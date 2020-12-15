#!/usr/bin/env node
#============================================================================
# CoffeeScriptのソースファイルと保存先を指定し、コンパイル＆minify化を行う
# 「-c」オプションでソースファイルだけを指定した場合は、生成されるファイル
# はソースファイルと同じ場所に保存される。
# 例）terffee -c hoge.coffee
#
# 「-o」オプションで保存先を指定する。
# 保存場所の最後をスラッシュにするか、すでに存在するディレクトリ名を指定し
# た場合は、ディレクトリとみなしその中に生成したファイルが「.min.js」の拡
# 張子で保存される。
# 例）terffee -c hoge.coffee -o ./apps/js/ → ./apps/js/hoge.min.jsが生成される
#
# 最後がスラッシュではない場合は、指定したソースファイルのコンパイル＆minify
# されたものがひとつのファイルとして保存される。
# 例）terffee -c hoge.coffee -c foo.coffee -o hogefoo.min.js
#
# ソースファイルと保存場所の対応は、記述した順番になる。
# 保存先の数がソースファイルの数よりも少ない場合、足りない分は最後の保存場所
# がそのまま使われる。
# 例）terffee -c hoge.coffee -o hoge.min.js -c foo.coffee -o foo.min.js -c bar.coffee
# （上記の例では、「bar.coffee」は「foo.min.js」に結合される）
#
# type： -1 指定したpathが存在しない
#         0 (未使用)
#         1 ディレクトリ
#         2 ファイル　
#============================================================================

TERSER = require("terser")
COFFEE = require("coffee-compiler2")
ARGV = require("argv")
MINIMIST = require("minimist")
ASYNC = require("async")
FS = require("fs-extra")
PATH = require("path")
PROMISE = require("bluebird")
FORM = require("ndlog").form
READLINE = require("readline")
WATCHER = require("filewatcher")
  forcePolling: false
  debounce: 10
  interval: 1000
  persistent: true

echo = require("ndlog").echo
packinfo = require("./package.json")

#============================================================================
# 色コード
#============================================================================
black = '\u001b[01;30m'
red = '\u001b[01;31m'
green = '\u001b[01;32m'
yellow = '\u001b[01;33m'
blue = '\u001b[01;34m'
magenta = '\u001b[01;35m'
cyan = '\u001b[01;36m'
white = '\u001b[01;37m'
reset = '\u001b[0m'

#============================================================================
# CoffeeScriptをコンパイルし、minify化した結果をリストで返す
# coffeecode = CoffeeScriptコード文字列
# ret = err: エラーコード 0=正常終了 0以外=エラー
#       message: 結果
#       result: 正常終了の時はJS、エラーの時はエラーメッセージ
#============================================================================
compile = (coffeecode) ->
  return new PROMISE (resolve, reject) ->
    if (nominify)
      inlineopt = !no_inlinemap
    else
      inlineopt = true

    COFFEE_OPTS =
      inlineMap: inlineopt
      bare: true
    try
      COFFEE.fromSource coffeecode, COFFEE_OPTS, (compile_err, jsstr) ->
        if (compile_err?)
          reject
            err: compile_err.errno
            status: "compile error."
            message: compile_err.message
        else
          if (nominify)
            code = jsstr
          else
            if (no_inlinemap)
              terser_opts = {}
            else
              terser_opts =
                sourceMap:
                  url: "inline"
            code = (TERSER.minify(jsstr, terser_opts)).code
          resolve
            err: 0
            status: "compiled."
            message: ""
            result: code
    catch e
      reject
        err: compile_err.errno
        status: "compile error."
        message: compile_err.message

#============================================================================
# 指定されたpathが、ディレクトリなのか、ファイルなのかを返す
# 返値： type
#  -1 = pathが存在しない
#   1 = ディレクトリ
#   2 = ファイル
# 返値： fname
#   pathがファイルだった場合のファイル名
#============================================================================
isPath_DirectoryOrFile = (path) ->
  if (path.match(/\/$/))
    # pathがスラッシュで終わっている
    type = 1 # ディレクトリ
    fname = undefined
  else
    # pathがスラッシュで終わっていない
    try
      # pathが既存ディレクトリ
      if (FS.statSync(path).isDirectory())
        type = 1 # ディレクトリ
        fname = undefined
      else
        type = 2 # ファイル
        fname = PATH.basename("./#{path}")
    catch path_check_err
      # pathが存在しない
      type = -1 # 存在しない
      fname = undefined

  return
    type: type
    fname: fname

