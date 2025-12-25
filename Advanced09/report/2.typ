#import "@preview/codelst:2.0.2": sourcecode, sourcefile

== 課題 2-1

修正したコードは以下のようになった。
なお、Python の実装において black フォーマッタツールによりコードフォーマットをかけているため、★ 以外の場所で提供されたものから若干の変更がある。

#sourcefile(read("../PoissonImage/PoissonImage.py"), file:"PoissonImage.py")

また、実行結果は @f2 のようになった。

#figure(
  image("figure2.png", width: 100%),
  caption: [課題2-1 の実行結果]
) <f2>

期待されている動作がされていることが確認できる。
