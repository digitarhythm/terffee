#!/usr/bin/env coffee
terser = require("terser")
coffee = require("coffee-compiler")

target = process.argv
target.shift(1)
target.shift(1)

COFFEE_OPTS =
  sourceMap: false
  bare: true

for fpath in target
  coffee.fromFile fpath, COFFEE_OPTS, (err, jsstr) ->
    code = (terser.minify(jsstr)).code
    console.log(code)
