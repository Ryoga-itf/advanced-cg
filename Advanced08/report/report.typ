#import "/common/template.typ": *
#import "@preview/tenv:0.1.2": parse_dotenv
#import "@preview/codelst:2.0.2": sourcecode, sourcefile

#let env = parse_dotenv(read("/.env"))

#show: project.with(
  week: "第8回 課題",
  authors: (
    (name: env.STUDENT_NAME, email: "学籍番号：" + env.STUDENT_ID, affiliation: "所属：情報科学類"),
  ),
  date: "2025 年 12 月 18 日",
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

なお、私の思想として C++ のコードフォーマット設定は以下のようにして実装を行った。

#sourcecode[```
BasedOnStyle: LLVM
IndentWidth: 4
TabWidth: 4
ColumnLimit: 120
```]

== 課題 A

修正した `advection` 関数のコードは以下の通り。

#sourcecode[```cpp
void WaveSWE::advection(float *d_new, float *d, float *u_new, float *v_new, float *u, float *v, float dt) {
    float dx = m_dx;
    float dy = m_dy;

    // ----課題ここから----
    const float max_x = (m_nx - 1) * dx;
    const float max_y = (m_ny - 1) * dy;

    // バイリニア補間
    static auto sampleBilinear = [&](const float *f, int i0, int j0, float s, float t) -> float {
        const float f00 = f[IDX(i0, j0)];
        const float f10 = f[IDX(i0 + 1, j0)];
        const float f01 = f[IDX(i0, j0 + 1)];
        const float f11 = f[IDX(i0 + 1, j0 + 1)];
        const float f0 = glm::mix(f00, f10, s);
        const float f1 = glm::mix(f01, f11, s);
        return glm::mix(f0, f1, t);
    };

    for (int j = 1; j < m_ny - 1; ++j) {
        for (int i = 1; i < m_nx - 1; ++i) {
            // current grid cell
            const float x = i * dx;
            const float y = j * dy;

            // バックトレース
            const float x0 = glm::clamp(x - u[IDX(i, j)] * dt, 0.0f, max_x);
            const float y0 = glm::clamp(y - v[IDX(i, j)] * dt, 0.0f, max_y);

            // 出発点の index
            const int i0 = glm::clamp(static_cast<int>(floor(x0 / dx)), 0, m_nx - 2);
            const int j0 = glm::clamp(static_cast<int>(floor(y0 / dy)), 0, m_ny - 2);

            const float s = (x0 - i0 * dx) / dx;
            const float t = (y0 - j0 * dy) / dy;

            // update suru
            d_new[IDX(i, j)] = sampleBilinear(d, i0, j0, s, t);
            u_new[IDX(i, j)] = sampleBilinear(u, i0, j0, s, t);
            v_new[IDX(i, j)] = sampleBilinear(v, i0, j0, s, t);
        }
    }

    bnd(d_new);
    bnd(u_new, v_new);

    // ----課題ここまで----
}
```]

また、修正した `pressure` 関数のコードは以下の通り。

#sourcecode[```cpp
void WaveSWE::pressure(float *d_new, float *d, float *u_new, float *v_new, float *u, float *v, float dt) {
    float dx = m_dx;
    float dy = m_dy;
    float g = m_gravity;

    // ----課題ここから----

    const float inv2dx = 1.0f / (2.0f * dx);
    const float inv2dy = 1.0f / (2.0f * dy);

    // u & v
    for (int j = 1; j < m_ny - 1; ++j) {
        for (int i = 1; i < m_nx - 1; ++i) {
            const int idx = IDX(i, j);

            const float dh_dx = (m_h[IDX(i + 1, j)] - m_h[IDX(i - 1, j)]) * inv2dx;
            const float dh_dy = (m_h[IDX(i, j + 1)] - m_h[IDX(i, j - 1)]) * inv2dy;

            u_new[idx] -= g * dt * dh_dx;
            v_new[idx] -= g * dt * dh_dy;
        }
    }

    bnd(u_new, v_new);

    // update d
    for (int j = 1; j < m_ny - 1; ++j) {
        for (int i = 1; i < m_nx - 1; ++i) {
            const int idx = IDX(i, j);

            const float du_dx = (u_new[IDX(i + 1, j)] - u_new[IDX(i - 1, j)]) * inv2dx;
            const float dv_dy = (v_new[IDX(i, j + 1)] - v_new[IDX(i, j - 1)]) * inv2dy;
            const float div = du_dx + dv_dy;

            d_new[idx] = d[idx] - d[idx] * dt * div;
        }
    }

    bnd(d_new);

    // ----課題ここまで----
}
```]

また、実行結果は以下のようになった。
この図は `save screenshot` のボタンから保存したものである。

#stack(
  dir: ltr,
  spacing: 1em,
  figure(
    image("img_00001.png", width: 48%),
    caption: [課題A]
  ),
  figure(
    image("img_00002.png", width: 48%),
    caption: [課題A]
  ),
)

#stack(
  dir: ltr,
  spacing: 1em,
  figure(
    image("img_00003.png", width: 48%),
    caption: [課題A]
  ),
  figure(
    image("img_00004.png", width: 48%),
    caption: [課題A]
  ),
)

== 課題 B

スタガード格子を用いた速度定義位置の変更を行った。
