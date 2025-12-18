// SWEを使った波のシミュレーション

//-----------------------------------------------------------------------------
// インクルードファイル
//-----------------------------------------------------------------------------
#include "wave_B.hpp"

//-----------------------------------------------------------------------------
// 課題用関数
//-----------------------------------------------------------------------------
/*!
 * SWEによるハイトフィールドの更新
 *  - 移流項のセミラグランジュ法による計算
 *  - *_newの方が更新後の値で出力値となる
 * @param[out] d_new 更新後の水深(デプス)値を格納する配列
 * @param[in] d 更新前の水深(デプス)値を格納した配列
 * @param[out] u_new,v_new 更新後の速度場を格納する配列
 * @param[in] u,v 更新前の速度場を格納した配列
 * @param[in] dt 時間ステップ幅
 */
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

/*!
 * SWEによるハイトフィールドの更新
 *  - 圧力項の計算
 *  - *_newの方が更新後の値で出力値となる
 * @param[out] d_new 更新後の水深(デプス)値を格納する配列
 * @param[in] d 更新前の水深(デプス)値を格納した配列
 * @param[out] u_new,v_new 更新後の速度場を格納する配列
 * @param[in] u,v 更新前の速度場を格納した配列
 * @param[in] dt 時間ステップ幅
 */
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

/*!
 * ハイトフィールドの更新
 * @param[in] step 現在の計算ステップ数
 * @param[in] dt 時間ステップ幅
 */
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

//-----------------------------------------------------------------------------
// WaveSWEクラスの実装
//-----------------------------------------------------------------------------
/*!
 * コンストラクタ
 */
WaveSWE::WaveSWE() {
    // 重力
    m_gravity = 9.81;
    m_surf = false;
    m_gs = false;
    m_nu = 1.0e-3;
}

/*!
 * デストラクタ
 */
WaveSWE::~WaveSWE() {}

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

/*!
 * OpenGLによるハイトフィールドメッシュの描画
 * @param[in] drw 描画フラグ
 */
void WaveSWE::Draw(int draw) {
    if (draw & 0x02) {
        // エッジ描画における"stitching"をなくすためのオフセットの設定
        glEnable(GL_POLYGON_OFFSET_FILL);
        glPolygonOffset(1.0, 1.0);
    }

    if (draw & 0x04) {
        glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
        glEnable(GL_LIGHTING);

        glColorMaterial(GL_FRONT_AND_BACK, GL_AMBIENT_AND_DIFFUSE);
        glEnable(GL_COLOR_MATERIAL);

        // 水面をポリゴンで描画
        glColor3d(0.2, 0.2, 0.7);
        for (const rxFace &face : m_mesh.faces) {
            glBegin(GL_POLYGON);
            for (int idx : face.vert_idx) {
                glNormal3fv(glm::value_ptr(m_mesh.normals[idx]));
                glVertex3fv(glm::value_ptr(m_mesh.vertices[idx]));
            }
            glEnd();
        }
        // 水底をポリゴンで描画
        glColor3d(0.7, 0.4, 0.2);
        for (const rxFace &face : m_mesh_ground.faces) {
            glBegin(GL_POLYGON);
            for (int idx : face.vert_idx) {
                glNormal3fv(glm::value_ptr(m_mesh_ground.normals[idx]));
                glVertex3fv(glm::value_ptr(m_mesh_ground.vertices[idx]));
            }
            glEnd();
        }
    }

    // 頂点描画
    if (draw & 0x01) {
        glEnable(GL_POLYGON_OFFSET_FILL);
        glPolygonOffset(1.0, 1.0);

        glDisable(GL_LIGHTING);
        glPointSize(5.0);
        glColor3d(1.0, 0.3, 0.3);
        glBegin(GL_POINTS);
        for (const glm::vec3 &v : m_mesh.vertices) {
            glVertex3fv(glm::value_ptr(v));
        }
        glEnd();
    }

    // エッジ描画
    if (draw & 0x02) {
        glDisable(GL_LIGHTING);
        glColor3d(0.5, 0.5, 0.5);
        glLineWidth(1.0);
        for (const rxFace &face : m_mesh.faces) {
            glBegin(GL_LINE_LOOP);
            for (int idx : face.vert_idx) {
                glVertex3fv(glm::value_ptr(m_mesh.vertices[idx]));
            }
            glEnd();
        }
    }
}

