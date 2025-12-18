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

まず配列のサイズに変更を加えた。それに伴って、 `Init` と `Update` を変更した。


#sourcecode[```cpp
/*!
 * 波の初期化
 *  - 水面がy=0になるように設定する
 * @param[in] n グリッド数
 * @param[in] scale 全体のスケール
 * @param[in] ground 水底の高さを与える関数ポインタ
 */
void WaveSWE::Init(int n, float scale, float (*ground)(float, float)) {
    // ハイトフィールドの解像度と全体の大きさ
    m_nx = n;
    m_ny = n;
    m_scale = scale;

    // 水底の高さを与える関数
    m_ground = ground;

    // 配列の初期化
    m_h.resize(m_nx * m_ny, 0.0);
    m_d.resize(m_nx * m_ny, 0.0);
    m_dprev.resize(m_nx * m_ny, 0.0);
    m_u.resize((m_nx + 1) * m_ny, 0.0);
    m_v.resize(m_nx * (m_ny + 1), 0.0);
    m_uprev.resize((m_nx + 1) * m_ny, 0.0);
    m_vprev.resize(m_nx * (m_ny + 1), 0.0);

    // メッシュ作成(グリッド幅m_dx,m_dyの計算もgenerateMeshでやっている)
    glm::vec3 c1(-m_scale / 2.0f, 0.0f, -m_scale / 2.0f);
    glm::vec3 c2(m_scale / 2.0f, 0.0f, m_scale / 2.0f);
    generateMesh(c1, c2, m_mesh);
    generateMesh(c1, c2, m_mesh_ground);

    //! 波の初期化
    for (int j = 0; j < m_ny; ++j) {
        for (int i = 0; i < m_nx; ++i) {
            int idx = IDX(i, j);
            float b = m_ground(i * m_dx, j * m_dy);
            m_d[idx] = m_dprev[idx] = -b; // 水面の高さ0なので水深は水底の高さに-1を掛けたものになる
            m_u[idx] = m_uprev[idx] = 0.0;
            m_v[idx] = m_vprev[idx] = 0.0;
        }
    }

    // staggered
    for (int j = 0; j < m_ny; ++j) {
        for (int iu = 0; iu <= m_nx; ++iu) {
            m_u[IDXU(iu, j)] = m_uprev[IDXU(iu, j)] = 0.0f;
        }
    }
    for (int jv = 0; jv <= m_ny; ++jv) {
        for (int i = 0; i < m_nx; ++i) {
            m_v[IDXV(i, jv)] = m_vprev[IDXV(i, jv)] = 0.0f;
        }
    }

    // 水面高さの更新
    updateHeight(&m_d[0]);

    // 水面ハイトフィールドメッシュの更新
    updateMesh(m_h);

    // 水底メッシュの更新(水底地形は変わらないと仮定しているので最初だけでよい)
    for (int j = 0; j < m_ny; ++j) {
        for (int i = 0; i < m_nx; ++i) {
            int idx = IDX(i, j);
            m_mesh_ground.vertices[idx][1] = m_ground(i * m_dx, j * m_dy);
        }
    }

    // 法線再計算
    CalVertexNormals(m_mesh);
    CalVertexNormals(m_mesh_ground);
}