#============================================================================
# 渡されたソースがディレクトリの場合は中を探査しCoffeeScriptファイルを列挙し返す
# otype
#   1 = ディレクトリ
#   2 = ファイル
#============================================================================
get_sourcelist_in_path = (srcinfo)->
  src = srcinfo.src
  output = srcinfo.output || "."
  stype = srcinfo.stype
  otype = srcinfo.otype
  ext = if (nominify) then ".js" else ".min.js"
  if (extension?)
    ext = ".#{extension}"

  ret_srclist = []

  #===========================================================================
  # 渡されたソースがディレクトリだった
  #===========================================================================
  if (stype == 1) # ディレクトリ

    files = FS.readdirSync(src)
    for srcfname in files
      srcfullpath = FORM("%@/%@", src, srcfname)

      # 取り出したファイルがCoffeeScript場合は処理しない
      if (!srcfname.match(/\.coffee$/) && !FS.statSync(srcfullpath).isDirectory())
        continue

      # 取り出したパスを再帰処理
      else
        if (FS.statSync(srcfullpath).isDirectory())
          stype = 1
        else
          stype = 2
        reinfo =
          src: "#{src}/#{srcfname}"
          output: output
          stype: stype
          otype: otype
        ret_srclist = ret_srclist.concat(get_sourcelist_in_path(reinfo))

  #===========================================================================
  # 渡されたソースがファイルだった
  #===========================================================================
  else if (stype == 2) # ファイル
    if (!src.match(/\.coffee$/))
      return undefined
    switch (otype)
      when 1 # 出力先がディレクトリ
        #if (!output?)
        #  output = "."
        ofile = "#{output}/#{PATH.basename(src).replace(/\.coffee$/, ext)}"
      when 2 # 出力先がファイル　
        ofile = output
    ret_srclist.push
      src: src
      output: ofile

  return ret_srclist

#============================================================================
# 渡されたソースファイル名リストからソースを読み込んで配列にして返す
#============================================================================
sourcelist_fileread = (sourcepath_list) ->
  return new Promise (resolve, reject) ->
    compile_strings = []
    ASYNC.whilst ->
      # コンパイルするソースファイルがなくなったらループを抜ける
      if (sourcepath_list.length > 0)
        return true
      else
        return false

    , (callback) ->
      # ファイルパスをひとつ取り出す
      srcinfo = sourcepath_list.shift()
      src = srcinfo.src
      output = srcinfo.output

      # outputの最初の処理の時はリストを初期化する
      if (!compile_strings[output]?)
        compile_strings[output] = {}
        compile_strings[output]['code'] = ""
        compile_strings[output]['src'] = []

      # ソースを読み込む
      FS.readFile src, "utf-8", (err, code) ->
        if (err)
          callback(err, null)
        else
          # 同じoutputのところに追記する
          compile_strings[output]['code'] += code
          compile_strings[output]['src'].push(src)
          callback(null, 0)

    , (err, result) ->
      if (result)
        reject(undefined)
      else
        resolve(compile_strings)

#============================================================================
# 渡されたソースの配列をコンパイルして保存する
#============================================================================
sourcelist_compile = (compile_strings) ->
  return new Promise (resolve, reject) ->
    # output一覧配列を取得（これでループを回す）
    output_list = Object.keys(compile_strings)

    # ループしながら順番に（同期して）コンパイルする
    ASYNC.whilst ->
      # コンパイルされるファイル名がなくなったらループを抜ける
      if (output_list.length > 0)
        return true
      else
        return false

    , (callback) ->
      # コンパイル対象ファイル名をひとつ取り出す
      output = output_list.shift()
      code = compile_strings[output]['code']
      srclist = compile_strings[output]['src']
      srclist.map (s) ->
        console.log "#{cyan}===> compile #{s}"
      compile(code).then (ret) ->
        minify = ret.result
        FS.writeFile output, minify, 'utf8', ->
          callback(null, 0)
      .catch (err) ->
        message = err.message
        console.log "#{red}#{message}#{reset}"

    , (ret, result) ->
      if (result < 0)
        reject(result)
      else
        resolve(0)


