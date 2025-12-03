#import "/common/template.typ": *
#import "@preview/tenv:0.1.2": parse_dotenv
#import "@preview/codelst:2.0.2": sourcecode, sourcefile

#let env = parse_dotenv(read("/.env"))

#show: project.with(
  week: "第1回 課題",
  authors: (
    (name: env.STUDENT_NAME, email: "学籍番号：" + env.STUDENT_ID, affiliation: "所属：情報科学類"),
  ),
  date: "2025 年 10 月 16 日",
)

#show math.equation: set text(font: ("New Computer Modern Math", "Noto Serif", "Noto Serif CJK JP"))

本課題を行った環境を以下に示す。
OS は Void Linux である。

#sourcecode[```
$ cat /proc/version
Linux version 6.12.52_1 (voidlinux@voidlinux) (gcc (GCC) 14.2.1 20250405, GNU ld (GNU Binutils) 2.44) #1 SMP PREEMPT_DYNAMIC Sun Oct 12 20:52:41 UTC 2025
```]

また、プログラム起動時に表示される文字列情報は以下の通りである。

#sourcecode[```
OpenGL version: 4.6 (Compatibility Profile) Mesa 25.1.9
GLSL version: 4.60
Vendor: Intel
Renderer: Mesa Intel(R) Iris(R) Xe Graphics (RPL-U)
```]

== (1) 格子模様の描画

GLSL のソースコードは以下のようになった。

#sourcecode[```glsl
// scene01_checker2D.vert
#version 130

in vec4 vertexPosition;
in vec2 inTexCoord;

out vec2 outTexCoord;

void main()
{
	gl_Position = vertexPosition;
	outTexCoord = inTexCoord;
}
```]

#sourcecode[```glsl
// scene01_checker2D.frag
#version 130

in vec2 outTexCoord;
out vec4 fragColor;

uniform vec4 checkerColor0;
uniform vec4 checkerColor1;
uniform vec2 checkerScale;

void main()
{
	vec2 uv = outTexCoord / checkerScale;
	vec2 st = fract(uv);

	bool f = (st.x <= 0.5) ^^ (st.y <= 0.5);

	fragColor = f ? checkerColor1 : checkerColor0;
}
```]

インターネット上で調べると、GLSL では論理演算が使えるようであった。#footnote[https://learnwebgl.brown37.net/12_shader_language/glsl_mathematical_operations.html]
そのため、格子模様の描画に際して XOR 演算を用いて判定を行っている。

実行結果は以下の通りである。

#figure(
  image("scene01_0.png", width: 48%),
  caption: [課題1の実行結果]
)

== (2) 画像ぼかし

GLSL のソースコードは以下のようになった。

#sourcecode[```glsl
// scene02_image_smoothing.vert
#version 130

in vec4 vertexPosition;
in vec2 inTexCoord;

out vec2 outTexCoord;

void main()
{
	gl_Position = vertexPosition;
	outTexCoord = inTexCoord;
}
```]

#sourcecode[```glsl
// scene02_image_smoothing.frag
#version 130

in vec2 outTexCoord;
out vec4 fragColor;

uniform sampler2D tex;
uniform int halfKernelSize;
uniform float uScale;
uniform float vScale;

void main()
{
	if (halfKernelSize <= 0) {
		fragColor = texture2D(tex, outTexCoord);
		return;
	}

	float div = halfKernelSize * halfKernelSize;

	vec4 acc = vec4(0.0);
	float wsum = 0.0;

	for (int j = -halfKernelSize; j <= halfKernelSize; ++j) {
		for (int i = -halfKernelSize; i <= halfKernelSize; ++i) {
			float dx = float(i);
			float dy = float(j);
			float r2 = dx * dx + dy * dy;
			float w = exp(-r2 / div);

			vec2 offset = vec2(dx * uScale, dy * vScale);
			vec4 c = texture2D(tex, outTexCoord + offset);

			acc += c * w;
			wsum += w;
		}
	}

	if (wsum > 0.0) {
		acc /= wsum;
	}

	fragColor = acc;
}
```]

コーナーケースとして `0` 除算を回避するため、指定の通り `halfKernelSize` が `0` のとき例外処理を入れている。
また、ガウスぼかしにおいては課題の説明で示されていたガウス関数の例を用いた。
ガウス関数は、$y$ 軸に対称であるので、関数における $x$ が $[0, 1]$ に収まるようにスケーリングしている。

実行結果は以下の通りである。

#stack(
  dir: ltr,
  spacing: 1em,
  figure(
    image("scene02_0.png", width: 48%),
    caption: [課題2の実行結果 (`halfKernelSize = 30`)]
  ),
  figure(
    image("scene02_1.png", width: 48%),
    caption: [課題2の実行結果 (`halfKernelSize = 0`)]
  )
)

== (3) 簡易アニメーション

GLSL のソースコードは以下のようになった。

#sourcecode[```glsl
// scene03_wave_animation.vert
#version 130