int WaveSWE::Update(int step, float dt) {
    // 強制的な波の生成
    if (m_surf)
        makeSurf(step * dt, &m_dprev[0], 0.1);

    // SWEによるハイトフィールドの更新

    // 移流項(*_prev ⇒ *)
    advection(&m_d[0], &m_dprev[0], &m_u[0], &m_v[0], &m_uprev[0], &m_vprev[0], dt);

    // 粘性項(速度u,vは* ⇒ *_prev)
    viscosity(&m_uprev[0], &m_vprev[0], &m_u[0], &m_v[0], dt);

    // 水面高さ場hの更新(h=b+d)
    updateHeight(&m_d[0]);

    // 圧力項(水深dは* ⇒ *_prev，速度u,vは*_prev ⇒ *)
    pressure(&m_dprev[0], &m_d[0], &m_u[0], &m_v[0], &m_uprev[0], &m_vprev[0], dt);

    // 水面高さ場hの再更新と描画用メッシュの更新
    updateHeight(&m_dprev[0]);
    updateMesh(m_h);

    // 次のステップのためにu_prev,v_prevを更新しておく
    for (int i = 0; i < (m_nx + 1) * m_ny; ++i) {
        m_uprev[i] = m_u[i];
    }
    for (int i = 0; i < m_nx * (m_ny + 1); ++i) {
        m_vprev[i] = m_v[i];
    }

    return 1;
}
```
]

また、グリッドインデックスの計算において、スタガード格子のためのヘルパ関数を追加した。
具体的には、以下の文をヘッダーファイルの `IDX` の定義の下に追加した。

#sourcecode[```cpp
    inline int IDXU(int iu, int j) { return iu + j * (m_nx + 1); }
    inline int IDXV(int i, int jv) { return i + jv * (m_nx); }
    inline int USZ() const { return (m_nx + 1) * m_ny; }
    inline int VSZ() const { return m_nx * (m_ny + 1); }