#============================================================================
# 渡されたディレクトリ内の追加されたCoffeeScriptファイルを監視対象にする
#============================================================================
setFileWatchIntoDirectory = (srcinfo) ->
  return new Promise (resolve, reject) ->
    src = srcinfo.src.replace(/\/*$/, "")
    stype = srcinfo.stype
    output = srcinfo.output
    otype = srcinfo.otype
    ext = if (nominify) then ".js" else ".min.js"
    if (extension?)
      ext = ".#{extension}"

    srclist = get_sourcelist_in_path(srcinfo)
    compile_list = []
    ASYNC.whilst ->
      if (srclist.length > 0)
        true
      else
        false

    , (callback) ->
      f = srclist.shift()
      fname2 = (f.src).replace(/[\.\/]/g, "")
      # ソースファイルが追加された
      if (!SRC2OUTPUT[fname2]?)
        WATCHER.add f.src
        # 出力先から出力ファイル名を生成する
        switch (otype)
          when 1 # 出力先がディレクトリ　
            fname = PATH.basename(f.src)
            ofile = "#{output}/"+PATH.basename(fname).replace(/\.coffee$/, ext)
          when 2 # 出力先がファイル　
            ofile = output
        compile_list.push(ofile)
        OUTPUT2SRCLIST[ofile] = [] if (!OUTPUT2SRCLIST[ofile]?)
        SRC2OUTPUT[fname2] = ofile
        OUTPUT2SRCLIST[ofile].push
          src: f.src
          output: ofile
      callback(null, 0)

    , (err, result) ->
      if (err)
        reject(-1)
      else
        resolve(compile_list)

#============================================================================
# 渡された出力ファイルを構成するCoffeeScriptをコンパイルする
#============================================================================
output2compile = (output)->
  return new Promise (resolve, reject) ->
    srclist = OUTPUT2SRCLIST[output].concat()
    sourcelist_fileread(srclist).then (srcjoinlist) ->
      return sourcelist_compile(srcjoinlist)
    .then (err) ->
      if (err == 0)
        console.log("#{green}create [#{yellow}#{PATH.basename(output)}#{green}] done: "+new Date()+reset+"\n")
    .catch (err) ->
      if (err)
        reject(-1)
      else
        console.log("error: #{err}")
        resolve(0)

#============================================================================
#============================================================================
#============================================================================

#============================================================================
# メイン処理
#============================================================================

# 引数チェック
ARGV.option
  name: "watch"
  short: "w"
  type: "string"
  description: "watch source file change."
  example: "terffee -wc [source file path]"
ARGV.option
  name: "compile"
  short: "c"
  type: "path"
  description: "compile source file."
  example: "terffee -c [source file path]"
ARGV.option
  name: "output"
  short: "o"
  type: "path"
  description: "compiled file output directory."
  example: "terffee -o [output directroy]"
ARGV.option
  name: "nomap"
  short: "n"
  type: "string"
  description: "not include inline sourceMap."
  example: "terffee -n"
ARGV.option
  name: "nominify"
  short: "m"
  type: "string"
  description: "not minify source."
  example: "terffee -m"
ARGV.option
  name: "extension"
  short: "e"
  type: "string"
  description: "Specify the extension after compilation."
  example: "terffee -e js"
ARGV.option
  name: "version"
  short: "v"
  type: "string"
  description: "display this menu."
  example: "terffee -v"
argopt = ARGV.run()

if (argopt.options.version)
  console.log "ver #{packinfo.version}"
  process.exit(0)

target = process.argv
target.splice(0, 2)
argm = MINIMIST(target)

#============================================================================
# オプションを取得
#============================================================================
c_opt = argm.c || argm.compile
outputlist_tmp = argm.o || argm.output
no_inlinemap = argm.n || argm.nomap
nominify = argm.m || argm.nominify
exttmp= argm.e || argm.extension
if (exttmp)
  extension = argopt.options.extension
  if (extension == "true")
    console.log "Please, input output file extension."
    process.exit()
else
  extension = undefined

#============================================================================
# コンパイルするソースファイル一覧を取得する
#============================================================================
sourcepath_tmp = []
directotypath = []
sourcepath_tmp = argm._
if (c_opt?)
  if (typeof c_opt == 'string')
    c_opt = [c_opt]
  sourcepath_tmp.push.apply(sourcepath_tmp, c_opt)

#============================================================================
# コンパイル／minify化したファイルを保存する一覧を取得する　
#============================================================================
if (typeof outputlist_tmp == "object")
  outputlist = outputlist_tmp
else
  outputlist = [outputlist_tmp]

#============================================================================
# 引数で指定されたソース一覧と保存先一覧を整理する
#============================================================================
sourcepath = []
sourcepath_tmp.forEach (fpath, cnt) ->

  #===========================================================================
  # ソースの種類（ファイルかディレクトリか）と存在するかチェック
  #===========================================================================
  # 処理するファイル
  src = fpath
  stype = isPath_DirectoryOrFile(src).type
  # ソースに指定されたファイル／ディレクトリが存在する場合は処理する
  if (stype > 0)
    # 保存先リストからひとつ取り出す
    output = outputlist[cnt] || outputlist[outputlist.length-1]

    # 保存先が存在する
    if (output?)
      otype = isPath_DirectoryOrFile(output).type
      # outputが存在しなかったらファイル
      if (otype == -1)
        otype = 2

    # 保存先がundefined
    else
      # 保存先をsrcから生成する
      otype = 1

    # srcの末尾に「/」があったら除去する
    src = src.replace(/\/*$/, "")
    # outputの末尾に「/」があったら除去する
    output = output.replace(/\/*$/, "") if (outputp?)

    sourcepath.push
      src: src
      stype: stype
      output: output
      otype: otype
  else

    console.log "\n#{red}File/Directory not found: #{src}#{reset}"
    process.exit(-1)

#============================================================================
# ソースファイルが指定されていない
#============================================================================
if (target.length == 0)
  ARGV.run(["-h"])
  process.exit(-1)

if (argm.w || argm.watch)
  #==========================================================================
  # ソースファイル／ディレクトリ監視
  #==========================================================================
  WATCHER
    .on "change", (fpath, stat) ->
      fname2 = fpath.replace(/[\.\/]/g, "")
      if (!stat.deleted?)
        fname = PATH.basename(fpath)

        if (PATH.extname(fname) == ".coffee")
          # ファイル更新
          output = SRC2OUTPUT[fname2]
          output2compile(output)
        else
          # ファイル追加
          srcinfo = undefined
          # 追加されたディレクトリを取得
          sourcepath.forEach (info) ->
            if (info.src == fpath)
              srcinfo = info
          # 追加されたディレクトリ内の追加されたファイルを取得
          setFileWatchIntoDirectory(srcinfo).then (compile_list) ->
            # 追加されたファイルがあった場合は出力先を取り出す（コンパイルされる）
            if (compile_list.length > 0)
              output = compile_list[0]
              output2compile(output)
      else
        # 監視ファイル削除
        WATCHER.remove(fpath)
        output = SRC2OUTPUT[fname2]
        idx = 0
        i = 0
        target_list = OUTPUT2SRCLIST[output]
        target_list.map (tmp) ->
          if (tmp.src == fpath)
            idx = i
          i++
        target_list.splice(idx, 1)
        delete SRC2OUTPUT[fname2]
        if (target_list.length == 0)
          delete OUTPUT2SRCLIST[output]
          delete_output = output
          output = undefined
          try
            FS.unlink delete_output, (err) ->
          catch e
        output2compile(output) if (output?)

  # 監視対象を列挙
  SRC2OUTPUT = {}
  OUTPUT2SRCLIST = {}
  for srcinfo in sourcepath
    try
      # ソースとして指定されたファイル／ディレクトリが存在するかチェック
      FS.accessSync(srcinfo.src, FS.F_OK)
      # 監視対象をひとつ取り出して、行末のスラッシュを除去する
      src = srcinfo.src.replace(/\/*$/, "")
      stype = srcinfo.stype
      output = srcinfo.output || "."
      otype = srcinfo.otype
      ext = if (nominify) then ".js" else ".min.js"

      # 監視対象がディレクトリの場合は中のファイルを走査し処理する
      switch (stype)
        when 1 # 監視対象がディレクトリ
          console.log("#{yellow}watching directory [#{green}#{src}#{reset}]")
          WATCHER.add srcinfo.src
          setFileWatchIntoDirectory(srcinfo)

        when 2 # 監視対象がファイル
          console.log("watching file [#{yellow}#{src}#{reset}]")
          WATCHER.add src
          # 出力先から出力ファイル名を生成する
          switch (otype)
            when 1 # 出力先がディレクトリ　
              fname = PATH.basename(src)
              ofile = "#{output}/"+PATH.basename(fname).replace(/\.coffee$/, ext)
            when 2 # 出力先がファイル　
              ofile = output
          OUTPUT2SRCLIST[ofile] = [] if (!OUTPUT2SRCLIST[ofile]?)
          # ソースファイルに対する出力先のファイル名を設定する
          SRC2OUTPUT[src.replace(/[\.\/]/g, "")] = ofile
          OUTPUT2SRCLIST[ofile].push
            src: src
            output: ofile

    catch e
      #echo e
      console.log("File/Directory not found: #{src}")
      process.exit(0)
      WATCHER.close()

else

  #==========================================================================
  # ソースファイルコンパイル
  #==========================================================================
  # ソース指定がディレクトリの場合を想定して展開する
  sourcepath_expand = []
  ASYNC.whilst ->
    if (sourcepath.length > 0)
      return true
    else
      return false
  , (callback) ->
    srcinfo = sourcepath.shift()
    srclist = get_sourcelist_in_path(srcinfo)
    if (srclist?)
      Array.prototype.push.apply(sourcepath_expand, srclist)
    callback(null, 0)
  , (err, result) ->
    # コンパイルする
    sourcelist_fileread(sourcepath_expand).then (srcjoinlist) ->
      return sourcelist_compile(srcjoinlist)
    .then (err) ->
      if (err == 0)
        console.log("#{green}compile done: "+new Date()+reset+"\n")