in vec4 vertexPosition;

uniform float temporalSignal;
uniform mat4 projModelViewMatrix;

void main()
{
	float x = vertexPosition.x;
	float z = vertexPosition.z;

	float wave = sin(temporalSignal + x) * 0.5 + cos(temporalSignal + z) * 0.5;
	float y = wave;

	gl_Position = projModelViewMatrix * vec4(x, y, z, 1.0);
}
```]

#sourcecode[```glsl
// scene03_wave_animation.frag
out vec4 fragColor;

uniform vec4 lineColor;

void main()
{
	fragColor = lineColor;
}
```]

実行結果は以下の通りである。
アニメーションしている様子がわかるように複数枚載せている。

#stack(
  dir: ltr,
  spacing: 1em,
  figure(
    image("scene03_0.png", width: 48%),
    caption: [課題3の実行結果]
  ),
  figure(
    image("scene03_1.png", width: 48%),
    caption: [課題3の実行結果]
  )
)

== (4) 法線の表示

GLSL のソースコードは以下のようになった。

#sourcecode[```glsl
// scene04_pseudo_normal.vert
#version 130

in vec4 vertexPosition;
in vec3 vertexNormal;

out vec3 vVertexNormal;

uniform mat4 modelViewMatrix;
uniform mat4 projMatrix;
uniform mat3 modelViewInvTransposed;

void main()
{
	gl_Position = projMatrix * modelViewMatrix * vertexPosition;

	vec3 n_view = normalize(modelViewInvTransposed * vertexNormal);
	vVertexNormal = n_view;
}
```]

#sourcecode[```glsl
// scene04_pseudo_normal.frag
#version 130

in vec3 vVertexNormal;
out vec4 fragColor;

void main()
{
	vec3 c = 0.5 * normalize(vVertexNormal) + 0.5;
	fragColor = vec4(c, 1.0);
}
```]

実行結果は以下の通りである。

#stack(
  dir: ltr,
  spacing: 1em,
  figure(
    image("scene04_0.png", width: 48%),
    caption: [課題4の実行結果 (`Pseudo Normal`)]
  ),
  figure(
    image("scene04_1.png", width: 48%),
    caption: [課題4の実行結果 (`Texture + WireFrame`)]
  )
)

== (5) 環境マッピング

GLSL のソースコードは以下のようになった。

#sourcecode[```glsl
// scene05_envmap.vert
#version 130

in vec4 vertexPosition;
in vec3 vertexNormal;

out vec3 vWorldEyeDir;
out vec3 vWorldNormal;

uniform mat4 projModelViewMatrix;
uniform vec3 eye;

void main()
{
	vec3 world_pos = vertexPosition.xyz;
	vWorldEyeDir = normalize(world_pos - eye);

	vWorldNormal = normalize(vertexNormal);

	gl_Position = projModelViewMatrix * vertexPosition;
}
```]

#sourcecode[```glsl
// scene05_envmap.frag
#version 130

#define PI 3.141592653589793

in vec3 vWorldEyeDir;
in vec3 vWorldNormal;

out vec4 fragColor;
uniform sampler2D envmap;

float atan2(in float y, in float x)
{
    return x == 0.0 ? sign(y)*PI/2 : atan(y, x);
}

void main()
{
	vec3 ref = reflect(-normalize(vWorldEyeDir), normalize(vWorldNormal));

	float u = atan2(ref.z, ref.x) / (2.0 * PI) + 0.5;
	float v = 0.5 - asin(clamp(ref.y, -1.0, 1.0)) / PI;

  vec3 rgb = texture2D(envmap, vec2(u, v)).rgb;
	fragColor = vec4(rgb, 1.0);
}
```]

実行結果は以下の通りである。

#figure(
  image("scene05_0.png", width: 48%),
  caption: [課題5の実行結果]
)

== オプション課題

シェーダーが並列処理に向いているのならば、たくさんの更新が発生するライフゲームを描画するのに向いているのではないかと思い、ライフゲームを描画するプログラムを実装した。
C++ のコードは `Scene01Checker2D.*` をもとに実装した。

なお、コードフォーマットのために ClangFormat を用いている。

#sourcecode[```cpp
// Scene06.h
#pragma once

