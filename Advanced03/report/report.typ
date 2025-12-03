#import "/common/template.typ": *
#import "@preview/tenv:0.1.2": parse_dotenv
#import "@preview/codelst:2.0.2": sourcecode, sourcefile

#let env = parse_dotenv(read("/.env"))

#show: project.with(
  week: "第3回 課題",
  authors: (
    (name: env.STUDENT_NAME, email: "学籍番号：" + env.STUDENT_ID, affiliation: "所属：情報科学類"),
  ),
  date: "2025 年 11 月 12 日",
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

== (1) Lambert BRDF

修正した C++ のソースコードは以下の通り。

#sourcecode[```cpp
  else if (matType == Material::Diffuse_Type) {
    const float pi = std::numbers::pi_v<float>;
    const vec3 normal = glm::normalize(record.m_Normal);
    const vec3 incomingDir = glm::normalize(ray.getUnitDir());

    vec3 xLocal, yLocal, zLocal;
    calcLocalCoordinateSystem(normal, incomingDir, xLocal, yLocal, zLocal);

    const float r1 = frand();
    const float r2 = frand();
    const float phi = 2.0f * pi * r1;
    const float cosTheta = std::sqrt(r2);
    const float sinTheta = std::sqrt(1.0f - r2);

    vec3 sampledDir =
        glm::normalize(std::cos(phi) * cosTheta * xLocal + sinTheta * yLocal +
                       std::sin(phi) * cosTheta * zLocal);
    if (glm::dot(sampledDir, normal) < 0.0f) {
      sampledDir = -sampledDir;
    }

    auto *diffuseMat = static_cast<DiffuseMaterial *>(record.m_pMaterial);
    const vec3 diffuseCoeff = diffuseMat->getDiffuseCoeff();

    const float cosAlpha = std::max(glm::dot(sampledDir, normal), 0.0f);

    const float probability = cosTheta / pi;
    if (recursionDepth >= s_MinRecursionDepth) {
      if (frand() >= probability) {
        return g_Scene.getBackgroundColor(ray);
      }
    }

    const vec3 incomingRadiance =
        traceRec(Ray(record.m_HitPos, sampledDir), recursionDepth + 1);

    const vec3 contribution = diffuseCoeff * incomingRadiance;
    return contribution;
  }
```]

なお、`std::numbers` を用いるために、ファイルの先頭に `#include <numbers>` を加えている。
また、この機能は C++20 より使えるため、Makefile を以下のように変更した。

#sourcecode[```cpp
TARGET=advanced03

$(TARGET): CheckGLError.o EnvironmentMap.o GLSLProgramObject.o GLSLShaderObject.o GeometricObject.o Material.o PathTracer.o Scene.o Sphere.o Texture.o Triangle.o TriangleMesh.o arcball_camera.o imgui.o imgui_demo.o imgui_draw.o imgui_impl_glfw.o imgui_impl_opengl2.o imgui_tables.o imgui_widgets.o main.o tinyfiledialogs.o
	g++ -o $(TARGET) CheckGLError.o EnvironmentMap.o GLSLProgramObject.o GLSLShaderObject.o GeometricObject.o Material.o PathTracer.o Scene.o Sphere.o Texture.o Triangle.o TriangleMesh.o arcball_camera.o imgui.o imgui_demo.o imgui_draw.o imgui_impl_glfw.o imgui_impl_opengl2.o imgui_tables.o imgui_widgets.o main.o tinyfiledialogs.o -lglfw -lGLEW -lGL -lIL -lILU -lILUT -fopenmp
.cpp.o:
	g++ -c $< -O3 -I../../include -std=c++20 -fopenmp
run: $(TARGET)
	./$(TARGET)
clean:
	rm -f *.o $(TARGET)
