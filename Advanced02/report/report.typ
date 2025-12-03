#import "/common/template.typ": *
#import "@preview/tenv:0.1.2": parse_dotenv
#import "@preview/codelst:2.0.2": sourcecode, sourcefile

#let env = parse_dotenv(read("/.env"))

#show: project.with(
  week: "第2回 課題",
  authors: (
    (name: env.STUDENT_NAME, email: "学籍番号：" + env.STUDENT_ID, affiliation: "所属：情報科学類"),
  ),
  date: "2025 年 10 月 23 日",
)

#show math.equation: set text(font: ("New Computer Modern Math", "Noto Serif", "Noto Serif CJK JP"))
#show raw: set text(font: "Hack Nerd Font")

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

== (1) Phong・Blinn-Phong モデル

GLSL のソースコードは以下のようになった。

#sourcecode[```glsl
// phong.vert
#version 130

in vec4 vertexPosition;
in vec3 vertexNormal;

out vec3 vEyePos;
out vec3 vEyeNormal;

uniform mat4 projMatrix;
uniform mat4 modelViewMatrix;
uniform mat3 modelViewInverseTransposed;

void main()
{
  vec4 eyePos = modelViewMatrix * vertexPosition;
  vEyePos     = eyePos.xyz;
  vEyeNormal  = normalize(modelViewInverseTransposed * vertexNormal);

  gl_Position = projMatrix * eyePos;
}
```]

#sourcecode[```glsl
// phong.frag
#version 130

in vec3 vEyePos;
in vec3 vEyeNormal;

out vec4 fragColor;

uniform vec3 eLightDir;
uniform vec3 lightColor;
uniform float shininess;
uniform vec3 diffuseCoeff;
uniform vec3 ambient;

void main()
{
  vec3 N = normalize(vEyeNormal);
  vec3 V = normalize(-vEyePos);
  vec3 L = normalize(eLightDir);

  // 拡散
  float NdotL = max(dot(N, L), 0.0);
  vec3 diff  = diffuseCoeff * lightColor * NdotL;

  // 鏡面
  vec3 R = reflect(-L, N);
  vec3 spec = lightColor * pow(max(dot(R, V), 0.0), max(shininess, 0.0));

  vec3 color = (ambient * lightColor) + diff + spec;
  fragColor = vec4(color, 1.0);
}
```]

#sourcecode[```glsl
// blinn_phong.frag
#version 130

in vec3 vEyePos;
in vec3 vEyeNormal;

out vec4 fragColor;

uniform vec3 eLightDir;
uniform vec3 lightColor;
uniform float shininess;
uniform vec3 diffuseCoeff;
uniform vec3 ambient;

