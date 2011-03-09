# TODO
# - Wrap the whole reader thing in a context object
# - Read square brackets as Array literals
# - Read curlies as object literals
# - Implement reading numbers to the JSON standard
# - Implement reading string to the JSON standard
# - Change unquote to something else so that ',' can be whitespace
# - Assert all the bits that I'm skipping e.g. closing brackets

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

class Reader
    constructor: (string) ->
        @port = new Port string

    lookahead: ->
        @port.skipWhitespace()

        if @port.isEmpty()
            return '<eof>'

        char = @port.peek()

        for name, pattern of @lookaheadTable
            return name if pattern.test char

        throw new Error "Unexpected character during lookahead: #{ char }"

    lookaheadTable:
        open:        /\(/
        close:       /\)/
        letter:      /[a-zA-Z_]/
        number:      number_pattern
        'this':      /\@/
        'arguments': /%/
        short_fun:   /#/
        quote:       /'/
        quasiquote:  /`/
        unquote:     /,/
        key:         /:/

    read_sexp: ->
        switch @lookahead()
            when 'open'   then @read_list()
            when 'letter' then @read_symbol()
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
    Number @port.match number_pattern

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
    port.match /[a-z-_+=!?^~*<>:&\/\\]+/

read_key = (port) ->
    port.skip() # skip ':'
    ["key", read_symbol port]


number_pattern = ///
    -?               # negative?
    (
        0 |          # leading 0
        ([1-9]\d*)   # or any number of other digits
    )
    (
        \.           # decimal point followed by
        \d+          # any number of other digite
    )?
    (
        (e|E)        # optionally a power of 10
        (\+|\-)
        \d+
    )?
    ///


exports.Port = Port
exports.read_sexp = read_sexp
exports.read_number = read_number
exports.read_symbol = read_symbol
exports.read_list = read_list
exports.lookahead = lookahead
