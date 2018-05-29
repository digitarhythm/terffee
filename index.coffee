#!/usr/bin/env coffee
terser = require("terser")
coffee = require("coffee-compiler")

target = process.argv
target.splice(0, 2)

COFFEE_OPTS =
  sourceMap: false
  bare: true

for fpath in target
  coffee.fromFile fpath, COFFEE_OPTS, (err, jsstr) ->
    code = (terser.minify(jsstr)).code
    console.log(code)
