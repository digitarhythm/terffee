# terffee

## CoffeeScript compile and minify tool.

CoffeeScriptをコンパイルし自動的にminify化します。  
複数のディレクトリを監視し、それぞれ別のディレクトリ／ファイルを指定することが出来ます。  
コンパイルされたJSコードの後ろに、inline sourceMapが追記されます（オプションでオフにすることが出来ます）。  

Compile CoffeeScript and automatically minify it. You can monitor multiple directories and specify different directories/files respectively.  
An inline sourceMap is appended after the compiled JS code (you can turn it off as option).  

$ terffee -c [directory/file] -o [directory/file] -w  


## オプション(option)

- -c  
コンパイル対象ファイル／ディレクトリです。  
ディレクトリを指定した場合は、内包するCoffeeScriptファイルがコンパイルされます。  
監視モードの場合は、内包するCoffeeScriptファイルが監視対象になります。  
This is the file/directory to be compiled. If you specify a directory, the included CoffeeScript file will be compiled. In the monitoring mode, the included CoffeeScript file is monitored.

- -o  
保存先ディレクトリ／ファイルを指定します。  
コンパイル対象が複数指定されている場合は、保存先指定がひとつの場合はすべてのコンパイル対象でそれが使用されます。  
保存先指定が複数ある場合は、コンパイル対象と対で使用されます。  
複数のコンパイル結果を指定する場合はワイルドカードを使用すると動作がおかしくなります。なぜならワイルドカードは展開される数が不確定だからです。  
Specify the destination directory/file. If multiple compilation targets are specified, if there is only one save destination specification, it will be used for all compilation targets. If there are multiple destination specifications, they are used in pairs with the compilation target.  
If you specify multiple compilation results, using wildcards will cause the behavior to go wrong. Because the number of wildcards to be expanded is indeterminate.

例 example)  
$ terffee -c foo.coffee -o ./tmp1/ -c bar.coffee -o ./tmp2/  

この場合、「foo.coffee」はディレクトリ「./tmp1」配下に「foo.min.js」として保存されます。  
「bar.coffee」は「./tmp2」配下に「bar.min.js」として保存されます。  
保存先指定の最後がスラッシュで終わっている、もしくは既存のディレクトリを指定すると、その配下にコンパイル対象ファイルの拡張子が「.min.js」になったファイルとして保存されます。  
最後がスラッシュで終わっていなく、ディレクトリとして存在していない場合は、ファイルとして保存されます。  
複数のコンパイル対象が同じ保存先ファイルになっている場合は追記されます。  
In this case, "foo.coffee" is saved as "foo.min.js" under the directory "./tmp1". "bar.coffee" is saved as "bar.min.js" under "./tmp2". If the end of the save destination specification ends with a slash, or if you specify an existing directory, it will be saved as a file whose extension of the compilation target file is ".min.js" under that directory. If the end does not end with a slash and it does not exist as a directory, it is saved as a file. If multiple compilation targets are the same save destination file, it will be appended.

- -w  
コンパイルはされず、コンパイル対象ディレクトリ／ファイルを監視し、変更があった場合にコンパイルされます。  
コンパイル対象ファイルに変更があった場合、同じ保存先ファイルが指定されているコンパイル対象ファイルはすべてコンパイルされます。  
It is not compiled, it monitors the compilation target directory/file and compiles it when there is a change. If there is a change in the compilation target file, all files to be compiled for which the same save destination file is specified are compiled.

- -n  
コンパイル／minify化されたJSコードの末尾に、inline sourceMapを追記しません。  
Do not append inline sourceMap to the end of compiled/minified JS code.  

- -m  
コンパイルされた結果をminify化しません。  
複数ディレクトリの監視だけを行いたい場合に使用します。  
Do not minify compiled results.  
Use this when you want to watch multiple directories only.
  
## License
  
The MIT License (MIT)  
Copyright (c) 2018 Hajime Oh-yake

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:  

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.  

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.  

