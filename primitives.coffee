compile = Hubrisp.compiler.compileStatement
compile_exp = Hubrisp.compiler.compileExpression

Hubrisp.definePrimitive "core.js", "js:if",
    statement: (test_exp, true_branch, false_branch) ->
        if false_branch?
            "
            if (#{compile_exp test_expression}) {
                #{compile true_branch}
            } else {
                #{compile false_branch}
            }
            "
        else
            "
            if (#{compile_exp test_expression}) {
                #{compile true_branch}
            }
            "

    expression: (test_form, true_branch, false_branch) ->
        false_branch = false_branch ? Hubrisp.getModule('core.js').export('js:null')
        "(#{compile_exp test_expression} ? #{compile_exp true_branch} : #{compile_exp false_branch})"
