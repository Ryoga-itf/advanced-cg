#import "/common/template.typ": *
#import "@preview/tenv:0.1.2": parse_dotenv
#import "@preview/codelst:2.0.2": sourcecode, sourcefile

#let env = parse_dotenv(read("/.env"))

#show: project.with(
  week: "第6回 課題",
  authors: (
    (name: env.STUDENT_NAME, email: "学籍番号：" + env.STUDENT_ID, affiliation: "所属：情報科学類"),
  ),
  date: "2025 年 11 月 27 日",
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

修正した `projectStretchingConstraint` 関数のコードは以下の通り。

#sourcecode[```cpp
void ElasticPBD::projectStretchingConstraint(float ks)
{
	if(m_iNumEdge <= 1) return;

	for(int i = 0; i < m_iNumEdge; ++i){
		// 四面体を使うときの内部エッジかどうかの判定＆内部エッジを使うかどうかのフラグチェック
		if(m_vInEdge[i] && !m_bUseInEdge) continue;

		// エッジ情報の取得とエッジ両端の頂点番号および質量の取得(固定点の質量は大きくする)
		const rxEdge &e = m_poly.edges[i];
		int v1 = e.v[0];	// エッジ
		int v2 = e.v[1];
		float m1 = m_vFix[v1] ? 30.0f*m_vMass[v1] : m_vMass[v1];
		float m2 = m_vFix[v2] ? 30.0f*m_vMass[v2] : m_vMass[v2];
		if(m1 < glm::epsilon<float>() || m2 < glm::epsilon<float>()) continue;

		// 2頂点の位置ベクトル
		glm::vec3 p1 = m_vNewPos[v1];
		glm::vec3 p2 = m_vNewPos[v2];

		// 計算点間の元の長さ(制約条件)
		float d = m_vLengths[i];

		// TODO:重力等を考慮した後の2頂点座標(スライド中のp')はp1=m_vNewPos[v1],p2=m_vNewPos[v2]で得られるので，
		//      これらから制約を満たすような位置修正量dp1,dp2を求めて，m_vNewPos[v1],m_vNewPos[v2]に足し合わせる．
		//      ◎エッジの長さによってはゼロ割が発生することがある．エラーチェックを忘れずに！
		glm::vec3 dp1, dp2;

		// ----課題ここから----
		
		const auto dir = p1 - p2;
		const float length = glm::length(dir);

		if (length < glm::epsilon<float>()) {
			dp1 = dp2 = glm::vec3(0.0f);
			continue;
		}

		const float C = length - d; 
		const auto n = dir / length;

		const float w1 = 1.0f / m1; 
		const float w2 = 1.0f / m2;

		dp1 = -(w1 / (w1 + w2)) * C * n;
		dp2 = (w2 / (w1 + w2)) * C * n; 

		// ----課題ここまで----

		// 頂点位置を修正
		if(!m_vFix[v1]) m_vNewPos[v1] += ks*dp1;
		if(!m_vFix[v2]) m_vNewPos[v2] += ks*dp2;
	}
}
```]

また、実行結果は以下のようになった。

#stack(
  dir: ltr,
  spacing: 1em,
  figure(
    image("a1_0.png", width: 48%),
    caption: [課題A (1) の実行結果]
  ),
  figure(
    image("a1_1.png", width: 48%),
    caption: [課題A (1) の実行結果]
  )
)

== 課題 A (2)

修正した `projectBendingConstraint` 関数のコードは以下の通り。

#sourcecode[```cpp
void ElasticPBD::projectBendingConstraint(float ks)
{
	if(m_iNumTris <= 1 || m_iNumEdge <= 0 || m_vBends.empty()) return;

	for(int i = 0; i < m_iNumEdge; i++){
		// 2つのポリゴンに挟まれたエッジ情報の取得
		const rxEdge &e = m_poly.edges[i];
		if(e.f.size() < 2) continue;	// このエッジを含むポリゴン数が1なら処理をスキップ

		// 2つの三角形を構成する4頂点のインデックスを抽出
		set<int>::iterator itr = e.f.begin();
		const rxFace &f1 = m_poly.faces[*itr]; itr++;
		const rxFace &f2 = m_poly.faces[*itr];
		int v1 = e.v[0], v2 = e.v[1], v3, v4;
		for(int j = 0; j < 3; ++j){
			if(f2[j] != v1 && f2[j] != v2) v4 = f2[j];
			if(f1[j] != v1 && f1[j] != v2) v3 = f1[j];
		}
		float m1 = m_vFix[v1] ? 30.0f*m_vMass[v1] : m_vMass[v1];
		float m2 = m_vFix[v2] ? 30.0f*m_vMass[v2] : m_vMass[v2];
		float m3 = m_vFix[v3] ? 30.0f*m_vMass[v3] : m_vMass[v3];
		float m4 = m_vFix[v4] ? 30.0f*m_vMass[v4] : m_vMass[v4];
		if(m1 < glm::epsilon<float>() || m2 < glm::epsilon<float>() || m3 < glm::epsilon<float>() || m4 < glm::epsilon<float>()) continue;

		// 4頂点の位置ベクトル(p2-p4はp1に対する相対位置ベクトル) -> スライドp36の^(ハット)付きのp2-p4の方
		glm::vec3 p1 = m_vNewPos[v1];
		glm::vec3 p2 = m_vNewPos[v2]-p1;
		glm::vec3 p3 = m_vNewPos[v3]-p1;
		glm::vec3 p4 = m_vNewPos[v4]-p1;

		// 2面間の初期角度
		float phi0 = m_vBends[i];

		// TODO:エッジを挟んだ4頂点座標p1,p2,p3,p4からbending constraintを満たす位置修正量dp1～dp4を求め，
		//      m_vNewPos[v1]～m_vNewPos[v4]に足し合わせる．
		//		・↑で定義しているp1～p4で，p2～p4はp1に対する相対座標(スライドp36の^(ハット)付きのp2-p4の方)にしてあるので注意
		//		・三角形ポリゴン間の角度の初期値φ0はm_vBends[i]で得られる(↑で変数phi0に代入済み)
		//      ◎ベクトルの大きさで割るという式が多いが，メッシュの変形によってはゼロ割が発生することがある．エラーチェックを忘れずに！
		//		◎スライドp36のdを計算するときに，-1～1の範囲にあるかをちゃんとチェックして，範囲外ならクランプするように！
		//      - 授業スライドに合わせるためにp1～p4など配列を使わずに書いている．
		//		  配列を使って書き換えても構わないが添え字の違い(配列は0から始まる)に注意．
		glm::vec3 dp1(0.0f), dp2(0.0f), dp3(0.0f), dp4(0.0f);

		// ----課題ここから----

		auto n1 = glm::cross(p2, p3);
		auto n2 = glm::cross(p2, p4);

		const float length1 = glm::length(n1);
		const float length2 = glm::length(n2);

		if (length1 < glm::epsilon<float>() || length2 < glm::epsilon<float>()) {
			dp1 = dp2 = dp3 = dp4 = glm::vec3(0.0f);
			continue;
		}

		n1 /= length1;
		n2 /= length2;

		const float d = glm::clamp(glm::dot(n1, n2), -1.0f, 1.0f);
		const float s = glm::sqrt(glm::max(0.0f, 1.0f - d * d));
		const float C = std::acos(d) - phi0;
		
		const glm::vec3 q3 = (glm::cross(p2, n2) + glm::cross(n1, p2) * d) / length1;
		const glm::vec3 q4 = (glm::cross(p2, n1) + glm::cross(n2, p2) * d) / length2;
		const glm::vec3 q2 = -(glm::cross(p3, n2) + glm::cross(n1, p3) * d) / length1
		                   -(glm::cross(p4, n1) + glm::cross(n2, p4) * d) / length2;
		const glm::vec3 q1 = -q2 - q3 - q4;
		
		const float w1 = 1.0f / m1;
		const float w2 = 1.0f / m2;
		const float w3 = 1.0f / m3;
		const float w4 = 1.0f / m4;

		const float denom = (w1 + w2 + w3 + w4) * (glm::length2(q1) + glm::length2(q2) + glm::length2(q3) + glm::length2(q4));

		if (denom < glm::epsilon<float>()) {
			dp1 = dp2 = dp3 = dp4 = glm::vec3(0.0f);
			continue;
		}

		const float lambda = -4.0f * s * C / denom;
		dp1 = (w1 * lambda) * q1;
		dp2 = (w2 * lambda) * q2;
		dp3 = (w3 * lambda) * q3;
		dp4 = (w4 * lambda) * q4;

		// ----課題ここまで----

		// 頂点位置を移動
		if(!m_vFix[v1]) m_vNewPos[v1] += ks*dp1;
		if(!m_vFix[v2]) m_vNewPos[v2] += ks*dp2;
		if(!m_vFix[v3]) m_vNewPos[v3] += ks*dp3;
		if(!m_vFix[v4]) m_vNewPos[v4] += ks*dp4;
	}
}
```]

また、実行結果は以下のようになった。

#stack(
  dir: ltr,
  spacing: 1em,
  figure(
    image("a2_0.png", width: 48%),
    caption: [課題A (2) の実行結果]
  ),
  figure(
    image("a2_1.png", width: 48%),
    caption: [課題A (2) の実行結果]
  )
)

== 課題 A (3)

修正した `projectVolumeConstraint` 関数のコードは以下の通り。

#sourcecode[```cpp
void ElasticPBD::projectVolumeConstraint(float ks)
{
	if(m_iNumTets <= 1) return;

	for(int i = 0; i < m_iNumTets; i++){
		// 四面体情報(四面体を構成する4頂点インデックス)の取得
		int v1 = m_vTets[i][0], v2 = m_vTets[i][1], v3 = m_vTets[i][2], v4 = m_vTets[i][3];

		// 四面体の4頂点座標と質量の取り出し
		glm::vec3 p1 = m_vNewPos[v1];
		glm::vec3 p2 = m_vNewPos[v2];
		glm::vec3 p3 = m_vNewPos[v3];
		glm::vec3 p4 = m_vNewPos[v4];
		float m1 = m_vFix[v1] ? 30.0f*m_vMass[v1] : m_vMass[v1];
		float m2 = m_vFix[v2] ? 30.0f*m_vMass[v2] : m_vMass[v2];
		float m3 = m_vFix[v3] ? 30.0f*m_vMass[v3] : m_vMass[v3];
		float m4 = m_vFix[v4] ? 30.0f*m_vMass[v4] : m_vMass[v4];
		if(m1 < glm::epsilon<float>() || m2 < glm::epsilon<float>() || m3 < glm::epsilon<float>() || m4 < glm::epsilon<float>()) continue;

		// 四面体の元の体積
		float V0 = m_vVolumes[i];

		// TODO:四面体の4頂点座標p1,p2,p3,p4からvolume constraintを満たす位置修正量dp1～dp4を求め，
		//      m_vNewPos[v1]～m_vNewPos[v4]に足し合わせる．
		//      ◎ベクトルの大きさで割るという式が多いが，メッシュの変形によってはゼロ割が発生することがある．エラーチェックを忘れずに！
		//		- 四面体の体積はスライドに書いてある式を書くのでもよいし，
		//		  calVolume()という四面体の体積計算用関数も用意してあるのでこれを使っても良い
		//      - 授業スライドに合わせるためにp1～p4など配列を使わずに書いている．
		//		  配列を使って書き換えても構わないが添え字の違い(配列は0から始まる)に注意．
		glm::vec3 dp1(0.0f), dp2(0.0f), dp3(0.0f), dp4(0.0f);

		// ----課題ここから----

		const float V = calVolume(p1, p2, p3, p4);
		const float C = V - V0; 

		const auto q1 = glm::cross(p2 - p3, p4 - p3);
		const auto q2 = glm::cross(p3 - p1, p4 - p1);
		const auto q3 = glm::cross(p1 - p2, p4 - p2);
		const auto q4 = glm::cross(p2 - p1, p3 - p1);

		const float w1 = 1.0f / m1;
		const float w2 = 1.0f / m2;
		const float w3 = 1.0f / m3;
		const float w4 = 1.0f / m4;

		const float denom =
			(w1 + w2 + w3 + w4) *
			(glm::length2(q1) + glm::length2(q2) + glm::length2(q3) + glm::length2(q4));

		if (denom < glm::epsilon<float>()) {
			dp1 = dp2 = dp3 = dp4 = glm::vec3(0.0f);
			continue;
		}

		const float lambda = -C / denom;
		dp1 = (w1 * lambda) * q1;
		dp2 = (w2 * lambda) * q2;
		dp3 = (w3 * lambda) * q3;
		dp4 = (w4 * lambda) * q4;

		// ----課題ここまで----

		// 頂点位置を移動
		if(!m_vFix[v1]) m_vNewPos[v1] += ks*dp1;
		if(!m_vFix[v2]) m_vNewPos[v2] += ks*dp2;
		if(!m_vFix[v3]) m_vNewPos[v3] += ks*dp3;
		if(!m_vFix[v4]) m_vNewPos[v4] += ks*dp4;
	}
}
```]

また、実行結果は以下のようになった。

#stack(
  dir: ltr,
  spacing: 1em,
  figure(
    image("a3_0.png", width: 48%),
    caption: [課題A (3) の実行結果]
  ),
  figure(
    image("a3_1.png", width: 48%),
    caption: [課題A (3) の実行結果]
  )
)