```]

== (2) Blinn-Phong BRDF

修正した C++ のソースコードは以下の通り。

#sourcecode[```cpp
  else if (matType == Material::Blinn_Phong_Type) {
    const vec3 kd =
        ((BlinnPhongMaterial *)record.m_pMaterial)->getDiffuseCoeff();
    const vec3 ks =
        ((BlinnPhongMaterial *)record.m_pMaterial)->getSpecularCoeff();
    const float n = ((BlinnPhongMaterial *)record.m_pMaterial)->getShininess();

    const float diffuseWeight = glm::length(kd);
    const float specularWeight = glm::length(ks);
    const float weightSum = diffuseWeight + specularWeight;

    const float pd = (weightSum > 0.0f) ? (diffuseWeight / weightSum) : 0.0f;
    const float ps = (weightSum > 0.0f) ? (specularWeight / weightSum) : 0.0f;

    const float r0 = frand();

    if (r0 < pd) {
      const vec3 normal = glm::normalize(record.m_Normal);
      const vec3 incomingDir = glm::normalize(ray.getUnitDir());

      vec3 xLocal, yLocal, zLocal;
      calcLocalCoordinateSystem(normal, incomingDir, xLocal, yLocal, zLocal);

      const float r1 = frand();
      const float r2 = frand();
      const float phi = 2.0f * std::numbers::pi_v<float> * r1;
      const float cosTheta = std::sqrt(r2);
      const float sinTheta = std::sqrt(1.0f - r2);

      vec3 sampledDir =
          glm::normalize(std::cos(phi) * cosTheta * xLocal + sinTheta * yLocal +
                         std::sin(phi) * cosTheta * zLocal);
      if (glm::dot(sampledDir, normal) < 0.0f) {
        sampledDir = -sampledDir;
      }

      const float cosAlpha = std::max(glm::dot(sampledDir, normal), 0.0f);

      const float probability = cosTheta / std::numbers::pi_v<float>;
      if (recursionDepth >= s_MinRecursionDepth) {
        if (frand() >= probability) {
          return g_Scene.getBackgroundColor(ray);
        }
      }

      const vec3 incomingRadiance =
          traceRec(Ray(record.m_HitPos, sampledDir), recursionDepth + 1);
      const vec3 contribution = kd * incomingRadiance;

      return contribution / std::max(pd, 1e-6f);
    } else if (r0 < pd + ps) {
      const vec3 normal = glm::normalize(record.m_Normal);
      const vec3 incomingDir = glm::normalize(ray.getUnitDir());

      vec3 xLocal, yLocal, zLocal;
      calcLocalCoordinateSystem(normal, incomingDir, xLocal, yLocal, zLocal);

      const float r1 = frand();
      const float r2 = frand();
      const float phi = 2.0f * std::numbers::pi_v<float> * r1;
      const float cosTheta = std::pow(r2, 1.0f / (n + 1.0f));
      const float sinTheta = std::sqrt(1.0f - cosTheta * cosTheta);

      vec3 sampledDir =
          glm::normalize(std::cos(phi) * cosTheta * xLocal + sinTheta * yLocal +
                         std::sin(phi) * cosTheta * zLocal);
      if (glm::dot(sampledDir, normal) < 0.0f) {
        sampledDir = -sampledDir;
      }

      const vec3 halfVec = glm::normalize(incomingDir + sampledDir);

      const float up = (n + 1.0f) * std::pow(cosTheta, n);
      const float down = 2.0f * std::numbers::pi_v<float> * 4.0f *
                         glm::dot(sampledDir, halfVec);
      const float probability = up / down;

      if (recursionDepth >= s_MinRecursionDepth) {
        if (frand() >= probability) {
          return g_Scene.getBackgroundColor(ray);
        }
      }

      const vec3 incomingRadiance =
          traceRec(Ray(record.m_HitPos, sampledDir), recursionDepth + 1);

      const vec3 contribution = ks * incomingRadiance * (n + 2.0f) /
                                (n + 1.0f) *
                                (4.0f * glm::dot(sampledDir, halfVec));

      return contribution / std::max(ps, 1e-6f);
    } else {
      return g_Scene.getBackgroundColor(ray);
    }
  }
```]

(1) 同様、`std::numbers` に関する変更を加えている。

また、これらの実行結果は以下のようになった。

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