void main()
{
  vec3 N = normalize(vEyeNormal);
  vec3 V = normalize(-vEyePos);
  vec3 L = normalize(eLightDir);

  // 拡散
  float NdotL = max(dot(N, L), 0.0);
  vec3  diff  = diffuseCoeff * lightColor * NdotL;

  // 鏡面
  vec3  H = normalize(L + V);
  vec3 spec = lightColor * pow(max(dot(N, H), 0.0), max(shininess, 0.0));

  vec3 color = (ambient * lightColor) + diff + spec;
  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
```]

なお、`blinn_phong.vert` は `phong.vert` と同一であるため省略している。
また、`vEyePos` は「目空間での位置」を、`vEyeNormal` は「目空間での法線」を表している。


実行結果は以下の通りである。

#stack(
  dir: ltr,
  spacing: 1em,
  figure(
    image("scene01_0.png", width: 48%),
    caption: [課題1の実行結果 (Phong)]
  ),
  figure(
    image("scene01_1.png", width: 48%),
    caption: [課題1の実行結果 (Blinn-Phong)]
  )
)

== (2) 影の計算

GLSL のソースコードは以下のようになった。

#sourcecode[```glsl
// shadow_blinn_phong.vert
#version 130

in vec4 vertexPosition;
in vec3 vertexNormal;

out vec3 vEyePos;
out vec3 vEyeNormal;
out vec4 vShadowCoord;

uniform mat4 biasedShadowProjModelView;
uniform mat3 modelViewInverseTransposed;
uniform mat4 projMatrix;
uniform mat4 modelViewMatrix;

void main()
{
  vec4 eyePos = modelViewMatrix * vertexPosition;
  vEyePos = eyePos.xyz;
  vEyeNormal = normalize(modelViewInverseTransposed * vertexNormal);

  vShadowCoord = biasedShadowProjModelView * vertexPosition;

  gl_Position = projMatrix * eyePos;
}
```]

#sourcecode[```glsl
// shadow_blinn_phong.frag
#version 130

in vec3 vEyePos;
in vec3 vEyeNormal;
in vec4 vShadowCoord;

out vec4 fragColor;

uniform sampler2DShadow shadowTex;

uniform vec3 eLightDir;
uniform vec3 lightColor;
uniform float shininess;
uniform vec3 diffuseCoeff;
uniform vec3 ambient;

void main()
{
  vec3 N = normalize(vEyeNormal);
  vec3 V = normalize(-vEyePos);
  vec3 L = normalize(eLightDir);

  // Blinn-Phong
  float NdotL = max(dot(N, L), 0.0);
  vec3 diff = diffuseCoeff * lightColor * NdotL;

  vec3 H = normalize(L + V);
  vec3 spec = lightColor * ((NdotL > 0.0) ? pow(max(dot(N, H), 0.0), max(shininess, 0.0)) : 0.0);
  vec3 amb = ambient * lightColor;

  vec3 color = (amb + diff + spec) * textureProj(shadowTex, vShadowCoord);
  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
```]

#sourcecode[```glsl
// pcf_shadow_blinn_phong.vert
#version 130

in vec4 vertexPosition;
in vec3 vertexNormal;

out vec3 vEyePos;
out vec3 vEyeNormal;
out vec4 vShadowCoord;

uniform mat4 biasedShadowProjModelView;
uniform mat3 modelViewInverseTransposed;
uniform mat4 projMatrix;
uniform mat4 modelViewMatrix;

void main()
{
  vec4 eyePos = modelViewMatrix * vertexPosition;
  vEyePos = eyePos.xyz;
  vEyeNormal = normalize(modelViewInverseTransposed * vertexNormal);

  vShadowCoord = biasedShadowProjModelView * vertexPosition;

  gl_Position = projMatrix * eyePos;
}
```]

#sourcecode[```glsl
// pcf_shadow_blinn_phong.frag
#version 130

in vec3 vEyePos;
in vec3 vEyeNormal;
in vec4 vShadowCoord;

out vec4 fragColor;

uniform sampler2DShadow shadowTex;
uniform vec2 texMapScale;

uniform vec3 eLightDir;
uniform vec3 lightColor;
uniform float shininess;
uniform vec3 diffuseCoeff;
uniform vec3 ambient;

float offsetLookup(sampler2DShadow map, vec4 loc, vec2 offset)
{
	return textureProj(map, vec4(loc.xy + offset * texMapScale * loc.w, loc.z, loc.w));
}

float samplingLimit = 3.5;

void main()
{
  vec3 N = normalize(vEyeNormal);
  vec3 V = normalize(-vEyePos);
  vec3 L = normalize(eLightDir);

  // Blinn-Phong
  float NdotL = max(dot(N, L), 0.0);
  vec3 diff = diffuseCoeff * lightColor * NdotL;

  vec3 H = normalize(L + V);
  vec3 spec = lightColor * ((NdotL > 0.0) ? pow(max(dot(N, H), 0.0), max(shininess, 0.0)) : 0.0);
 	vec3 amb = ambient * lightColor;

	float sum = 0.0;
  for (float y = -samplingLimit; y <= samplingLimit; y += 1.0) {
    for (float x = -samplingLimit; x <= samplingLimit; x += 1.0) {
      sum += offsetLookup(shadowTex, vShadowCoord, vec2(x, y));
    }
  }

	vec3 color = (amb + diff + spec) * sum / 64.0;
  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
```]

`vShadowCoord` は射影込みの影テクスチャの座標である。

実行結果は以下の通りである。

#stack(
  dir: ltr,
  spacing: 1em,
  figure(
    image("scene02_0.png", width: 48%),
    caption: [課題2の実行結果]
  ),
  figure(
    image("scene02_1.png", width: 48%),
    caption: [課題2の実行結果]
  )
)

== (3) MRT (Multiple Render Target)

#sourcecode[```glsl
// mrt.vert
#version 130

in vec4 vertexPosition;
in vec3 vertexNormal;

out vec3 vEyePos;
out vec3 vEyeNormal;

uniform mat4 projMatrix;
uniform mat4 modelViewMatrix;

void main()
{
  vec4 eyePos = modelViewMatrix * vertexPosition;
  vEyePos = eyePos.xyz;
  vEyeNormal = normalize(mat3(modelViewMatrix) * vertexNormal);

  gl_Position = projMatrix * eyePos;
}
```]

#sourcecode[```glsl
// mrt.frag
#version 130

in vec3 vEyePos;
in vec3 vEyeNormal;

void main()
{
  gl_FragData[0] = vec4(vEyePos, 1.0); // 座標

  vec3 n = normalize(vEyeNormal);
  gl_FragData[1] = vec4(0.5 * n + 0.5, 1.0); // 法線

  float d = gl_FragCoord.z;
  gl_FragData[2] = vec4(d, d, d, 1.0); // デプス値
}
```]

C++ 側から `modelViewInverseTransposed` が与えられないため、法線変換はシェーダ側で計算している。

実行結果は以下の通りである。

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
