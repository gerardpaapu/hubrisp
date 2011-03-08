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

read_sexp = (port) ->
    switch lookahead(port)
        when 'open'   then read_list port
        when 'letter' then read_symbol port
        when 'number' then read_number port
        else throw new Error "Unexpected #{ port.peek() }"

lookahead = (port) ->
    port.skipWhitespace()

    char = port.peek()
    keys =
        open:   /\(/
        close:  /\)/
        letter: /[a-zA-Z_]/
        number: /\d/

    for name, pattern of keys
        return name if pattern.test char

    throw new Error "Unexpected character: #{ char }"

read_list = (port) ->
    list = []
    port.skip() # skip the '('
    while lookahead(port) != 'close'
        list.push(read_sexp port)

    port.skip() # skip the ')'
    list

read_number = (port) ->
    Number port.match /\d+\.?\d*/

read_symbol = (port) ->
    port.match ///
        [a-z_]
        ([a-z] | [-_+=!?#%^~*<>:&/\\])+
    ///

exports.Port = Port
exports.read_sexp = read_sexp
exports.read_number = read_number
exports.read_symbol = read_symbol
exports.read_list = read_list
exports.lookahead = lookahead
