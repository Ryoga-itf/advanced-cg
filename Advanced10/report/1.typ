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
  caption: [課題1の実行結果]
) <f1>

== 発展課題 1

本課題は local color transfer を実装するというものである。

スライド 7,8 ページの Local Color Transfer は、

- source/target を GMM でクラスタリング
- クラスタ対応付け（色や位置の近さ）
- クラスタ単位の平均・標準偏差合わせを、所属確率 $P_k$ で混ぜる（L だけでなく a, b も同様）

という流れになっている。

特に出力は、各画素で

$
L_o (x, y) = sum_k P_k (x, y) ( sigma^L_(s,k) / sigma^L_(t,k) (L_t (x,y) - mu^L_(t,k)) + mu^L_(s,k) )
$

（a, b も同様）をやれ、という式になっている。

コードは以下のようになった。

#sourcefile(read("../ColorTransfer/ColorTransfer_appendix.py"), file:"ColorTransfer_appendix.py")

クラスタリングには、`scikit-learn` を用いた。`pip install scikit-learn` のようなコマンドにより依存関係を追加した。

今回のアルゴリズムは以下の通りである。

- target/source を Lab に変換し、各画素を特徴量 $[L, a, b, x, y]$ （位置は `pos_weight`）で表現して確率的クラスタリングを行い、画素ごとの所属確率 $P_k(x, y)$ を得た。(1)
- 各クラスタについて、Lab 各チャネルの重み付き平均・標準偏差 $mu_(t,k), sigma_(t,k)$ と $mu_(s,k), sigma_(s,k)$ を計算する。(2)
- クラスタ対応付けは、クラスタの Lab 平均（a, b を重視）の距離が最小になるように Hungarian で決定した。(3)
- 最終出力はスライドの式に従い、各画素でクラスタごとの Reinhard 型変換を計算し、$P_k(x, y)$ で混合した。(4)

なお、対応する部分に数字のコメントを入れている。

実行結果は @f2 のようになった。

#figure(
  image("figure2.png", width: 100%),
  caption: [発展課題1の実行結果]
) <f2>
