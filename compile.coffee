
# PrimitiveSyntax -> JavascriptString
compile_special_form = (stx) ->
    [head, tail...] = stx

    switch head.toString()
        when "js:function"

            "function (#{compile_args tail[0]}) {
                #{compile_function_body tail[1..]}
            }"

        when "js:while"

            "while (#{ compile tail[0] }) {
                #{ compile_expressions tail[1..] }
            }\n"

        when "js:if"

            "(#{compile tail[0]} ? #{compile tail[1]} : #{compile tail[2]})"

        when "js:throw"

            "throw #{compile tail[0]};"

        when "js:var"

            "var #{(compile_symbol sym for sym in tail).join ", "};"

        when "js:set!"

            "#{compile_symbol tail[0]} = #{compile tail[1]}"

        when "js:begin"

            "(function () { 
                #{compile_function_body tail} 
            }.call(this))"

        when "js:expr"

            "(function () {
                #{compile tail[0]}
                return null;
            }())"

        when "js:try/catch"

            "try {
                #{compile tail[1]}
            } catch (#{compile_symbol tail[0]}) {
                #{compile tail[2]}
            }"

        when "js:return"

            "return #{ compile_expressions(tail).join ', ' };"


compile_function_body = (stx) ->
    [body..., tail] = stx
    _body = ("#{compile e};\n" for e in body).join ''
    _tail = "return #{ compile tail };\n"

    _body + _tail

compile_args = (args) ->
    (compile_symbol arg for arg in args).join ''

compile_symbol = () ->
    ()
