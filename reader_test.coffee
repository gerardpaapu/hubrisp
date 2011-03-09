{Port, read_number, read_symbol, read_sexp, read_list, lookahead} = require './reader.js'

_ = (fn, str) ->
    console.log JSON.stringify fn new Port str

_ lookahead, "("
_ lookahead, ")"
_ lookahead, "lol"
_ lookahead, "4.5"

_ read_number, "3234.2"
_ read_number, "-3234.2e+10"
_ read_number, "0.2e-23"
_ read_symbol, "pasihusd"
_ read_list, "(1 2 3 4)"
_ read_list, "(foo lol (2 3) (butts 69))"
_ read_list, "(set! @lol #(sum % %4))"
_ read_sexp, "`(,(foo bar) baz (1 ,b 3))"
_ read_sexp, "(js:ref @omg :cats)"

