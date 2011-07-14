/*jshint eqnull: true */
(function (){ 
    var regexes, escape_table, Port, Reader;

    escape_table = {
        "\"": "\"",
        "\\": "\\",
        b: "\b",
        f: "\f",
        n: "\n",
        r: "\r",
        t: "\t"
    };

    Port = function (string, position) {
        this.string = string;
        this.position = (position != null) ? position : 0;
    };

    Port.prototype = {
        position: 0, link: 1, column: 1,

        clone: function () {
            return new Port(this.string, this.position);
        },

        peek: function (n) {
            if (this.position >= this.string.length) {
                return null;
            } else {
                return this.string.slice(this.position, this.position + (n != null ? n : 1)); 
            }
        },

        read: function (n) {
            var value;
            n = (n != null) ? n : 1;
            value = this.peek(n);
            this.skip(n); 
            return value;
        },

        skip: function (n) {
            var segment;
            n = (n != null) ? n : 1;
            segment = this.string.slice(this.position, this.position + n);
            this.line += segment.replace(/[^\n]/mg, '').length;
            this.col   = segment.replace(/.*(\n.*)$/, '$1').length;
            this.position += n;

            return this;
        },

        match: function (p) {
            var string  = this.string.slice(this.position),
                pattern = new RegExp("^" + p.source),
                match   = pattern.exec(string),
                result;

            if (match != null) {
                result = match[0];    
                this.skip(result.length);
                return result;
            } else {
                return null;
            }
        }, 

        test: function (p) {
            var string = this.string.slice(this.position),
            pattern = new RegExp("^" + p.source);

            return pattern.test(string);
        },

        skipWhitespace: function () {
            return this.match(/(\s|,)+/);
        },

        isEmpty: function () {
            return this.string.length <= this.position;
        }
    };

    Reader = function (string) { 
        this.port = new Port(string); 
    };
    Reader.prototype = {
        lookahead: function() {
            var name, pattern;
            this.port.skipWhitespace();

            if (this.port.isEmpty()) {
                return '<eof>';
            }

            for (name in this.lookaheadTable) {
                pattern = this.lookaheadTable[name];
                if (this.port.test(pattern)) {
                    return name;
                }
            }
            throw new Error("Unexpected character during lookahead: " + this.port.peek() + " at " + (this.port.report()));
        },

        lookaheadTable: {
            number: regexes.number,
            symbol: regexes.symbol,
            '(': /\(/,
            ')': /\)/,
            '[': /\[/,
            ']': /\]/,
            '{': /\{/,
            '}': /\}/,
            string: /"/,
            'this': /\@/,
            'arguments': /%/,
            short_fun: /#/,
            quote: /'/,
            quasiquote: /`/,
            unquote: /~/,
            key: /:/
        },

        read_sexps: function() {
            var sexps = [];
            while (this.lookahead() !== '<eof>') {
                sexps.push(this.read_sexp());
            }
            return sexps;
        },

        read_sexp: function() {
            var sexp, location = this.port.location;

            switch (this.lookahead()) {
                case '(':
                    sexp = this.read_list(); break;
                case '[':
                    sexp = this.read_array(); break;
                case '{':
                    sexp = this.read_dict(); break;
                case 'string':
                    sexp = this.read_string(); break;
                case 'symbol':
                    sexp = this.read_symbol(); break;
                case 'number':
                    sexp = this.read_number(); break;
                case 'this':
                    sexp = this.read_this(); break;
                case 'arguments':
                    sexp = this.read_arguments(); break;
                case 'short_fun':
                    sexp = this.read_short_fun(); break;
                case 'quote':
                    sexp = this.read_quote(); break;
                case 'quasiquote':
                    sexp = this.read_quasiquote(); break;
                case 'unquote':
                    sexp = this.read_unquote(); break;
                case 'key':
                    sexp = this.read_key(); break;
                case '<eof>':
                    sexp = null; break;
                default:
                    throw new Error("Unexpected " + (this.port.peek()) + " at " + (this.port.report()));
            }

            sexp._location = location; 
            return sexp;
        },

        read_list: function() {
            return this.read_brackets('(', ')');
        },

        read_array: function() {
            return ["js:array", this.read_brackets('[', ']')];
        },

        read_dict: function() {
            return ["js:dict", this.read_brackets('{', '}')];
        },

        read_brackets: function(start, stop) {
            var list = [];

            this.assert(start);

            while (this.lookahead() !== stop) {
                if (this.port.isEmpty()) {
                    throw new Error('Unexpected EOF');
                }
                list.push(this.read_sexp());
            }

            this.assert(stop);
            return list;
        },

        assert: function(symbol) {
            if (this.lookahead() !== symbol) {
                throw new Error("Expected " + symbol + ", got " + (this.lookahead()) + " at " + (this.port.report()));
            }
            return this.port.skip();
        },

        read_number: function() {
            return Number(this.port.match(regexes.number));
        },

        read_arguments: function() {
            this.port.skip();
            if (/\d/.test(this.port.peek())) {
                return ["js:arguments", Number(this.port.match(/\d+/))];
            } else {
                return ["js:arguments", 0];
            }
        },

        read_this: function() {
            this.port.skip();
            return ["js:this", this.read_symbol()];
        },

        read_quote: function() {
            this.port.skip();
            return ["quote", this.read_sexp()];
        },

        read_unquote: function() {
            this.port.skip();
            return ["unquote", this.read_sexp()];
        },

        read_quasiquote: function() {
            this.port.skip();
            return ["quasiquote", this.read_sexp()];
        },

        read_short_fun: function() {
            this.port.skip();
            return ["js:function", [], this.read_sexp()];
        },

        read_symbol: function() {
            return this.port.match(regexes.symbol);
        },

        read_key: function() {
            this.port.skip();
            return ["key", this.read_symbol()];
        },

        read_string: function() {
            var code, code_point, str;
            str = "";
            this.port.skip();
            while (true) {
                switch (this.port.peek()) {
                    case null:
                        throw new Error("Unexpected EOF in '" + str + "'");

                    case '\\':
                        this.port.skip();
                        code = this.port.read();
                        if (code === 'u') {
                            code_point = parseInt(this.port.read(4), 16);
                            str += String.fromCharCode(code_point);
                        } else {
                            str += escape_table[code];
                        }
                    break;

                    case '"':
                        this.port.skip();
                        return ["js:string", str];

                    default:
                        str += this.port.read();
                }
            }
        }
    };

    /*globals module: false */
    if (typeof module != 'undefined' && module.exports) {
        module.exports.Reader = Reader;
        module.exports.Port = Port;
    }
}.call(null));
