#import "@preview/codelst:2.0.2": sourcecode, sourcefile

#set enum(numbering: "(a)")

== 課題 1

本課題は `ColorTransfer.py` を修正し、Output に正しい結果が出力されるようにするものである。

修正したコードは以下のようになった。
なお、Python の実装において black フォーマッタツールによりコードフォーマットをかけているため、★ 以外の場所で提供されたものから若干の変更がある。

#sourcefile(read("../ColorTransfer/ColorTransfer.py"), file:"ColorTransfer.py")

また、実行結果は @f1 のようになった。

#figure(
  image("figure1.png", width: 100%),
  caption: [課題1-1, 1-2 の実行結果]
) <f1>

== 発展課題 1

