Promise = require("bluebird")
fs = require("fs-extra")
echo = require("ndlog").echo

class hoge
  constructor:->
    console.log("hoge")

  hoge:->
    console.log("hogehoge")
