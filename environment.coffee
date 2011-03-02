class Scope
    constructor: (@parent) ->
        @module = @parent.module
        @modules = @parent.modules
        @bindings = {}
        @uid = new UID()

    # Symbol || Identifier 
    add: (binding, tags=[]) ->
        # a new binding is being introduced 
        is_stx = binding instanceof Identifier
        key = if is_stx then binding.symbol else symbol

        if @bindings[key]?
            throw Error "Symbol already exists in this scope: #{key}"

        @bindings[key] = if is_stx
            binding
        else
            new Identifier binding, @module, @uid, tags

    # Symbol || Identifier -> Identifier
    tag: (symbol) ->
        # should be an existing binding
        if (symbol instanceof Identifier) then symbol

        if (id = @lookup symbol)? then id

        else throw new Error "symbol not bound #{symbol}"

    lookup: (symbol) ->
        @bindings[symbol] ? @parent.lookup symbol

class EmptyScope extends Scope
    constructor: ->
    add: (symbol) -> throw Error ""
    tag: (symbol) -> throw Error ""
    lookup: (symbol) -> null

class Identifier
    constructor: (@symbol, @module, @location, @tags) ->

    toJSIdentifier: -> "#{ js_escape @symbol }_uid#{ @location }"


js_escape = (string) ->
    chars = for char in string
        switch char
            when '_'  then '__'
            when '-'  then '_hyphen_'
            when '+'  then '_plus_'
            when '='  then '_equals_'
            when '!'  then '_bang_'
            when '?'  then '_question_'
            when '#'  then '_hash_'
            when '/'  then '_fslash_'
            when '\\' then '_bslash_'
            when '%'  then '_mod_'
            when '^'  then '_caret_'
            when '~'  then '_tilde_'
            when '*'  then '_star_'
            when '>'  then '_gt_'
            when '<'  then '_lt_'
            when ':'  then '_colon_'
            when '&'  then '_amp_'
            else char

    chars.join ''

class UID
    constructor: ->
        if UID.num is UID.alphabet.length
            UID.root += UID.alphabet[UID.num]
            UID.num = 0
        else

    toString: ->
        @root + String.fromCharcode @num

    @root: ""

    @num: ""

    @alphabet: "abcdefghiklmnopqrstuvwxyz0123456789"

class Symbol

class Gensym extends Symbol
    constructor: ->
        @str = "_gen_#{}" 