#include "AbstractScene.h"
#include "imgui.h"
#include <string>

class Scene06 : public AbstractScene {
public:
  static void Init();
  static void ReloadShaders();
  static void Draw();
  static void Cursor(GLFWwindow *window, double xpos, double ypos) {}
  static void Mouse(GLFWwindow *window, int button, int action, int mods) {}
  static void Resize(GLFWwindow *window, int w, int h);
  static void ImGui();
  static void Destroy();

private:
  static GLSLProgramObject *s_pShader;
  static std::string s_VertexShaderFilename, s_FragmentShaderFilename;

  static GLuint s_VBO, s_VAO;

  static GLuint s_StateTex[2], s_FBO[2];
  static int s_Ping;
  static int s_GridW, s_GridH;
  static bool s_Running;

  static void CreateStateResources(int w, int h);
  static void DestroyStateResources();
  static void UpdateOnce();
  static void BlitToScreen();
};
```]

#sourcecode[```cpp
// Scene06.cpp
#include "Scene06.h"
#include "PathFinder.h"
#include "glm/glm.hpp"
#include "glm/gtc/matrix_transform.hpp"
#include "glm/gtc/type_ptr.hpp"
#include <iostream>
#include <random>

using namespace std;

string Scene06::s_VertexShaderFilename = "scene06_lifegame.vert";
string Scene06::s_FragmentShaderFilename = "scene06_lifegame.frag";
GLSLProgramObject *Scene06::s_pShader = 0;

GLuint Scene06::s_VBO = 0;
GLuint Scene06::s_VAO = 0;

GLuint Scene06::s_StateTex[2] = {0, 0};
GLuint Scene06::s_FBO[2] = {0, 0};
int Scene06::s_Ping = 0;

int Scene06::s_GridW = 512;
int Scene06::s_GridH = 512;

bool Scene06::s_Running = true;

void Scene06::Init() {
  ReloadShaders();
  CreateStateResources(s_GridW, s_GridH);
}

void Scene06::ReloadShaders() {
  if (s_pShader)
    delete s_pShader;
  s_pShader = new GLSLProgramObject();

  PathFinder finder;
#ifdef __APPLE__
  finder.addSearchPath("GLSL_Mac");
  finder.addSearchPath("../GLSL_Mac");
  finder.addSearchPath("../../GLSL_Mac");
#else
  finder.addSearchPath("GLSL");
  finder.addSearchPath("../GLSL");
  finder.addSearchPath("../../GLSL");
#endif

  const GLuint vertexPositionLocation = 0;
  const GLuint inTexCoordLocation = 1;

  s_pShader->attachShaderSourceFile(finder.find(s_VertexShaderFilename).c_str(),
                                    GL_VERTEX_SHADER_ARB);
  s_pShader->attachShaderSourceFile(
      finder.find(s_FragmentShaderFilename).c_str(), GL_FRAGMENT_SHADER_ARB);
  s_pShader->setAttributeLocation("vertexPosition", vertexPositionLocation);
  s_pShader->setAttributeLocation("inTexCoord", inTexCoordLocation);
  s_pShader->link();

  if (!s_pShader->linkSucceeded()) {
    cerr << __FUNCTION__ << ": shader link failed" << endl;
    s_pShader->printProgramLog();
    return;
  }

  // build a screen-sized quad

  float quadVertices[] = {-1, -1, 1, -1, 1, 1, -1, -1, 1, 1, -1, 1};
  float quadTexCoords[] = {0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1};

  if (!s_VAO)
    glGenVertexArrays(1, &s_VAO);
  glBindVertexArray(s_VAO);

  if (!s_VBO)
    glGenBuffers(1, &s_VBO);
  glBindBuffer(GL_ARRAY_BUFFER, s_VBO);

  glBufferData(GL_ARRAY_BUFFER, sizeof(quadVertices) + sizeof(quadTexCoords),
               NULL, GL_STATIC_DRAW);
  glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(quadVertices), quadVertices);
  glBufferSubData(GL_ARRAY_BUFFER, sizeof(quadVertices), sizeof(quadTexCoords),
                  quadTexCoords);

  glEnableVertexAttribArray(vertexPositionLocation);
  glVertexAttribPointer(vertexPositionLocation, 2, GL_FLOAT, GL_FALSE, 0,
                        (const void *)0); // vertices

  glEnableVertexAttribArray(inTexCoordLocation);
  glVertexAttribPointer(
      inTexCoordLocation, 2, GL_FLOAT, GL_FALSE, 0,
      (const void *)sizeof(quadVertices)); // texture coordinates

  glBindBuffer(GL_ARRAY_BUFFER, 0);
  glBindVertexArray(0);
}

