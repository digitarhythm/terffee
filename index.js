// Generated by CoffeeScript 1.12.7
var COFFEE_OPTS, coffee, fpath, i, len, target, terser;

terser = require("terser");

coffee = require("coffee-compiler");

target = process.argv;

target.splice(0, 2);

COFFEE_OPTS = {
  sourceMap: false,
  bare: true
};

for (i = 0, len = target.length; i < len; i++) {
  fpath = target[i];
  coffee.fromFile(fpath, COFFEE_OPTS, function(err, jsstr) {
    var code;
    code = (terser.minify(jsstr)).code;
    return console.log(code);
  });
}
