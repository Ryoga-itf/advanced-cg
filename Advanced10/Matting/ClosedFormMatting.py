# -*- coding: utf-8 -*-
import cv2
import numpy as np
import scipy.sparse
import scipy.sparse.linalg
from matplotlib import pyplot as plt

image = cv2.imread("source.png")  # 入力画像の読み込み
trimap = cv2.imread("trimap.png", 0)
h, w, c = image.shape
image = image[:, :, ::-1].astype(np.double)
trimap = trimap.astype(np.double)

# Matting Laplacianを計算
print("Computing matting laplacian...")
window_radius = 1
eps = 1e-3
num_window_pixels = (window_radius * 2 + 1) ** 2
pixels_indices = np.array(range(w * h)).reshape(
    h, w
)  # 各画素にインデックスを割り当てておく
laplacian_values = []  # 後で疎行列化するためにLaplacianの値を格納しておくリスト
row_ind, col_ind = (
    [],
    [],
)  # 後で疎行列化するためにLaplacianと対応する列番号と行番号を格納しておくリスト
for y in range(window_radius, w - window_radius):
    for x in range(window_radius, h - window_radius):
        window_x_start, window_x_end = (
            x - window_radius,
            x + window_radius + 1,
        )  # 窓の両端のx座標を計算
        window_y_start, window_y_end = (
            y - window_radius,
            y + window_radius + 1,
        )  # 窓の両端のy座標を計算
        window_values = image[
            window_x_start:window_x_end, window_y_start:window_y_end, :
        ]  # 窓内の画素値を取得
        window_values = window_values.reshape((num_window_pixels, c))

        mean = np.mean(window_values, axis=0)  # ☆①
        cov = np.matmul(window_values.T, window_values) / num_window_pixels - np.matmul(
            mean.reshape(c, 1), mean.reshape(c, 1).T
        )  # ☆②
        inv_cov = np.linalg.inv(cov + eps / num_window_pixels * np.identity(c))  # ☆③
        dev = window_values - mean.reshape(1, c).repeat(num_window_pixels, axis=0)  # ☆④
        window_values = (
            np.eye(num_window_pixels)
            - (1 + np.matmul(np.matmul(dev, inv_cov), dev.T)) / num_window_pixels
        )  # ☆⑤
        laplacian_values.extend(
            window_values.ravel()
        )  # 疎行列化のためにラプラシアンの値をリストに保存しておく

        window_indices = pixels_indices[
            window_x_start:window_x_end, window_y_start:window_y_end
        ].ravel()  # 窓内の画素インデックスを取得
        ind_mat = window_indices.reshape(1, num_window_pixels).repeat(
            num_window_pixels, axis=0
        )  # 下で行番号と列番号を計算するための準備
        row_ind.extend(
            ind_mat.ravel()
        )  # 上記のラプラシアンの値と対応する行番号をリストに保存しておく
        col_ind.extend(
            ind_mat.T.ravel()
        )  # 上記のラプラシアンの値と対応する列番号をリストに保存しておく

# Matting Laplacian の疎行列化 (重複する行列番号がある場合は値が加算される)
L = scipy.sparse.csc_matrix(
    (laplacian_values, (row_ind, col_ind)), shape=(w * h, w * h)
)

# 線形方程式Ax=bの行列A(スライドのL+λD)とベクトルb(スライドのλc)の計算
print("Solving optimization problem...")
lambd = 100.0  # Trimap を重視する重み
A = L  # 仮の値を代入
b = trimap.ravel()  # 仮の値を代入
# ★以下に正しいAとbの計算処理を記述

# trimap: 0(background), 255(foreground), 128(unknown) を想定
trimap01 = trimap / 255.0

# D: 前景 or 背景で確定している画素だけ 1（未知は0）
known = (trimap <= 1) | (trimap >= 254)  # 0/255以外を未知扱い（閾値は適宜OK）
D = scipy.sparse.diags(known.ravel().astype(np.double), format="csc")

# c: 前景=1、それ以外=0（背景も未知も0）
cvec = np.zeros(h * w, dtype=np.double)
cvec[(trimap >= 254).ravel()] = 1.0

# A = L + λD,  b = λc
A = L + lambd * D
b = lambd * cvec


# Ax=bにおけるx(スライドのα)について解く
x = scipy.sparse.linalg.spsolve(A, b)
output = x.reshape(h, w)

# 後処理と画像の出力
output = np.clip(output * 255.0, 0, 255)  # 0～1前後の値を可視化のために正規化
output = np.expand_dims(output, 2).repeat(3, 2).astype(np.uint8)
image = image.astype(np.uint8)
trimap = np.expand_dims(trimap, 2).repeat(3, 2).astype(np.uint8)
plt.figure(figsize=(20, 10))
plt.subplot(1, 3, 1)
plt.imshow(image)
plt.xlabel("Image")
plt.subplot(1, 3, 2)
plt.imshow(trimap)
plt.xlabel("Trimap")
plt.subplot(1, 3, 3)
plt.imshow(output)
plt.xlabel("Output")
plt.show()