/*!
 * n×nの頂点を持つメッシュ生成(x-z平面)
 * @param[in] c1,c2 2端点座標

 */
void WaveSWE::generateMesh(glm::vec3 c1, glm::vec3 c2, rxPolygons &poly) {
    if (!poly.vertices.empty()) {
        poly.vertices.clear();
        poly.faces.clear();
    }

    // 頂点座標生成
    float dx = (c2[0] - c1[0]) / static_cast<float>(m_nx - 1);
    float dz = (c2[2] - c1[2]) / static_cast<float>(m_ny - 1);
    poly.vertices.resize(m_nx * m_ny);
    for (int k = 0; k < m_ny; ++k) {
        for (int i = 0; i < m_nx; ++i) {
            glm::vec3 pos;
            pos[0] = c1[0] + i * dx;
            pos[1] = c1[1];
            pos[2] = c1[2] + k * dz;
            poly.vertices[IDX(i, k)] = pos;
        }
    }

    m_min = c1 + glm::vec3(0.0f, -0.5f * dx * m_nx, 0.0f);
    m_max = c1 + glm::vec3((m_nx - 1) * dx, 0.5f * dx * m_nx, (m_ny - 1) * dz);

    m_dx = dx;
    m_dy = dz;

    // メッシュ作成
    for (int k = 0; k < m_ny - 1; ++k) {
        for (int i = 0; i < m_nx - 1; ++i) {
            rxFace face;
            face.resize(3);

            face[0] = IDX(i, k);
            face[1] = IDX(i + 1, k + 1);
            face[2] = IDX(i + 1, k);
            poly.faces.push_back(face);

            face[0] = IDX(i, k);
            face[1] = IDX(i, k + 1);
            face[2] = IDX(i + 1, k + 1);
            poly.faces.push_back(face);
        }
    }

    // 頂点法線の更新
    CalVertexNormals(poly.vertices, poly.vertices.size(), poly.faces, poly.faces.size(), poly.normals);
}

/*!
 * ハイトフィールドに従って描画用メッシュ頂点のy座標値を更新
 * @param[in] h ハイトフィールド(m_nx*m_ny)
 */
void WaveSWE::updateMesh(const vector<float> &h) {
    for (int k = 0; k < m_ny; ++k) {
        for (int i = 0; i < m_nx; ++i) {
            int idx = IDX(i, k);
            m_mesh.vertices[idx][1] = h[idx];
        }
    }

    // 頂点法線の更新
    CalVertexNormals(m_mesh.vertices, m_mesh.vertices.size(), m_mesh.faces, m_mesh.faces.size(), m_mesh.normals);
}

/*!
 * 頂点選択(レイと頂点(球)の交差判定)
 * @param[in]  ray_origin,ray_dir レイ(光線)の原点と方向ベクトル
 * @param[out] t 交差があったときの原点から交差点までの距離(媒介変数の値)
 * @param[in]  rad 球の半径(これを大きくすると頂点からマウスクリック位置が多少離れていても選択されるようになる)
 * @return 交差していればその頂点番号，交差していなければ-1を返す
 */
