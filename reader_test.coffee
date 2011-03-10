{read} = require './reader.js'

_ = (str) ->
    console.log JSON.stringify read str

_ "3234.2"
_ "-3234.2e+10"
_ "0.2e-23"
_ "pasihusd"
_ "(1 2 3 4)"
_ "(foo lol (2 3) (butts 69))"
_ "(set! @lol #(+ % %4))"
_ "`(~(foo bar) baz (1 ~b 3))"
_ "(js:ref @omg :cats)"
_ "{ :lol 5, :omg 666 }"
_ '(lol "this is a fraggin string \\"ok\\"" 3.5)'
