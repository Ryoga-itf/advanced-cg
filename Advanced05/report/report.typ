#import "/common/template.typ": *
#import "@preview/tenv:0.1.2": parse_dotenv
#import "@preview/codelst:2.0.2": sourcecode, sourcefile

#let env = parse_dotenv(read("/.env"))

#show: project.with(
  week: "第5回 課題",
  authors: (
    (name: env.STUDENT_NAME, email: "学籍番号：" + env.STUDENT_ID, affiliation: "所属：情報科学類"),
  ),
  date: "2025 年 11 月 20 日",
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

== 課題 A (1)

修正した `affineDeformation` 関数のコードは以下の通り。

#sourcecode[```cpp
glm::vec2 rxMeshDeform2D::affineDeformation(const glm::vec2 &v, const glm::vec2 &pc, const glm::vec2 &qc, const double alpha)
{
	constexpr float eps = std::numeric_limits<float>::epsilon();

	glm::mat2 m1{ 0.0f };
	glm::mat2 m2{ 0.0f };

	for (int k = 0; k < m_iNcp; ++k)
	{
		const int j = m_vCP[k]; 

		const auto dist2 = glm::length2(m_vP[j] - v);
		const auto w = (dist2 > eps) ? 1.0 / std::pow(dist2, alpha) : 0.0;

		const auto p = m_vP[j] - pc; 
		const auto q = m_vX[j] - qc;  

		m1 += w * glm::outerProduct(p, p);
		m2 += w * glm::outerProduct(p, q);
	}

	const auto det = glm::determinant(m1);

	const auto fa = (std::fabs(det) < eps ? v : (m2 * glm::inverse(m1)) * (v - pc) + qc);

	return fa;
}
```]


また、実行結果は以下のようになった。

#stack(
  dir: ltr,
  spacing: 1em,
  figure(
    image("a1_0.png", width: 48%),
    caption: [課題A (1) の実行結果 (grid)]
  ),
  figure(
    image("a1_1.png", width: 48%),
    caption: [課題A (1) の実行結果 (random)]
  )
)

== 課題 A (2)

修正した `similarityDeformation` 関数のコードは以下の通り。

#sourcecode[```cpp
glm::vec2 rxMeshDeform2D::similarityDeformation(const glm::vec2 &v, const glm::vec2 &pc, const glm::vec2 &qc, const double alpha)
{
	constexpr float eps = std::numeric_limits<float>::epsilon();

	float mu = 0.0;
	glm::vec2 vt{ 0.0 }; 

	// Loop control points
	for (int k = 0; k < m_iNcp; ++k) {
		const int j = m_vCP[k];

		const auto dist2 = glm::length2(m_vP[j] - v);
		const auto w = (dist2 > eps) ? 1.0 / std::pow(dist2, alpha) : 0.0;

		const auto p = m_vP[j] - pc;
		const auto q = m_vX[j] - qc;

		mu += w * glm::dot(p, p);

		const glm::mat2 t1{ p.x, p.y, p.y, -(p.x) };
		const glm::mat2 t2{ (v - pc).x, (v - pc).y, (v - pc).y, -((v - pc).x) };
		const glm::mat2 A{ w * t1 * t2 };

		vt += glm::transpose(A) * q;
	}

	const auto fsv = (mu < eps ? v : vt / mu + qc);

	return fsv;
}
```]

また、実行結果は以下のようになった。

#stack(
  dir: ltr,
  spacing: 1em,
  figure(
    image("a2_0.png", width: 48%),
    caption: [課題A (2) の実行結果 (grid)]
  ),
  figure(
    image("a2_1.png", width: 48%),
    caption: [課題A (2) の実行結果 (random)]
  )
)

== 課題 A (3)

修正した `rigidDeformation` 関数のコードは以下の通り。

#sourcecode[```cpp
glm::vec2 rxMeshDeform2D::rigidDeformation(const glm::vec2 &v, const glm::vec2 &pc, const glm::vec2 &qc, const double alpha)
{
	constexpr float eps = std::numeric_limits<float>::epsilon();

	float mu1 = 0.0;
	float mu2 = 0.0; 
	glm::vec2 vt{ 0.0f };

	for (int k = 0; k < m_iNcp; ++k) {
		const int j = m_vCP[k];

		const auto dist2 = glm::length2(m_vP[j] - v);
		const auto w = (dist2 > eps) ? 1.0 / std::pow(dist2, alpha) : 0.0;

		const auto p = m_vP[j] - pc;
		const auto q = m_vX[j] - qc;

		mu1 += w * glm::dot(q, p);
		mu2 += w * glm::dot(p, glm::vec2(-(p.y), p.x));

		const glm::mat2 t1{ p.x, p.y, p.y, -(p.x) };
		const glm::mat2 t2{ (v - pc).x, (v - pc).y, (v - pc).y, -((v - pc).x) };
		const glm::mat2 A{ w * t1 * t2 };

		vt += glm::transpose(A) * q;
	}

	const float mu = std::sqrt(std::pow(mu1, 2) + std::pow(mu2, 2));

	const auto frv = (mu < eps ? v : vt / mu + qc);

	return frv;
}
```]

また、実行結果は以下のようになった。

#stack(
  dir: ltr,
  spacing: 1em,
  figure(
    image("a3_0.png", width: 48%),
    caption: [課題A (3) の実行結果 (grid)]
  ),
  figure(
    image("a3_1.png", width: 48%),
    caption: [課題A (3) の実行結果 (random)]
  )
)