int WaveSWE::IntersectRay(const glm::vec3 &ray_origin, const glm::vec3 &ray_dir, float &t, float rad) {
    if (m_mesh.vertices.empty())
        return -1;
    int v = -1;
    float min_t = 1.0e6;
    float rad2 = rad * rad;
    float a = glm::length2(ray_dir);
    if (a < 1.0e-6)
        return -1;

    glm::vec3 origin(m_mesh.vertices[0][0], 0.0, m_mesh.vertices[0][2]);
    for (int j = 1; j < m_ny - 1; ++j) {
        for (int i = 1; i < m_nx - 1; ++i) {
            int idx = IDX(i, j);
            float x = i * m_dx, z = j * m_dy; // グリッド位置

            glm::vec3 cen = glm::vec3(x, m_h[IDX(i, j)], z) + origin;
            glm::vec3 s = ray_origin - cen;
            float b = 2.0f * glm::dot(s, ray_dir);
            float c = glm::length2(s) - rad2;

            float D = b * b - 4.0f * a * c;
            if (D < 0.0f)
                continue; // 交差なし

            float t0 = (-b - sqrt(D)) / (2.0 * a);
            float t1 = (-b + sqrt(D)) / (2.0 * a);
            if (t0 > 0.0 && t1 > 0.0 && t0 < min_t) { // 2交点がある場合
                v = idx;
                min_t = t0;
            } else if (t0 < 0.0 && t1 > 0.0 && t1 < min_t) { // 1交点のみの場合(光線の始点が球内部にある)
                v = idx;
                min_t = t1;
            }
        }
    }
    return v;
}

/*!
 * 高さ値の直接変更
 * @param[in] idx 頂点インデックス
 * @param[in] h 追加する高さ
 */
void WaveSWE::AddHeight(int idx, float dh) {
    if (idx < 0 || idx >= m_nx * m_ny)
        return;
    m_d[idx] += dh;
    m_dprev[idx] = m_d[idx];
    float b = m_ground((idx % m_nx) * m_dx, (idx / m_nx) * m_dy); // 水底の地形の高さ
    m_h[idx] = m_d[idx] + b;
    m_mesh.vertices[idx][1] = m_h[idx];
}
void WaveSWE::AddHeight(int i, int j, float h) { AddHeight(IDX(i, j), h); }
void WaveSWE::AddHeightArea(int idx, float dh) {
    if (idx < 0 || idx >= m_nx * m_ny)
        return;
    int s = 3;
    int i0 = idx % m_nx;
    int j0 = idx / m_nx;
    for (int j = 0; j < m_ny; ++j) {
        for (int i = 0; i < m_nx; ++i) {
            if (i >= i0 - s && i <= i0 + s && j >= j0 - s && j <= j0 + s) {
                int idx = IDX(i, j);
                float b = m_ground(i * m_dx, j * m_dy); // 水底の地形の高さ
                m_d[idx] = m_dprev[idx] = m_avg_h - b + dh;
            }
        }
    }
    updateHeight(&m_d[0]);
    updateMesh(m_h);
}

/*!
 * 平均高さの算出
 * @return 平均高さ
 */
double WaveSWE::calAvarageHeight(void) {
    int n = m_nx * m_ny;
    if (n <= 0)
        return 0.0f;

    float hsum = 0.0f;
    for (const float &h : m_h) {
        hsum += h;
    }
    return hsum / static_cast<float>(n);
}

/*!
 * ハイトフィールドの更新
 * @param[in] t 現在のシミュレーション時間(step*dt)
 * @param[out] h ハイトフィールド
 * @param[in] wave_height 設定する波の高さ
 */
void WaveSWE::makeSurf(float t, float *h, float wave_height) {
    float ht = wave_height * sin(4 * glm::pi<float>() * t);
    for (int i = 0; i < m_nx; ++i) {
        float b = m_ground(i * m_dx, 1 * m_dy); // 水底の地形の高さ
        h[IDX(i, 1)] = -b + ht;
    }
}

/*!
 * 周囲境界条件の処理(水深場)
 * @param[in] d 水深の値が格納された配列
 */
void WaveSWE::bnd(float *d) {
    for (int i = 0; i < m_nx; ++i) {
        d[IDX(i, 0)] = d[IDX(i, 1)];
        d[IDX(i, m_ny - 1)] = d[IDX(i, m_ny - 2)];
    }
    for (int j = 0; j < m_ny; ++j) {
        d[IDX(0, j)] = d[IDX(1, j)];
        d[IDX(m_nx - 1, j)] = d[IDX(m_nx - 2, j)];
    }
}
/*!
 * 周囲境界条件の処理(速度場)
 * @param[in] u,v 速度が格納された配列
 */
