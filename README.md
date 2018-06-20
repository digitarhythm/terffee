# terffee

CoffeeScript compile and minify tool.

CoffeeScriptをコンパイルし自動的にminify化します。
複数のディレクトリを監視し、それぞれ別のディレクトリ／ファイルを指定することが出来ます。

Compile CoffeeScript and automatically minify it. You can monitor multiple directories and specify different directories / files respectively.

$ terffee -c [directory / file] -o [directory / file] -w


## オプション(option)

- -c
コンパイル対象ファイル／ディレクトリです。
ディレクトリを指定した場合は、内包するCoffeeScriptファイルがコンパイルされます。
監視モードの場合は、内包するCoffeeScriptファイルが監視対象になります。
This is the file / directory to be compiled. If you specify a directory, the included CoffeeScript file will be compiled. In the monitoring mode, the included CoffeeScript file is monitored.

- -o
保存先ディレクトリ／ファイルを指定します。
コンパイル対象が複数指定されている場合は、保存先指定がひとつの場合はすべてのコンパイル対象でそれが使用されます。
保存先指定が複数ある場合は、コンパイル対象と対で使用されます。
Specify the destination directory / file. If multiple compilation targets are specified, if there is only one save destination specification, it will be used for all compilation targets. If there are multiple destination specifications, they are used in pairs with the compilation target.

例 example)
$ terffee -c foo.coffee -o ./tmp1/ -c bar.coffee -o ./tmp2/

この場合、「foo.coffee」はディレクトリ「./tmp1」配下に「foo.min.js」として保存されます。
「bar.coffee」は「./tmp2」配下に「bar.min.js」として保存されます。
保存先指定の最後がスラッシュで終わっている、もしくは既存のディレクトリを指定すると、その配下にコンパイル対象ファイルの拡張子が「.min.js」になったファイルとして保存されます。
最後がスラッシュで終わっていなく、ディレクトリとして存在していない場合は、ファイルとして保存されます。
複数のコンパイル対象が同じ保存先ファイルになっている場合は追記されます。

In this case, "foo.coffee" is saved as "foo.min.js" under the directory ". / Tmp1". "Bar.coffee" is saved as "bar.min.js" under ". / Tmp 2". If the end of the save destination specification ends with a slash, or if you specify an existing directory, it will be saved as a file whose extension of the compilation target file is ". Min.js" under that directory. If the end does not end with a slash and it does not exist as a directory, it is saved as a file. If multiple compilation targets are the same save destination file, it will be appended.

- -w
コンパイルはされず、コンパイル対象ディレクトリ／ファイルを監視し、変更があった場合にコンパイルされます。
コンパイル対象ファイルに変更があった場合、同じ保存先ファイルが指定されているコンパイル対象ファイルはすべてコンパイルされます。
It is not compiled, it monitors the compilation target directory / file and compiles it when there is a change. If there is a change in the compilation target file, all files to be compiled for which the same save destination file is specified are compiled.
