
# PrimitiveSyntax -> JavascriptString
compile = (stx) ->
    [head, tail...] = stx

    switch head
        when JS.FUNCTION
            "function (#{compile_args args}) {
                #{compile_function_body body}
            }"