```
]


修正した `advection` 関数のコードは以下の通り。

#sourcecode[```cpp
void WaveSWE::advection(float *d_new, float *d, float *u_new, float *v_new, float *u, float *v, float dt) {
    float dx = m_dx;
    float dy = m_dy;

    // ----課題ここから----
    // スタガード格子
    const float max_x = (m_nx - 1) * dx;
    const float max_y = (m_ny - 1) * dy;

    static auto sample_d = [&](const float *f, float x, float y) -> float {
        x = glm::clamp(x, 0.0f, max_x);
        y = glm::clamp(y, 0.0f, max_y);
        const int i0 = glm::clamp(static_cast<int>(std::floor(x / dx)), 0, m_nx - 2);
        const int j0 = glm::clamp(static_cast<int>(std::floor(y / dy)), 0, m_ny - 2);
        const float s = (x - i0 * dx) / dx;
        const float t = (y - j0 * dy) / dy;
        const float f00 = f[IDX(i0, j0)];
        const float f10 = f[IDX(i0 + 1, j0)];
        const float f01 = f[IDX(i0, j0 + 1)];
        const float f11 = f[IDX(i0 + 1, j0 + 1)];
        const float f0 = glm::mix(f00, f10, s);
        const float f1 = glm::mix(f01, f11, s);
        return glm::mix(f0, f1, t);
    };

    static auto sample_u = [&](const float *fu, float x, float y) -> float {
        // map to index space (iu,j)
        const float iu_f = x / dx + 0.5f;
        const float j_f = y / dy;
        const int iu0 = glm::clamp(static_cast<int>(std::floor(iu_f)), 0, m_nx - 1);
        const int j0 = glm::clamp(static_cast<int>(std::floor(j_f)), 0, m_nx - 2);
        const float s = iu_f - iu0;
        const float t = j_f - j0;
        const float f00 = fu[IDXU(iu0, j0)];
        const float f10 = fu[IDXU(iu0 + 1, j0)];
        const float f01 = fu[IDXU(iu0, j0 + 1)];
        const float f11 = fu[IDXU(iu0 + 1, j0 + 1)];
        return glm::mix(glm::mix(f00, f10, s), glm::mix(f01, f11, s), t);
    };

    static auto sample_v = [&](const float *fv, float x, float y) -> float {
        const float i_f = x / dx;
        const float jv_f = y / dy + 0.5f;
        const int i0 = glm::clamp(static_cast<int>(std::floor(i_f)), 0, m_nx - 2);
        const int jv0 = glm::clamp(static_cast<int>(std::floor(jv_f)), 0, m_ny - 1);
        const float s = i_f - i0;
        const float t = jv_f - jv0;
        const float f00 = fv[IDXV(i0, jv0)];
        const float f10 = fv[IDXV(i0 + 1, jv0)];
        const float f01 = fv[IDXV(i0, jv0 + 1)];
        const float f11 = fv[IDXV(i0 + 1, jv0 + 1)];
        return glm::mix(glm::mix(f00, f10, s), glm::mix(f01, f11, s), t);
    };

    // for d
    for (int j = 0; j < m_ny; ++j) {
        for (int i = 0; i < m_nx; ++i) {
            const float x = i * dx;
            const float y = j * dy;

            const float uu = 0.5f * (u[IDXU(i, j)] + u[IDXU(i + 1, j)]);
            const float vv = 0.5f * (v[IDXV(i, j)] + v[IDXV(i, j + 1)]);

            const float x0 = x - dt * uu;
            const float y0 = y - dt * vv;
            d_new[IDX(i, j)] = sample_d(d, x0, y0);
        }
    }

    // for u
    for (int j = 0; j < m_ny; ++j) {
        for (int iu = 0; iu <= m_nx; ++iu) {
            const float x = (iu - 0.5f) * dx;
            const float y = j * dy;

            const float uu = u[IDXU(iu, j)];
            const float vv = sample_v(v, x, y);
            const float x0 = x - dt * uu;
            const float y0 = y - dt * vv;
            u_new[IDXU(iu, j)] = sample_u(u, x0, y0);
        }
    }

    // for v
    for (int jv = 0; jv <= m_ny; ++jv) {
        for (int i = 0; i < m_nx; ++i) {
            const float x = i * dx;
            const float y = (jv - 0.5f) * dy;
            const float vv = v[IDXV(i, jv)];
            const float uu = sample_u(u, x, y);
            const float x0 = x - dt * uu;
            const float y0 = y - dt * vv;
            v_new[IDXV(i, jv)] = sample_v(v, x0, y0);
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
    // u(i+1/2, j): use h(i,j) - h(i-1,j)
    for (int j = 0; j < m_ny; ++j) {
        for (int iu = 1; iu < m_nx; ++iu) {
            const float hR = m_h[IDX(iu, j)];
            const float hL = m_h[IDX(iu - 1, j)];
            u_new[IDXU(iu, j)] = u[IDXU(iu, j)] - g * dt * (hR - hL) / dx;
        }
    }
    // wall
    for (int j = 0; j < m_ny; ++j) {
        u_new[IDXU(0, j)] = 0.0f;
        u_new[IDXU(m_nx, j)] = 0.0f;
    }

    // v(i, j+1/2): use h(i,j) - h(i,j-1)
    for (int jv = 1; jv < m_ny; ++jv) {
        for (int i = 0; i < m_nx; ++i) {
            const float hU = m_h[IDX(i, jv)];
            const float hD = m_h[IDX(i, jv - 1)];
            v_new[IDXV(i, jv)] = v[IDXV(i, jv)] - g * dt * (hU - hD) / dy;
        }
    }
    for (int i = 0; i < m_nx; ++i) {
        v_new[IDXV(i, 0)] = 0.0f;
        v_new[IDXV(i, m_ny)] = 0.0f;
    }

    bnd(u_new, v_new);

    // update
    for (int j = 0; j < m_ny; ++j) {
        for (int i = 0; i < m_nx; ++i) {
            const float div =
                (u_new[IDXU(i + 1, j)] - u_new[IDXU(i, j)]) / dx + (v_new[IDXV(i, j + 1)] - v_new[IDXV(i, j)]) / dy;

            const int idx = IDX(i, j);
            d_new[idx] = d[idx] - d[idx] * dt * div;
        }
    }

    bnd(d_new);

    // ----課題ここまで----
}
}
```]

以上の

- 配列確保・初期化（`Init` / コンストラクタ）
- 速度の更新（`pressure` または `velocity update` 部分）
- 水深 `d` の更新（`divergence` を使う部分）
- 境界条件（`u, v` 用）

を更新した。

動かすと、以下の図のようになった。

#stack(
  dir: ltr,
  spacing: 1em,
  figure(
    image("img_00001B.png", width: 48%),
    caption: [課題B]
  ),
  figure(
    image("img_00002B.png", width: 48%),
    caption: [課題B]
  ),
)
