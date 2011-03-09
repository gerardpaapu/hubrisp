# So Hubrisp.compiler.compile(form, env, context)
# where context is either 'expression', 'statement' or 'return'
# so each Hubrisp.Primitive should implement
# `compileExpression`, `compileStatement` and `compileReturn`

class Hubrisp.Primitive
    compileReturn: -> "return #{ @compileExpression() };"
    compileStatement: -> "#{ @compileExpression() };\n"
    compileExpression: -> throw Error "Not Implemented"

compile_statements = (statements) ->
    ("#{ s.compileStatement() };\n" for s in statements).join('')

js_if = Hubrisp.primitives['js:if'] = new Hubrisp.Primitive()
js_if.compileExpression = (test, _true, _false) ->
    "(#{ test.compileExpression() } ? #{ _true.compileExpression() } : #{ _false.compileExpression })"

js_while = Hubrisp.primitives['js:while'] = new Hubrisp.Primitive()
js_while.compileExpression = (test_exp, forms..., tail) ->

Hubrisp.definePrimitive "core.js", "js:while",
    statement: (test_exp, forms...) ->
        "
        while (#{ compile_exp }) {
            #{ compile_statements forms }
        }
        "

    expression: (test_exp, forms..., tail) ->
        ref = gensym("collect")
        "
        (function () {
            var #{ compile_id ref } = [];
            while (#{ compile_exp test_exp }) {
                #{ compile_statements forms }
                #{ compile_id ref }.push(#{ compile_exp tail });
            }
            return #{compile_id ref};
        })
        "

"
;; How the fuck does syntax-quote even work?
;; could the syntax-expansion stage be aware of the
;; difference between statements and expressions?
(syntax-let ((_ref (gensym)))
  #`(let ((_ref []))
      (js:while test_exp
        forms ...
        (js:method-call _ref :push tail))
      _ref))
"
