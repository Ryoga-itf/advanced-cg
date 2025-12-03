#import "/common/template.typ": *
#import "@preview/tenv:0.1.2": parse_dotenv
#import "@preview/codelst:2.0.2": sourcecode, sourcefile

#let env = parse_dotenv(read("/.env"))

#show: project.with(
  week: "第7回 課題",
  authors: (
    (name: env.STUDENT_NAME, email: "学籍番号：" + env.STUDENT_ID, affiliation: "所属：情報科学類"),
  ),
  date: "2025 年 12 月 4 日",
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

== 課題 A (1) - LBS

修正した `pskinningLBS` 関数のコードは以下の通り。
なお、「課題ここから」の前の部分もリファクタリングのために書き換えている。
`const` と参照を活用することで無駄コピーを減らしている。

#sourcecode[```cpp
int CharacterAnimation::skinningLBS(vector<glm::vec3> &vrts, const vector<map<int, double>> &weights) {
    // 頂点毎に変換行列を重みをかけながら適用
    const int nv = static_cast<int>(vrts.size());
    for (int i = 0; i < nv; ++i) {
        const auto &vertex_weights = weights[i];

        glm::vec4 v{vrts[i], 1.0f};
        glm::vec4 v_new = v;

        if (vertex_weights.empty()) {
            vrts[i] = glm::vec3(v);
            continue;
        }

        glm::mat4 blended(0.0f);

        for (const auto &entry : vertex_weights) {
            const int j = entry.first;
            const float wij = static_cast<float>(entry.second);
            const glm::mat4 &Bj = m_joints[j].B;
            const glm::mat4 &Wj = m_joints[j].W;

            // Mj = Wj * Bj^{-1}
            const glm::mat4 Mj = Wj * glm::inverse(Bj);

            blended += wij * Mj;
        }

        // v'_i = blended * v_i
        v_new = blended * v;

        vrts[i] = glm::vec3{v_new};
    }

    return 1;
}
```]

また、実行結果は以下のようになった。

#stack(
  dir: ltr,
  spacing: 1em,
  figure(
    image("a1_0.png", width: 48%),
    caption: [課題A (1) の実行結果 (arm)]
  ),
  figure(
    image("a1_1.png", width: 48%),
    caption: [課題A (1) の実行結果 (arm (twist))]
  ),
)

#stack(
  dir: ltr,
  spacing: 1em,
  figure(
    image("a1_2.png", width: 48%),
    caption: [課題A (1) の実行結果 (walking)]
  )
)

== 課題 A (2) - DQS

修正した `skinningDQS` 関数のコードは以下の通り。
なお、「課題ここから」の前の部分もリファクタリングのために書き換えている。

#sourcecode[```cpp
int CharacterAnimation::skinningDQS(vector<glm::vec3> &vrts, const vector<map<int, double>> &weights) {
    // 頂点毎に変換DQを重みをかけながら適用
    const int nv = static_cast<int>(vrts.size());

    for (int i = 0; i < nv; ++i) {
        const auto &vertexWeights = weights[i];

        if (vertexWeights.empty()) {
            continue;
        }

        const glm::vec3 v = vrts[i];

        DualQuaternion dqBlend;
        dqBlend.m_real = glm::quat{0.0f, 0.0f, 0.0f, 0.0f};
        dqBlend.m_dual = glm::quat{0.0f, 0.0f, 0.0f, 0.0f};

        for (const auto &entry : vertexWeights) {
            const int j = entry.first;
            const float wij = static_cast<float>(entry.second);

            const glm::mat4 &Wj = m_joints[j].W; // current pose
            const glm::mat4 &Bj = m_joints[j].B; // bind pose

            const glm::mat3 RWj = glm::mat3{Wj};
            const glm::quat qWj = glm::quat_cast(RWj);
            const glm::vec3 tWj = glm::vec3{Wj[3]};

            const glm::mat3 RBj = glm::mat3{Bj};
            const glm::quat qBj = glm::quat_cast(RBj);
            const glm::vec3 tBj = glm::vec3{Bj[3]};

            // Dual Quaternion
            const DualQuaternion dqCurrent(qWj, tWj);
            const DualQuaternion dqBind(qBj, tBj);

            // DQ: Wj * Bj^{-1}
            const DualQuaternion dqSkin = dqCurrent * dqBind.conjugate();

            dqBlend += wij * dqSkin;
        }

        dqBlend.normalize();

        const glm::quat &qr = dqBlend.m_real;
        const glm::quat &qd = dqBlend.m_dual;

        // t = 2 * (qd * qr^*)
        const glm::quat qrConj = glm::conjugate(qr);
        const glm::quat tQuat = qd * qrConj;
        const glm::vec3 t = 2.0f * glm::vec3{tQuat.x, tQuat.y, tQuat.z};

        const glm::vec3 vRot = glm::rotate(qr, v);

        vrts[i] = vRot + t;
    }

    return 1;
}
```]

また、実行結果は以下のようになった。

#stack(
  dir: ltr,
  spacing: 1em,
  figure(
    image("a2_0.png", width: 48%),
    caption: [課題A (2) の実行結果 (arm)]
  ),
  figure(
    image("a2_1.png", width: 48%),
    caption: [課題A (2) の実行結果 (arm (twist))]
  ),
)

#stack(
  dir: ltr,
  spacing: 1em,
  figure(
    image("a2_2.png", width: 48%),
    caption: [課題A (2) の実行結果 (walking)]
  )
)
