# TODO
# - Start an actual test suite for the reader
# - Implement reading string to the JSON standard
# - Assert all the bits that I'm skipping e.g. closing brackets

regexes =
    symbol: /[a-z-_+=!?^*<>&\/\\]+/
    number: /-?(0|([1-9]\d*))(\.\d+)?((e|E)(\+|\-)\d+)?/

class Port
    constructor: (@string, @position=0) ->

    position: 0

    clone: -> new Port @string, @position

    peek: (n=1) ->
        @string.slice @position, @position + n

    read: (n=1) ->
        value = @peek n
        @skip n
        value

    skip: (n=1) -> @position += n

    match: (p) ->
        string  = @string[@position..]
        pattern = new RegExp "^#{p.source}"
        match   = pattern.exec string

        if match?
            result = match[0]
            @position += result.length
            result
        else
            null

    test: (p) ->
        string  = @string[@position..]
        pattern = new RegExp "^#{p.source}"

        pattern.test string

    skipWhitespace: -> @match /(\s|,)+/

    isEmpty: -> @string.length <= @position

class Reader
    constructor: (string) ->
        @port = new Port string

    lookahead: ->
        @port.skipWhitespace()

        if @port.isEmpty()
            return '<eof>'

        for name, pattern of @lookaheadTable
            return name if @port.test pattern

        throw new Error "Unexpected character during lookahead: #{ char }"

    lookaheadTable:
        number:      regexes.number
        symbol:      regexes.symbol
        '(':         /\(/
        ')':         /\)/
        '[':         /\[/
        ']':         /\]/
        '{':         /\{/
        '}':         /\}/
        'this':      /\@/
        'arguments': /%/
        short_fun:   /#/
        quote:       /'/
        quasiquote:  /`/
        unquote:     /~/
        key:         /:/

    read_sexp: ->
        switch @lookahead()
            when '('   then @read_list()
            when '['   then @read_array()
            when '{'   then @read_dict()
            when 'symbol' then @read_symbol()
            when 'number' then @read_number()
            when 'this'   then @read_this()
            when 'arguments'  then @read_arguments()
            when 'short_fun'  then @read_short_fun()
            when 'quote'      then @read_quote()
            when 'quasiquote' then @read_quasiquote()
            when 'unquote'    then @read_unquote()
            when 'key'        then @read_key()
            when '<eof>'      then null
            else throw new Error "Unexpected #{ @port.peek() }"

    read_list: ->
        @read_brackets '(', ')'

    read_array: ->
        ["js:array", @read_brackets '[', ']']

    read_dict: ->
        ["js:dict", @read_brackets '{', '}']

    read_brackets: (start, stop) ->
        list = []

        @assert start

        while @lookahead() != stop
           if @port.isEmpty()
               throw new Error 'Unexpected EOF'

           list.push @read_sexp()

        @assert stop

        list

    assert: (symbol) ->
        unless @lookahead() is symbol
            throw new Error "Expected #{ symbol }, got #{ @lookahead() }"

        @port.skip()

    read_number: ->
        Number @port.match regexes.number

    read_arguments: ->
        @port.skip() # skip '%'

        if /\d/.test @port.peek()
            ["js:arguments", Number @port.match /\d+/]
        else
            ["js:arguments", 0 ]

    read_this: ->
        @port.skip() # skip '@'
        [ "js:this", @read_symbol() ]

    read_quote: ->
        @port.skip() # skip '''
        [ "quote", @read_sexp() ]

    read_unquote: ->
        @port.skip() # skip '~'
        [ "unquote", @read_sexp() ]

    read_quasiquote: ->
        @port.skip() # skip '`'
        [ "quasiquote", @read_sexp() ]

    read_short_fun: ->
        @port.skip() # skip '#'
        ["js:function", [], @read_sexp() ]

    read_symbol: ->
        @port.match regexes.symbol

    read_key: ->
        @port.skip() # skip ':'
        ["key", @read_symbol() ]


exports.read = (string) ->
    new Reader(string).read_sexp()

exports.Port = Port
exports.Reader = Reader
exports.regexes = regexes
