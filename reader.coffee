class Port 
    constructor: (@string, @position=0) ->

    position: 0

    clone: -> new Port @string, @position

    peek: (n) ->
        @string.slice @position, @position + n

    read: (n) ->
        value = peek(n)
        @position += n
        value

    skip: -> @position++

    match: (p) ->
        pattern = new RegExp p
        pattern.lastIndex = @position


read_sexp = (string, ctx) ->
    switch lookahead(string)
        when 'space'  then skip_whitespace string, ctx 
        when 'open'   then read_list string, ctx
        when 'letter' then read_symbol string, ctx
        when 'number' then read_number string, ctx
        else throw new Error "Unexpected #{ string[0] }"

lookahead = (string) ->
    switch string
        when /^\w+/     then 'space'
        when /^(/       then 'open'
        when /^)/       then 'close'
        when /^[_a-z]/i then 'letter'
        when /^[0-9]/   then 'number'

skip_whitespace = (string, ctx) ->
    while /^\w/.test(string)
        string = string.slice(1)

    ctx string, null

read_list = (string, ctx) ->
    list = []
    while lookahead(string) != 'close'
        list.push(read_sexp string, (d) -> d)

    ctx string, list

read_number = (string, ctx) ->
    pattern = /\d\.?\d*/
    match   = pattern.exec string

    ctx string.slice(pattern.lastIndex), match[0]
