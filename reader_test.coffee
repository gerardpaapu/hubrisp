{Port, read_number, read_symbol, read_sexp, read_list, lookahead} = require './reader.js'

console.log lookahead new Port "("
console.log lookahead new Port ")"
console.log lookahead new Port "lol"
console.log lookahead new Port "4.5"

console.log read_number new Port "3234.2"
console.log read_symbol new Port "pasihusd"
console.log read_list new Port "(1 2 3 4)"
console.log read_list new Port "(foo lol (2 3) (butts 69))"


