# -*- coding: utf-8 -*-
import cv2
import numpy as np
import scipy.sparse
import scipy.sparse.linalg
from matplotlib import pyplot as plt

# 画像の読み込みと前処理
source = cv2.imread("fg.jpg")
mask = cv2.imread("mask.png", 0)  # Grayscale (1チャネル)で読むときは第2引数を0にする
h, w, _ = source.shape
target = cv2.imread("bg.jpg")
target = cv2.resize(target, (w, h))
source = source[:, :, ::-1].astype(np.double)
target = target[:, :, ::-1].astype(np.double)
mask = (
    mask / 255.0
)  # 0～1に正規化（コピーしたい前景領域（Ωの内側）を1,それ以外（Ωの外側）を0にする)

# 行列Aを計算
I = scipy.sparse.diags(
    mask.ravel(), format="csc"
)  # 計算用に対角成分にマスクの値を持った画素数x画素数の疎行列を作成
A = (
    scipy.sparse.eye(w * h) - I
)  # Ωの外側(maskの値が0)の領域における画素と対応する対角成分に1を持つ疎行列を用意
# ★Ωの内側(maskの値が1の領域)における画素と対応する行列Aの対角成分から4を減算
A += scipy.sparse.hstack(
    (I[:, -1:], I[:, :-1])
)  # Ω内の画素と対応する行、かつその右隣の画素と対応する列に1を加算
# ★同様に左隣に1を加算
# ★同様に上隣に1を加算
# ★同様に下隣に1を加算

# ベクトルbを計算
b = target.copy()  # ターゲット画像のコピーを代入
lap = np.zeros((h, w, 3), dtype=np.float64)  # ラプラシアンの計算結果を入れる配列
# ★ソース画像のラプラシアンを計算しlapに代入
b[mask > 0] = lap[mask > 0]  # Ωの内側にはソース画像のラプラシアンを代入

# Ax=bを解いてxを求める
b = b.reshape((h * w, 3))
x = scipy.sparse.linalg.spsolve(A, b)
output = x.reshape((h, w, 3))

# 後処理と画像の出力
output = np.clip(output, 0, 255)
output = output.astype(np.uint8)
source = source.astype(np.uint8)
target = target.astype(np.uint8)
plt.figure(figsize=(20, 10))
plt.subplot(1, 3, 1)
plt.imshow(source)
plt.xlabel("Source")
plt.subplot(1, 3, 2)
plt.imshow(target)
plt.xlabel("Target")
plt.subplot(1, 3, 3)
plt.imshow(output)
plt.xlabel("Output")
plt.show()
