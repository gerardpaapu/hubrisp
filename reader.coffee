class Hubrisp.Reader
    # String -> Sexp
    readsexp: (str) ->


class Hubrisp.Compiler
    # String, Environment -> Syntax
    readsyntax: (str, env) ->

    # Sexp, Environment -> Syntax
    _readsyntax: (sexp, env) ->
        switch Sexp.case(sexp)
            when "string", "number"
                sexp

            when "symbol"
                new Identifier(sexp, env)

            when "list"
                new Application (_readsyntax stx, env for stx in sexp)

class Environment
    # the compile-time environment
    module: null

    
