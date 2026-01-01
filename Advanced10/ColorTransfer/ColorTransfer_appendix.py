# -*- coding: utf-8 -*-
import cv2
import numpy as np
from matplotlib import pyplot as plt

# 画像の読み込みと前処理
target = cv2.imread("image1.jpg")  # ソース画像の読み込み
source = cv2.imread("image2.jpg")  # ターゲット画像の読み込み
target = target[:, :, ::-1]  # BGR色空間からRGB色空間への変換
source = source[:, :, ::-1]  # 同上
target_lab = cv2.cvtColor(target, cv2.COLOR_RGB2Lab)  # RGB色空間からLab色空間に変換
source_lab = cv2.cvtColor(source, cv2.COLOR_RGB2Lab)  # 同上
output_lab = np.zeros(target.shape)  # 出力用の仮の配列（この配列に結果を代入する）

###★以下にColor Transfer の処理を書く###
###★target_lab の平均・標準偏差をsource_lab に合わせた結果をoutput_lab に代入###

from scipy.optimize import linear_sum_assignment
from sklearn.mixture import GaussianMixture

# Local Color Transfer
K = 6  # クラスタ数
pos_weight = 0.3  # 位置 (x, y) をどれくらいクラスタに効かせるか
eps = 1e-6

H, W = target_lab.shape[:2]


def make_feat(lab_img):
    h, w = lab_img.shape[:2]
    lab = lab_img.astype(np.float32)
    lab01 = lab / 255.0

    yy, xx = np.mgrid[0:h, 0:w]
    x01 = (xx.astype(np.float32) / max(w - 1, 1)).reshape(-1, 1)
    y01 = (yy.astype(np.float32) / max(h - 1, 1)).reshape(-1, 1)

    lab_flat = lab01.reshape(-1, 3)
    feat = np.concatenate([lab_flat, pos_weight * x01, pos_weight * y01], axis=1)
    return feat, lab.reshape(-1, 3)  # Lab : 0..255


def softmax(x):
    x = x - x.max(axis=1, keepdims=True)
    e = np.exp(x)
    return e / (e.sum(axis=1, keepdims=True) + 1e-12)


def cluster_resp(feat, K):
    gmm = GaussianMixture(
        n_components=K,
        covariance_type="full",
        reg_covar=1e-6,
        max_iter=200,
        random_state=0,
    )
    gmm.fit(feat)
    resp = gmm.predict_proba(feat)  # (N,K)
    return resp


def weighted_mean_std(x, w):
    # x: (N,3) w:(N,) -> mean/std: (3,)
    wsum = np.sum(w) + eps
    m = np.sum(x * w[:, None], axis=0) / wsum
    v = np.sum(((x - m) ** 2) * w[:, None], axis=0) / wsum
    s = np.sqrt(np.maximum(v, eps))
    return m, s


# 1
t_feat, t_lab_flat = make_feat(target_lab)
s_feat, s_lab_flat = make_feat(source_lab)

t_resp = cluster_resp(t_feat, K)  # (N,K) = P_k(x,y)
s_resp = cluster_resp(s_feat, K)

# 2
t_mu = np.zeros((K, 3), np.float32)
t_sd = np.zeros((K, 3), np.float32)
s_mu = np.zeros((K, 3), np.float32)
s_sd = np.zeros((K, 3), np.float32)

for k in range(K):
    t_mu[k], t_sd[k] = weighted_mean_std(t_lab_flat, t_resp[:, k])
    s_mu[k], s_sd[k] = weighted_mean_std(s_lab_flat, s_resp[:, k])

t_sd = np.maximum(t_sd, eps)
s_sd = np.maximum(s_sd, eps)

# 3
cost = np.zeros((K, K), np.float32)
for kt in range(K):
    for ks in range(K):
        # a, b
        dv = t_mu[kt, 1:3] - s_mu[ks, 1:3]
        cost[kt, ks] = np.sqrt(np.sum(dv * dv))

mapping = -np.ones(K, dtype=np.int32)

r, c = linear_sum_assignment(cost)
mapping[r] = c

# 4
N = t_lab_flat.shape[0]
out_flat = np.zeros((N, 3), np.float32)

for kt in range(K):
    ks = mapping[kt]
    w = t_resp[:, kt : kt + 1]  # (N,1)
    # (sigma_s / sigma_t) * (x - mu_t) + mu_s
    transformed = (t_lab_flat - t_mu[kt]) * (s_sd[ks] / t_sd[kt]) + s_mu[ks]
    out_flat += w * transformed

output_lab = out_flat.reshape(H, W, 3)

# 後処理と画像の出力
output_lab = np.clip(output_lab, 0, 255)  # Lab色空間の上限下限を超えた値をクリップ
output_lab = output_lab.astype(
    np.uint8
)  # Float型を画像の階調に合わせたUnsigned Int 型に変換
output = cv2.cvtColor(output_lab, cv2.COLOR_Lab2RGB)  # Lab色空間からRGB色空間に変換
plt.figure(figsize=(20, 10))
plt.subplot(1, 3, 1)
plt.imshow(target)
plt.xlabel("Target")
plt.subplot(1, 3, 2)
plt.imshow(source)
plt.xlabel("Source")
plt.subplot(1, 3, 3)
plt.imshow(output)
plt.xlabel("Output")
plt.show()