void Scene06::Draw() {
  // update
  if (s_Running) {
    UpdateOnce(); // ping -> pong
  }

  // display
  BlitToScreen();
}

void Scene06::Resize(GLFWwindow *window, int w, int h) {
  AbstractScene::Resize(window, w, h);
}

void Scene06::ImGui() {
  ImGui::Text("Scene06 Menu:");

  if (ImGui::Button("Reload Shaders")) {
    ReloadShaders();
  }
}

void Scene06::Destroy() {
  if (s_pShader)
    delete s_pShader;
  if (s_VAO)
    glDeleteVertexArrays(1, &s_VAO);
  if (s_VBO)
    glDeleteBuffers(1, &s_VBO);
  DestroyStateResources();
}

static GLuint CreateStateTexture(int w, int h, const void *data) {
  GLuint tex = 0;
  glGenTextures(1, &tex);
  glBindTexture(GL_TEXTURE_2D, tex);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE,
               data);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glBindTexture(GL_TEXTURE_2D, 0);
  return tex;
}

void Scene06::CreateStateResources(int w, int h) {
  DestroyStateResources();

  std::vector<unsigned char> img(w * h * 4);
  std::mt19937 rng(std::random_device{}());
  std::uniform_int_distribution<int> b01(0, 1);
  for (int i = 0; i < w * h; ++i) {
    unsigned char v = b01(rng) ? 255 : 0;
    img[i * 4 + 0] = v;
    img[i * 4 + 1] = v;
    img[i * 4 + 2] = v;
    img[i * 4 + 3] = 255;
  }

  s_StateTex[0] = CreateStateTexture(w, h, img.data());
  s_StateTex[1] = CreateStateTexture(w, h, img.data());

  glGenFramebuffers(2, s_FBO);
  for (int i = 0; i < 2; ++i) {
    glBindFramebuffer(GL_FRAMEBUFFER, s_FBO[i]);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,
                           s_StateTex[i], 0);
  }
  glBindFramebuffer(GL_FRAMEBUFFER, 0);

  s_Ping = 0;
}

void Scene06::DestroyStateResources() {
  if (s_FBO[0] || s_FBO[1]) {
    glDeleteFramebuffers(2, s_FBO);
    s_FBO[0] = s_FBO[1] = 0;
  }
  if (s_StateTex[0] || s_StateTex[1]) {
    glDeleteTextures(2, s_StateTex);
    s_StateTex[0] = s_StateTex[1] = 0;
  }
}

void Scene06::UpdateOnce() {
  const int pong = 1 - s_Ping;

  // current viewport
  GLint prevVP[4];
  glGetIntegerv(GL_VIEWPORT, prevVP);

  glBindFramebuffer(GL_FRAMEBUFFER, s_FBO[pong]);
  glViewport(0, 0, s_GridW, s_GridH);

  glDisable(GL_DEPTH_TEST);
  glDisable(GL_CULL_FACE);
  glDisable(GL_BLEND);

  s_pShader->use();
  s_pShader->sendUniform1i("stateTex", 0);
  s_pShader->sendUniform2f("pixelSize", 1.0f / s_GridW, 1.0f / s_GridH);
  s_pShader->sendUniform1i("doUpdate", 1); // update

  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, s_StateTex[s_Ping]);

  glBindVertexArray(s_VAO);
  glDrawArrays(GL_TRIANGLES, 0, 6);
  glBindVertexArray(0);

  s_pShader->disable();

  glBindTexture(GL_TEXTURE_2D, 0);
  glBindFramebuffer(GL_FRAMEBUFFER, 0);

  // restore
  glViewport(prevVP[0], prevVP[1], prevVP[2], prevVP[3]);

  s_Ping = pong; // swap
}