void WaveSWE::bnd(float *u, float *v) {
    // Staggered (MAC-like) boundary conditions
    // u: (nx+1) x ny, normal component on left/right walls -> 0
    for (int j = 0; j < m_ny; ++j) {
        u[IDXU(0, j)] = 0.0f;
        u[IDXU(m_nx, j)] = 0.0f;
        // top/bottom: copy (let waves pass in y direction unless you want a wall)
    }
    for (int iu = 0; iu <= m_nx; ++iu) {
        u[IDXU(iu, 0)] = u[IDXU(iu, 1)];
        u[IDXU(iu, m_ny - 1)] = u[IDXU(iu, m_ny - 2)];
    }

    // v: nx x (ny+1), normal component on front/back (y) walls -> 0
    for (int i = 0; i < m_nx; ++i) {
        v[IDXV(i, 0)] = 0.0f;
        v[IDXV(i, m_ny)] = 0.0f;
    }
    for (int jv = 0; jv <= m_ny; ++jv) {
        v[IDXV(0, jv)] = v[IDXV(1, jv)];
        v[IDXV(m_nx - 1, jv)] = v[IDXV(m_nx - 2, jv)];
    }
}

/*!
 * 水深と地形の高さから水面の高さを更新
 * @param[in] d 水深の値が格納された配列
 */
void WaveSWE::updateHeight(float *d) {
    // デプス値dから地形を含めた高さhを計算
    for (int j = 0; j < m_ny; ++j) {
        for (int i = 0; i < m_nx; ++i) {
            int idx = IDX(i, j);
            float b = m_ground(i * m_dx, j * m_dy); // 水底の地形の高さ
            m_h[idx] = d[idx] + b;
        }
    }

    // マウス入出力のために平均高さを求めておく
    //  - 境界条件によっては高さが変わってしまう
    m_avg_h = calAvarageHeight();
}

/*!
 * SWEによるハイトフィールドの更新
 *  - 速度の粘性拡散項の計算
 *  - *_newの方が更新後の値で出力値となる
 *  - この項は速度のみに適用する
 * @param[in] u,v 更新前の速度場を格納した配列
 * @param[out] u_new,v_new 更新後の速度場を格納する配列
 * @param[in] dt 時間ステップ幅
 */
void WaveSWE::viscosity(float *u_new, float *v_new, float *u, float *v, float dt) {
    const float dx = m_dx;
    const float dy = m_dy;
    const float nu = m_nu;

    // u: (nx+1) x ny
    for (int j = 0; j < m_ny; ++j) {
        for (int iu = 0; iu <= m_nx; ++iu) {
            const int idx = IDXU(iu, j);
            // boundaries: keep as-is (bnd will fix)
            if (iu == 0 || iu == m_nx || j == 0 || j == m_ny - 1) {
                u_new[idx] = u[idx];
                continue;
            }
            const float u_xx = (u[IDXU(iu + 1, j)] - 2.0f * u[idx] + u[IDXU(iu - 1, j)]) / (dx * dx);
            const float u_yy = (u[IDXU(iu, j + 1)] - 2.0f * u[idx] + u[IDXU(iu, j - 1)]) / (dy * dy);
            u_new[idx] = u[idx] + nu * dt * (u_xx + u_yy);
        }
    }

    // v: nx x (ny+1)
    for (int jv = 0; jv <= m_ny; ++jv) {
        for (int i = 0; i < m_nx; ++i) {
            const int idx = IDXV(i, jv);
            if (i == 0 || i == m_nx - 1 || jv == 0 || jv == m_ny) {
                v_new[idx] = v[idx];
                continue;
            }
            const float v_xx = (v[IDXV(i + 1, jv)] - 2.0f * v[idx] + v[IDXV(i - 1, jv)]) / (dx * dx);
            const float v_yy = (v[IDXV(i, jv + 1)] - 2.0f * v[idx] + v[IDXV(i, jv - 1)]) / (dy * dy);
            v_new[idx] = v[idx] + nu * dt * (v_xx + v_yy);
        }
    }

    bnd(u_new, v_new);
}
