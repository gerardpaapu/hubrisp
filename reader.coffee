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

    skipWhitespace: -> @match /\s+/

    isEmpty: -> @string.length <= @position

read_sexp = (port) ->
    switch lookahead(port)
        when 'open'   then read_list port
        when 'letter' then read_symbol port
        when 'number' then read_number port
        when 'this'   then read_this port
        when 'arguments'  then read_arguments port
        when 'short_fun'  then read_short_fun port
        when 'quote'      then read_quote port
        when 'quasiquote' then read_quasiquote port
        when 'unquote'    then read_unquote port
        when '<eof>'      then null
        else throw new Error "Unexpected #{ port.peek() }"

lookahead = (port) ->
    port.skipWhitespace()

    char = port.peek()
    keys =
        open:        /\(/
        close:       /\)/
        letter:      /[a-zA-Z_]/
        number:      /\d/
        'this':      /\@/
        'arguments': /%/
        short_fun:   /#/
        quote:       /'/
        quasiquote:  /`/
        unquote:     /,/

    if port.isEmpty()
        return '<eof>'

    for name, pattern of keys
        return name if pattern.test char

    throw new Error "Unexpected character: #{ char }"

read_list = (port) ->
    list = []
    port.skip() # skip the '('
    while lookahead(port) != 'close'
        if port.isEmpty()
            throw new Error 'Unexpected EOF'

        list.push(read_sexp port)

    port.skip() # skip the ')'
    list

read_number = (port) ->
    Number port.match /\d+\.?\d*/

read_arguments = (port) ->
    port.skip() # skip '%'
    if /\d/.test port.peek()
        ["js:arguments", Number port.match /\d+/]
    else
        ["js:arguments", 0 ]

read_this = (port) ->
    port.skip() # skip '@'
    [ "js:this", read_symbol port ]

read_quote = (port) ->
    port.skip() # skip '''
    [ "quote", read_sexp port ]

read_unquote = (port) ->
    port.skip() # skip ','
    [ "unquote", read_sexp port ]

read_quasiquote = (port) ->
    port.skip() # skip '`'
    [ "quasiquote", read_sexp port ]

read_short_fun = (port) ->
    port.skip() # skip '#'
    ["js:function", [], read_sexp port]

read_symbol = (port) ->
    port.match /([a-z-_+=!?^~*<>:&\/\\])+/

exports.Port = Port
exports.read_sexp = read_sexp
exports.read_number = read_number
exports.read_symbol = read_symbol
exports.read_list = read_list
exports.lookahead = lookahead
