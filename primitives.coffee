keyword = (str) -> 
    new Primitive (body) ->
        unless body.length is 0 throw new SyntaxError body.location

    str

Hubrisp.primitives = p = {} 

p['js:if'] = new Primitive (body) ->
    unless body.length is 3 throw new SyntaxError body.location

    [ test, true_branch, false_branch ] = body
     
    "if (#{ test.compile() }) { 
        #{ true_branch.compile() } 
    } else {
        #{ false_branch.compile() }
    }"

p['js:when'] = new Primitive (body) ->
    unless body.length >= 1 throw new SyntaxError body.location
    
    [ test, statements ] = body

    "if (#{ test.compile() }) {
        #{ [ s.compile() for s in statements ].join("\n") } 
    }"

p['js:if/exp'] = new Primitive (body) ->
    unless body.length is 3 throw new SyntaxError body.location

    [ test, true_branch, false_branch ] = body

    "(#{ test.compile() }?#{ true_branch.compile() }:#{ false_branch.compile() })"

p['js:while'] = new Primitive (body) -> 
    unless body.length >= 2 throw new SyntaxError body.location

    [ test, statements ] = body 
        
    "while (#{ test.compile() }) {
        #{ [s.compile() for s in statements ].join('\n') }
    }"

p['js:function'] = new Primitive (body) ->
    unless body.length >= 2 throw new SyntaxError body.location

    [ args, body... ]

    "function (#{ [ v.compile() for v in args ].join(", ") }) {
        #{ [ s.compile() for s in body ].join("\n") }        
    }"
    
p['js:return'] = new Primitive(body) ->
    unless body.length is 1 throw new SyntaxError body.location

    [ exp ] = body  

    "return #{ exp.compile() };"

p['js:set!'] = new Primitive (body) ->
    unless body.length is 2 throw new SyntaxError body.location
        
    [ place, value ] = body

    unless place instanceof Location
        throw new SyntaxError body.location

    "#{ place.compile() } = #{ value.compile() };"

p['js:var'] = new Primitive (body) ->
    if body.length is 0 throw new SyntaxError body.location

    for v in body unless v instanceof Identifier
        throw new SyntaxError body.location

    "var #{ [ v.compile() for v in body ].join(', ') };" 


p['js:quote'] = new Primitive (body) ->
    unless body.length is 1 throw new SyntaxError body.location
    
    # This needs some kind of filter to produce only literals
    # that can actually be read by vanilla javascript
    body[0].toSource()

p['js:try/catch'] = new Primitive (body) ->
    "try {
        #{ }
    } catch (#{ }) {
        #{ }
    }"

p['js:throw'] = new Primitive (body) ->
    unless body.length is 1 throw new SyntaxError body.location
    
    "throw #{ body[0].compile() };"

p['js:arguments'] = new Primitive (body) ->
    switch body.length
        when 0 then "arguments[0]"
        when 1 then "arguments[#{ body[0].compile() }]"
        else throw new SyntaxError body.location

p['js:this'] = keyword "this"

p['js:undefined'] = keyword "undefined"

p['js:null'] = keyword "null"

p['js:true'] = keyword "true"

p['js:false'] = keyword "false"

p['js:or'] = new Primitive (body) ->
    switch body.length
        when 0 then "false"
        when 1 then body[0].compile()
        else "(#{ [ e.compile() for e in body ].join(" || ") })"

p['js:and'] = new Primitive (body) ->
    switch body.length
        when 0 then "true"
        when 1 then body[0].compile()
        else "(#{ [ e.compile() for e in body ].join(" && ") })"

p['js:not'] = new Primitive (body) ->
    unless body.length is 1 throw new SyntaxError body.location

    "!#{ body[0].compile() }"

p['js:ref'] = new Primitive (body) ->
    unless body.length is 2 throw new SyntaxError body.location

    [ obj, key ] = body

    "#{ obj.compile() }[#{ key.compile() }]"   

p['js:dot'] = new Primitive (body) ->
    unless body.length >= 2 throw new SyntaxError body.location

    unless Type.ArrayOf( Identifier ).check( body )
        throw new SyntaxError body.location

    [ v.getSymbol() for v in body ].join(".") 

p['js:funcall'] = new Primitive (body) ->
    unless body.length >= 1 throw new SyntaxError body.location

    [ fn, args ] = body

    "#{ fn.compile() }(#{ [ arg.compile() for arg in args ].join(", ") })"

p['js:array'] = new Primitive (body) ->
    "[#{ [ e.compile() for e in body ].join(", ") }]"

p['js:dict'] = new Primitive (body) ->
    unless body.length % 2 is 0 throw new SyntaxError body.location

    len = body.length / 2 
    i = 0
        
    entries = while i < len
        [ key, value ] = body[i..] 

        unless key instanceof Identifier throw new SyntaxError key.location

        "\"#{ body[i].getSymbol() }\":#{ body[i + 1].compile() }"

    "{#{ entries.join(", ") }}"
