# -*- coding: utf-8 -*-
import cv2
import numpy as np
from matplotlib import pyplot as plt


def bilateral_filter_gray(
    img: np.ndarray, diameter: int, sigma_r: float, sigma_p: float
) -> np.ndarray:
    assert img.ndim == 2
    assert diameter % 2 == 1 and diameter >= 1
    H, W = img.shape
    r = diameter // 2

    # reduce
    pad = np.pad(img, ((r, r), (r, r)), mode="reflect").astype(np.float32)

    # pre-compute
    ys, xs = np.mgrid[-r : r + 1, -r : r + 1].astype(np.float32)
    spatial = np.exp(-(xs * xs + ys * ys) / (2.0 * (sigma_p * sigma_p))).astype(
        np.float32
    )

    inv_2_sigma_r2 = np.float32(1.0 / (2.0 * (sigma_r * sigma_r)))

    out = np.empty((H, W), dtype=np.float32)
    for y in range(H):
        for x in range(W):
            patch = pad[y : y + diameter, x : x + diameter]
            center = pad[y + r, x + r]
            diff = patch - center
            range_w = np.exp(-(diff * diff) * inv_2_sigma_r2).astype(np.float32)

            w = spatial * range_w
            ws = np.sum(w, dtype=np.float32)
            out[y, x] = np.sum(w * patch, dtype=np.float32) / (ws + 1e-12)

    return out


###線形トーンマッピングの処理###
hdr = cv2.imread("memorial.hdr", -1)[
    :, :, ::-1
]  # HDR画像の読み込み＆BGRからRGBへの変換
hdr_Lab = cv2.cvtColor(
    hdr, cv2.COLOR_RGB2Lab
)  # RGB 色空間からLab 色空間に変換（明度(L)と色(ab)成分に分離）
hdr_L = hdr_Lab[:, :, 0]  # トーンマッピング対象の明度成分のみ抽出
ldr_L = 100.0 * hdr_L / hdr_L.max()  # 最大値が100になるように正規化
ldr_Lab = hdr_Lab.copy()  # LDR 画像の配列を用意
ldr_Lab[:, :, 0] = ldr_L  # トーンマッピングした明度成分を代入
ldr = cv2.cvtColor(ldr_Lab, cv2.COLOR_Lab2RGB)  # Lab 色空間からRGB 色空間に戻す
# 画像の表示
plt.figure(figsize=(20, 10))
plt.subplot(1, 3, 1)
plt.xlabel("Output (Linear)")
plt.imshow(ldr)

###非線形トーンマッピングの処理###
gamma = 1 / 2.2
# 課題 1-1: L' = L^γ, その後に最大値が100になるよう正規化
ldr_L = hdr_L**gamma
ldr_L = 100.0 * ldr_L / ldr_L.max()


ldr_Lab = hdr_Lab.copy()  # LDR 画像の配列を用意
ldr_Lab[:, :, 0] = ldr_L  # トーンマッピングした明度成分を代入
ldr2 = cv2.cvtColor(ldr_Lab, cv2.COLOR_Lab2RGB)  # Lab 色空間からRGB 色空間に戻す
# 画像の表示
plt.subplot(1, 3, 2)
plt.xlabel("Output (Gamma Correction)")
plt.imshow(ldr2)

###バイラテラルフィルタを使った非線形トーンマッピングの処理###
eps = 1e-8  # log10(0)=-inf を避けるための定数
log_hdr_L = np.log10(hdr_L + eps)  # 対数ドメインへ変換
# 課題 1-2: base=BF(log10(L)), detail=log10(L)-base, base' = γ*base, alpha = -max(base') + log10(100), log10(L') = base' + detail + alpha
base = bilateral_filter_gray(log_hdr_L.astype(np.float32), 9, 1, 9)
detail = log_hdr_L - base
base_prime = gamma * base
alpha = -base_prime.max() + np.log10(100.0)
log_hdr_L = base_prime + detail + alpha


ldr_L = 10.0**log_hdr_L - eps  # 対数domain の値を戻す
ldr_L = np.clip(ldr_L, 0.0, 100.0)  # 範囲外の値をクリップ
ldr_Lab = hdr_Lab.copy()  # LDR 画像の配列を用意
ldr_Lab[:, :, 0] = ldr_L  # トーンマッピングした明度成分を代入
ldr3 = cv2.cvtColor(ldr_Lab, cv2.COLOR_Lab2RGB)  # Lab 色空間からRGB 色空間に戻す
# 画像の表示
plt.subplot(1, 3, 3)
plt.xlabel("Output (Gamma Correction + Bilateral Filter)")
plt.imshow(ldr3)

plt.show()