void Scene06::BlitToScreen() {
  glBindFramebuffer(GL_FRAMEBUFFER, 0);

  glDisable(GL_DEPTH_TEST);
  glDisable(GL_CULL_FACE);
  glDisable(GL_BLEND);

  s_pShader->use();
  s_pShader->sendUniform1i("stateTex", 0);
  s_pShader->sendUniform2f("pixelSize", 1.0f / s_GridW, 1.0f / s_GridH);
  s_pShader->sendUniform1i("doUpdate", 0); // display

  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, s_StateTex[s_Ping]);

  glBindVertexArray(s_VAO);
  glDrawArrays(GL_TRIANGLES, 0, 6);
  glBindVertexArray(0);

  s_pShader->disable();

  glBindTexture(GL_TEXTURE_2D, 0);
}
```]

GLSL ファイルは以下のようになった。

#sourcecode[```glsl
// scene06_lifegame.vert
#version 130

in vec4 vertexPosition;
in vec2 inTexCoord;

out vec2 outTexCoord;

void main()
{
	gl_Position = vertexPosition;
	outTexCoord = inTexCoord;
}
```]

これは、`scene01_checker2D.vert` と同一である。

#sourcecode[```glsl
// scene06_lifegame.frag
#version 130

in vec2 outTexCoord;
out vec4 fragColor;

uniform sampler2D stateTex;
uniform vec2 pixelSize;
uniform int doUpdate;

float alive(vec2 uv) {
  return step(0.5, texture2D(stateTex, uv).r);
}

void main()
{
  if (doUpdate == 0) {
    fragColor = texture2D(stateTex, outTexCoord);
    return;
  }

  vec2 uv = outTexCoord;
  vec2 px = pixelSize;

  vec2 o[8];
  o[0] = vec2(-1.0, -1.0);
  o[1] = vec2( 0.0, -1.0);
  o[2] = vec2( 1.0, -1.0);
  o[3] = vec2(-1.0,  0.0);
  o[4] = vec2( 1.0,  0.0);
  o[5] = vec2(-1.0,  1.0);
  o[6] = vec2( 0.0,  1.0);
  o[7] = vec2( 1.0,  1.0);

  float c = alive(uv);
  float n = 0.0;
  for (int i = 0; i < 8; ++i) {
    n += alive(uv + o[i] * px);
  }

  // Conway rule
  float born    = step(2.5, n) * step(n, 3.5); // 3
  float survive = step(1.5, n) * step(n, 3.5); // 2 or 3
  float next    = mix(born, survive, c);       // c=0: born, c=1: survive

  fragColor = vec4(next, next, next, 1.0);
}
```]

Scene01 の実装をそのまま流用しつつ、中身のフラグメントだけをライフゲーム用に差し替えている。
`stateTex`（現在の盤面）を読み、`pixelSize=(1/W,1/H)` を使い上下左右＋斜めの 8 近傍を UV で 1 ピクセルずつずらしてサンプルを取るような処理になっている。
サンプルした R チャンネルを `step(0.5, …)` で `0/1` に丸めて総和 `n` を作り、現在セル `c` と合わせて「誕生 3、生存 2 or 3」を `step` のしきい値と `mix` でそのまま式に落とし込んでいる。

出力は次の世代なら `(1,1,1,1)`、死なら `(0,0,0,1)`。
表示だけのときは単純に `texture2D(stateTex, outTexCoord)` をそのまま返すようにしている。
そのため同じ frag で更新と表示を `doUpdate` という `int` の `uniform` で切り替えている。
調べてみると、どうやら frag ファイルを 2 つ作って別に実装できるようであるが、ゴニョゴニョしていたらうまく動かなかったため、このような実装にしている。

更新は、前の状態は必要であるので前のフレームと今のフレームの 2 つの状態を持って、swap している。

実行結果は以下の通りである。
アニメーションしている様子がわかるように複数枚載せている。

#stack(
  dir: ltr,
  spacing: 1em,
  figure(
    image("scene06_0.png", width: 48%),
    caption: [実行結果]
  ),
  figure(
    image("scene06_1.png", width: 48%),
    caption: [実行結果]
  )
)
