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

修正した `projectStretchingConstraint` 関数のコードは以下の通り。
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

// #stack(
//   dir: ltr,
//   spacing: 1em,
//   figure(
//     image("a2_0.png", width: 48%),
//     caption: [課題A (1) の実行結果]
//   ),
//   figure(
//     image("a2_1.png", width: 48%),
//     caption: [課題A (1) の実行結果]
//   )
// )

== 課題 A (2) - DQS
