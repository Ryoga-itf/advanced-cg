# -*- coding: utf-8 -*-
import numpy as np
import cv2
from matplotlib import pyplot as plt

#画像の読み込みと前処理
target = cv2.imread('image1.jpg') #ソース画像の読み込み
source = cv2.imread('image2.jpg') #ターゲット画像の読み込み
target = target[:,:,::-1] #BGR色空間からRGB色空間への変換
source = source[:,:,::-1] #同上
target_lab = cv2.cvtColor(target, cv2.COLOR_RGB2Lab) #RGB色空間からLab色空間に変換
source_lab = cv2.cvtColor(source, cv2.COLOR_RGB2Lab) #同上
output_lab = np.zeros(target.shape) #出力用の仮の配列（この配列に結果を代入する）

###★以下にColor Transfer の処理を書く###
###★target_lab の平均・標準偏差をsource_lab に合わせた結果をoutput_lab に代入###






#後処理と画像の出力
output_lab = np.clip(output_lab,0,255) #Lab色空間の上限下限を超えた値をクリップ
output_lab = output_lab.astype(np.uint8) #Float型を画像の階調に合わせたUnsigned Int 型に変換
output = cv2.cvtColor(output_lab, cv2.COLOR_Lab2RGB) #Lab色空間からRGB色空間に変換
plt.figure(figsize=(20,10))
plt.subplot(1,3,1)
plt.imshow(target)
plt.xlabel('Target')
plt.subplot(1,3,2)
plt.imshow(source)
plt.xlabel('Source')
plt.subplot(1,3,3)
plt.imshow(output)
plt.xlabel('Output')
plt.show()