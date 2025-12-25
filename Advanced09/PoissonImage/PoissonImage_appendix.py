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
A -= 4 * I  # Ω内の画素と対応する対角成分を -4 にする
A += scipy.sparse.hstack(
    (I[:, -1:], I[:, :-1])
)  # Ω内の画素と対応する行、かつその右隣の画素と対応する列に1を加算
# ★同様に左隣に1を加算
A += scipy.sparse.hstack((I[:, 1:], I[:, :1]))
# ★同様に上隣に1を加算
A += scipy.sparse.hstack((I[:, w:], I[:, :w]))
# ★同様に下隣に1を加算
A += scipy.sparse.hstack((I[:, -w:], I[:, :-w]))

# ベクトルbを計算
b = target.copy()  # ターゲット画像のコピーを代入
lap = np.zeros((h, w, 3), dtype=np.float64)  # ラプラシアンの計算結果を入れる配列
# ★ソース画像のラプラシアンを計算しlapに代入
# 発展課題 2: Target gradient の与え方を変更
mode = "stylize"  # "mix" | "scale" | "stylize"
grad_scale = 2.0  # mode="scale"
canny1, canny2 = 80, 160  # mode="stylize"

pad_s = np.pad(source, ((1, 1), (1, 1), (0, 0)), mode="reflect")
pad_t = np.pad(target, ((1, 1), (1, 1), (0, 0)), mode="reflect")

cs = pad_s[1:-1, 1:-1]
rs = pad_s[1:-1, 2:]
ls = pad_s[1:-1, :-2]
us = pad_s[:-2, 1:-1]
ds = pad_s[2:, 1:-1]

ct = pad_t[1:-1, 1:-1]
rt = pad_t[1:-1, 2:]
lt = pad_t[1:-1, :-2]
ut = pad_t[:-2, 1:-1]
dt = pad_t[2:, 1:-1]

# 勾配
gs_r, gs_l, gs_u, gs_d = cs - rs, cs - ls, cs - us, cs - ds
gt_r, gt_l, gt_u, gt_d = ct - rt, ct - lt, ct - ut, ct - dt


def pick_larger(gs, gt):
    # 勾配の大きさ（RGBのL2ノルム）で比較
    ms = np.sum(gs * gs, axis=2)
    mt = np.sum(gt * gt, axis=2)
    use_s = (ms >= mt)[..., None]
    return np.where(use_s, gs, gt)


if mode == "mix":
    g_r = pick_larger(gs_r, gt_r)
    g_l = pick_larger(gs_l, gt_l)
    g_u = pick_larger(gs_u, gt_u)
    g_d = pick_larger(gs_d, gt_d)
elif mode == "scale":
    # 元の勾配をスケール（Local Tone Mappingの雰囲気）
    g_r, g_l, g_u, g_d = (
        gs_r * grad_scale,
        gs_l * grad_scale,
        gs_u * grad_scale,
        gs_d * grad_scale,
    )
elif mode == "stylize":
    # エッジ以外の勾配をゼロ（Stylizationの雰囲気）
    gray = cv2.cvtColor(np.clip(source, 0, 255).astype(np.uint8), cv2.COLOR_RGB2GRAY)
    edges = cv2.Canny(gray, canny1, canny2).astype(np.float64) / 255.0
    # エッジ周辺も含めるために少し膨張
    edges = cv2.dilate(edges, np.ones((3, 3), np.uint8), iterations=1)
    edges = edges[..., None]  # (H,W,1)
    g_r, g_l, g_u, g_d = gs_r * edges, gs_l * edges, gs_u * edges, gs_d * edges
else:
    raise ValueError("unknown mode")

# Poissonの右辺：-Σ g_pq （= Σ (I(q)-I(p)) に相当）
lap = -(g_r + g_l + g_u + g_d)
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
