#import "@preview/codelst:2.0.2": sourcecode, sourcefile

== 課題 2-1

修正したコードは以下のようになった。
なお、Python の実装において black フォーマッタツールによりコードフォーマットをかけているため、★ 以外の場所で提供されたものから若干の変更がある。

#sourcefile(read("../Matting/ClosedFormMatting.py"), file:"ClosedFormMatting.py")

また、実行結果は @f3 のようになった。

#figure(
  image("figure3.png", width: 100%),
  caption: [課題2-1 の実行結果]
) <f3>

期待されている動作がされていることが確認できる。

== 課題 2-2

本課題はサンプルコードのマッティングラプラシアンの計算処理において28～32行目（☆①～⑤）の各行は何を計算しているか説明せよ、というものである。

/ ☆① `mean = np.mean(window_values, axis=0)`:\
  局所窓内の RGB 平均ベクトル $mu_k$ （3次元）を計算している。

/ ☆② `cov = ...`:\
  局所窓内の色の分散共分散行列 $sum_k$ （3×3）を計算している。

  式の形は
  $
  sum_k = E[I I^T] - mu_k mu_k^T
  $
  に対応する。(`window_values.T @ window_values / n - mean*mean^T`)

/ ☆③ `inv_cov = inv(cov + eps/n * I)`:\
  $sum_k$ が特異・不安定にならないように正規化項 $epsilon / n I$ を足してから、その逆行列 $(sum_k + epsilon / n I)^(-1)$ を計算している。

/ ☆④ `dev = window_values - mean ...`:\
  各画素の色から平均との差を取った偏差
  $
  I_i - mu_k
  $
  を作っている。（窓内画素数 $n$ 個分、形状は $n times 3$）

/ ☆⑤ `window_values = I - (1 + dev inv_cov dev.T)/n`:\
  局所窓に対応するマッティング・ラプラシアンのブロック（$n times n$）を作っている。
  中身の `dev @ inv_cov @ dev.T` は、窓内の画素 $i,j$ の「色の近さ（共分散で正規化した内積）」に相当し、それを使って
  $
  delta_(i,j) - (1 + (I_i - mu_k)^T (sum_k + epsilon / n I)^(-1) (I_j - mu_k)) / n
  $
  という形の係数（窓からの寄与）を作り、後で全窓の寄与を足し合わせて全体の $L$ を構成している。
