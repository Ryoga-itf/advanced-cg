#import "/common/template.typ": *
#import "@preview/tenv:0.1.2": parse_dotenv
#import "@preview/codelst:2.0.2": sourcecode, sourcefile

#let env = parse_dotenv(read("/.env"))

#show: project.with(
  week: "第4回 課題",
  authors: (
    (name: env.STUDENT_NAME, email: "学籍番号：" + env.STUDENT_ID, affiliation: "所属：情報科学類"),
  ),
  date: "2025 年 11 月 13 日",
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

== 課題

修正した C++ のソースコードは以下の通り。
なお、書き換えが必要な場所以外は変更を加えていない。#footnote[元のコードにあるようなスタイルでコードフォーマッタをかけたためもしかしたら若干の変更があるかもしれない]

#sourcecode[```cpp
// LoopSubdivision.cpp
#include "LoopSubdivision.h"
#include <unordered_map>

using namespace std;
using namespace glm;

void LoopSubdivision::subdivide(PolygonMesh& mesh, int nSubdiv)
{
  if (mesh.getVertices().empty() || mesh.getFaceIndices().empty())
  {
    std::cerr << __FUNCTION__ << ": mesh not ready" << std::endl;
    return;
  }

  mesh.triangulate();

  HalfEdge::Mesh _mesh;
  _mesh.build(mesh);

  for (int iter = 0; iter < nSubdiv; ++iter)
    _mesh = apply(_mesh);

  _mesh.restore(mesh);
  mesh.calcVertexNormals();
}

HalfEdge::Mesh LoopSubdivision::apply(HalfEdge::Mesh& mesh)
{
  HalfEdge::Mesh newMesh;

  const int nOldVertices = (int)mesh.vertices.size();
  const int nOldFaces = (int)mesh.faces.size();
  const int nOldHalfEdges = (int)mesh.halfEdges.size();

  // Step 0: allocate memory for even (i.e., old) vertices

  newMesh.vertices.reserve(nOldFaces + nOldHalfEdges);

  for (int vi = 0; vi < nOldVertices; ++vi)
    newMesh.addVertex();

  // Step 1: create odd (i.e., new) vertices by splitting half edges

  unordered_map<long, HalfEdge::Vertex*> newEdgeMidpointDict;
  unordered_map<long, pair<HalfEdge::HalfEdge*, HalfEdge::HalfEdge*>> newHalfEdgeDict;

  for (int hi = 0; hi < nOldHalfEdges; ++hi)
  {
    auto oldHE = mesh.halfEdges[hi];

    vec3 startVertexPosition = mesh.vertices[oldHE->pStartVertex->id]->position;
    vec3 endVertexPosition = mesh.vertices[oldHE->getEndVertex()->id]->position;

    HalfEdge::Vertex* edgeMidpoint = nullptr;

    if (oldHE->pPair == nullptr)  // on boundary
    {
      edgeMidpoint = newMesh.addVertex();
      // calculate the position of edge midpoint
      edgeMidpoint->position = 0.5f * (startVertexPosition + endVertexPosition);
    }
    else
    {
      auto edgeMidpointIter = newEdgeMidpointDict.find(oldHE->pPair->id); // check if pair has been already registered

      if (edgeMidpointIter == newEdgeMidpointDict.end())
      {
        edgeMidpoint = newMesh.addVertex();
        // calculate the position of edge midpoint
        HalfEdge::HalfEdge* pairHE = oldHE->pPair;
        const vec3 upVertexPosition = mesh.vertices[oldHE->pNext->getEndVertex()->id]->position; 
        const vec3 downVertexPosition = mesh.vertices[pairHE->pNext->getEndVertex()->id]->position;
        edgeMidpoint->position = (3.0f / 8.0f) * (startVertexPosition + endVertexPosition) + (1.0f / 8.0f) * (upVertexPosition + downVertexPosition);
      }
      else
      {
        edgeMidpoint = edgeMidpointIter->second;
      }
    }

    newEdgeMidpointDict[oldHE->id] = edgeMidpoint; // used in Step 3

    auto formerHE = newMesh.addHalfEdge();
    auto latterHE = newMesh.addHalfEdge();

    auto evenStartVertex = newMesh.vertices[oldHE->pStartVertex->id];
    auto evenEndVertex = newMesh.vertices[oldHE->getEndVertex()->id];

    formerHE->pStartVertex = evenStartVertex;
    if (evenStartVertex->pHalfEdge == nullptr)
      evenStartVertex->pHalfEdge = formerHE;

    latterHE->pStartVertex = edgeMidpoint;
    if (edgeMidpoint->pHalfEdge == nullptr)
      edgeMidpoint->pHalfEdge = latterHE;

    newHalfEdgeDict[hi] = make_pair(formerHE, latterHE);

    // register pairs

    if (oldHE->pPair != nullptr)
    {
      auto iter = newHalfEdgeDict.find(oldHE->pPair->id);

      if (iter != newHalfEdgeDict.end())
      {
        HalfEdge::HalfEdge* pairFormerHE = iter->second.first;
        HalfEdge::HalfEdge* pairLatterHE = iter->second.second;

        HalfEdge::Helper::SetPair(pairFormerHE, latterHE);
        HalfEdge::Helper::SetPair(pairLatterHE, formerHE);
      }
    }
  }

  // Step 2: update even (i.e., old) vertices

  for (int vi = 0; vi < nOldVertices; ++vi)
  {
    auto newVertex = newMesh.vertices[vi];
    const auto oldVertex = mesh.vertices[vi];
    const auto oldVertexPosition = oldVertex->position;

    // calculate the new vertex position
    // c.f., HalfEdge::Vertex::countValence() in HalfEdgeDataStructure.cpp
    vec3 sum{ 0.0f };
    auto* const beginHE = oldVertex->pHalfEdge;
    auto* he = beginHE;
    int valence = 0; 
    float beta = 0.0f;

    if (oldVertex->onBoundary()) [[likely]]
    {
      while (he->pPair != nullptr) he = he->pPair->pNext;
      auto* const p1 = he->pNext->pStartVertex;

      he = he->pPrev;
      while (he->pPair != nullptr) he = he->pPair->pPrev;
      auto* const p2 = he->pStartVertex;

      sum = p1->position + p2->position; 
      valence = 2; 
      beta = 1.0f / 8.0f; 
    }
    else {
      valence = oldVertex->countValence();
      beta = (valence == 3) ? (3.0f / 16.0f) : (3.0f / (8.0f * valence)); 
      do {
        sum += he->pPair->pStartVertex->position;
        he = he->pPair->pNext;
      } while (he != beginHE);
    }

    newVertex->position = (1.0f - valence * beta) * oldVertexPosition + beta * sum;
  }

  // Step 3: create new faces

  for (int fi = 0; fi < nOldFaces; ++fi)
  {
    auto oldFace = mesh.faces[fi];

    // update the half-edge data structure within each old face
    // HINT: the number of new faces within each old face is always 4 in the case of Loop subdivision,
    //       so you can write down all the steps without using a "for" or "while" loop 
    const auto& he1 = oldFace->pHalfEdge;
    const auto& he2 = he1->pNext;
    const auto& he3 = he2->pNext;

    const auto& o1 = he1->pStartVertex;
    const auto& o2 = he2->pStartVertex;
    const auto& o3 = he3->pStartVertex;

    const auto& m1 = newEdgeMidpointDict[he1->id];
    const auto& m2 = newEdgeMidpointDict[he2->id];
    const auto& m3 = newEdgeMidpointDict[he3->id];

    const auto& pair1 = newHalfEdgeDict.find(he1->id)->second;
    const auto& pair2 = newHalfEdgeDict.find(he2->id)->second;
    const auto& pair3 = newHalfEdgeDict.find(he3->id)->second;

    const auto& [o1_m1, m1_o2] = pair1; 
    const auto& [o2_m2, m2_o3] = pair2;
    const auto& [o3_m3, m3_o1] = pair3;

    static constexpr auto tri = [](auto* a, auto* b, auto* c, auto* f) -> void
    {
      HalfEdge::Helper::SetPrevNext(a, b);
      HalfEdge::Helper::SetPrevNext(b, c);
      HalfEdge::Helper::SetPrevNext(c, a);
      a->pFace = b->pFace = c->pFace = f;
      f->pHalfEdge = a;
    };

    auto* f1 = newMesh.addFace();
    auto* m1_m3 = newMesh.addHalfEdge(); m1_m3->pStartVertex = m1;
    tri(o1_m1, m1_m3, m3_o1, f1);

    auto* f2 = newMesh.addFace();
    auto* m2_m1 = newMesh.addHalfEdge(); m2_m1->pStartVertex = m2;
    tri(o2_m2, m2_m1, m1_o2, f2);

    auto* f3 = newMesh.addFace();
    auto* m3_m2 = newMesh.addHalfEdge(); m3_m2->pStartVertex = m3;
    tri(o3_m3, m3_m2, m2_o3, f3);

    auto* f4 = newMesh.addFace();
    auto* m1_m2 = newMesh.addHalfEdge(); m1_m2->pStartVertex = m1;
    auto* m2_m3 = newMesh.addHalfEdge(); m2_m3->pStartVertex = m2;
    auto* m3_m1 = newMesh.addHalfEdge(); m3_m1->pStartVertex = m3;
    tri(m1_m2, m2_m3, m3_m1, f4);

    HalfEdge::Helper::SetPair(m1_m2, m2_m1);
    HalfEdge::Helper::SetPair(m2_m3, m3_m2);
    HalfEdge::Helper::SetPair(m3_m1, m1_m3);
  }

  cerr << __FUNCTION__ << ": check data consistency" << endl;
  newMesh.checkDataConsistency();

  return move(newMesh);
}
```]

#sourcecode[```cpp
// CatmullClarkSubdivision.cpp
#include "CatmullClarkSubdivision.h"
#include <unordered_map>

using namespace std;
using namespace glm;

void CatmullClarkSubdivision::subdivide(PolygonMesh& mesh, int nSubdiv)
{
  if (mesh.getVertices().empty() || mesh.getFaceIndices().empty())
  {
    std::cerr << __FUNCTION__ << ": mesh not ready" << std::endl;
    return;
  }

  HalfEdge::Mesh _mesh;
  _mesh.build(mesh);

  for (int iter = 0; iter < nSubdiv; ++iter)
    _mesh = apply(_mesh);

  _mesh.restore(mesh);
  mesh.calcVertexNormals();
}

HalfEdge::Mesh CatmullClarkSubdivision::apply(HalfEdge::Mesh& mesh)
{
  HalfEdge::Mesh newMesh;

  const int nOldVertices = (int)mesh.vertices.size();
  const int nOldFaces = (int)mesh.faces.size();
  const int nOldHalfEdges = (int)mesh.halfEdges.size();

  // Step 0: allocate memory for even (i.e., old) vertices

  newMesh.vertices.reserve(nOldFaces + nOldVertices + nOldHalfEdges);

  for (int vi = 0; vi < nOldVertices; ++vi)
    newMesh.addVertex();

  // Step 1: generate face centroids

  for (int fi = 0; fi < nOldFaces; ++fi)
  {
    auto oldFace = mesh.faces[fi];
    auto newFaceCentroid = newMesh.addVertex();
    // calculate the positions of face centroids
    newFaceCentroid->position = oldFace->calcCentroidPosition();
  }

  // Step 2: create odd (i.e., new) vertices by splitting half edges

  unordered_map<long, HalfEdge::Vertex*> newEdgeMidpointDict;
  unordered_map<long, pair<HalfEdge::HalfEdge*, HalfEdge::HalfEdge*>> newHalfEdgeDict;

  for (int hi = 0; hi < nOldHalfEdges; ++hi)
  {
    auto oldHE = mesh.halfEdges[hi];

    vec3 startVertexPosition = oldHE->getStartVertex()->position;
    vec3 endVertexPosition = oldHE->getEndVertex()->position;

    HalfEdge::Vertex* edgeMidpoint = nullptr;

    if (oldHE->pPair == nullptr)  // on boundary
    {
      edgeMidpoint = newMesh.addVertex();
      // calculate the position of edge midpoint
      edgeMidpoint->position = 0.5f * (startVertexPosition + endVertexPosition);
    }
    else
    {
      auto edgeMidpointIter = newEdgeMidpointDict.find(oldHE->pPair->id); // check if pair has been already registered

      if (edgeMidpointIter == newEdgeMidpointDict.end())
      {
        edgeMidpoint = newMesh.addVertex();
        // calculate the position of edge midpoint
        const auto oppositeStart = oldHE->pPair->pFace->calcCentroidPosition();
        const auto oppositeEnd = oldHE->pFace->calcCentroidPosition();
        edgeMidpoint->position = (startVertexPosition + endVertexPosition + oppositeStart + oppositeEnd) / 4.0f;
      }
      else
      {
        edgeMidpoint = edgeMidpointIter->second;
      }
    }

    newEdgeMidpointDict[oldHE->id] = edgeMidpoint;

    auto formerHE = newMesh.addHalfEdge();
    auto latterHE = newMesh.addHalfEdge();

    auto evenStartVertex = newMesh.vertices[oldHE->pStartVertex->id];
    auto evenEndVertex = newMesh.vertices[oldHE->pNext->pStartVertex->id];

    formerHE->pStartVertex = evenStartVertex;
    if (evenStartVertex->pHalfEdge == nullptr)
      evenStartVertex->pHalfEdge = formerHE;

    latterHE->pStartVertex = edgeMidpoint;
    if (edgeMidpoint->pHalfEdge == nullptr)
      edgeMidpoint->pHalfEdge = latterHE;

    newHalfEdgeDict[hi] = make_pair(formerHE, latterHE);

    // register pairs

    if (oldHE->pPair != nullptr)
    {
      auto iter = newHalfEdgeDict.find(oldHE->pPair->id);

      if (iter != newHalfEdgeDict.end())
      {
        HalfEdge::HalfEdge* pairFormerHE = iter->second.first;
        HalfEdge::HalfEdge* pairLatterHE = iter->second.second;

        HalfEdge::Helper::SetPair(pairFormerHE, latterHE);
        HalfEdge::Helper::SetPair(pairLatterHE, formerHE);
      }
    }
  }

  // Step 3: update even (i.e., old) vertex positions

  for (int vi = 0; vi < nOldVertices; ++vi)
  {
    auto newVertex = newMesh.vertices[vi];
    const auto oldVertex = mesh.vertices[vi];
    const auto oldVertexPosition = oldVertex->position;

    // calculate the new vertex position
    // c.f., HalfEdge::Vertex::countValence() in HalfEdgeDataStructure.cpp
    const int n = oldVertex->countValence();
    auto* he = oldVertex->pHalfEdge;

    if (oldVertex->onBoundary()) [[likely]]
    {
      while (he->pPair) he = he->pPair->pNext;
      auto* const p1 = he->pNext->pStartVertex;
      he = he->pPrev;
      while (he->pPair) he = he->pPair->pPrev;
      auto* const p2 = he->pStartVertex;
      newVertex->position = 0.75f * oldVertex->position + 0.125f * (p1->position + p2->position);
      continue;
    }

    vec3 F{ 0.0f };
    vec3 R{ 0.0f };

    do
    {
      if (he->pFace) F += he->pFace->calcCentroidPosition();
      he = he->pPair->pNext;
    } while (he != oldVertex->pHalfEdge && he->pPair != nullptr);

    F /= static_cast<float>(n);

    he = oldVertex->pHalfEdge;
    do
    {
      if (he->pPair) R += 0.5f * (he->getStartVertex()->position + he->getEndVertex()->position);
      he = he->pPair->pNext;
    } while (he != oldVertex->pHalfEdge && he->pPair);

    R /= static_cast<float>(n);

    const float nf = static_cast<float>(n);
    newVertex->position = (F + 2.0f * R + (nf - 3.0f) * oldVertexPosition) / nf;
  }

  // Step 4: set up new faces

  for (int fi = 0; fi < nOldFaces; ++fi)
  {
    auto oldFace = mesh.faces[fi];
    auto centroidVertex = newMesh.vertices[oldFace->id + nOldVertices];

    // update the half-edge data structure within each old face
    // HINT: use the following std::vector to store temporal data and process step by step
    //vector<HalfEdge::HalfEdge*> tmpToCentroidHalfEdges;
    //vector<HalfEdge::Face*> tmpNewFaces;
    
    auto* cur_he = oldFace->pHalfEdge;
    auto* prev_he = cur_he->pPrev;
    do
    {
      const auto& [_, m0_o1] = newHalfEdgeDict.find(prev_he->id)->second;
      const auto& [o1_m1, m1_o2] = newHalfEdgeDict.find(cur_he->id)->second;

      auto* newFace = newMesh.addFace();
      auto* m1_c = newMesh.addHalfEdge();
      auto* c_m1 = newMesh.addHalfEdge();
      newFace->pHalfEdge = o1_m1;

      HalfEdge::Helper::SetPrevNext(m0_o1, o1_m1);
      HalfEdge::Helper::SetPrevNext(o1_m1, m1_c);
      HalfEdge::Helper::SetPair(m1_c, c_m1);
      HalfEdge::Helper::SetPrevNext(c_m1, m1_o2);

      m0_o1->pFace = newFace;
      o1_m1->pFace = newFace;
      m1_c->pFace = newFace;

      m1_c->pStartVertex = newEdgeMidpointDict[cur_he->id];
      c_m1->pStartVertex = centroidVertex;

      cur_he = cur_he->pNext;
      prev_he = cur_he->pPrev;
    } while (cur_he != oldFace->pHalfEdge);

    do
    {
      const auto& [o1_m1, m1_o2] = newHalfEdgeDict.find(cur_he->id)->second;
      auto* c_m0 = o1_m1->pPrev->pPrev;
      c_m0->pFace = o1_m1->pFace;
      HalfEdge::Helper::SetPrevNext(o1_m1->pNext, c_m0);
      cur_he = cur_he->pNext;
    } while (cur_he != oldFace->pHalfEdge);

    const auto& [o1_m1, m1_o2] = newHalfEdgeDict.find(cur_he->id)->second;
    centroidVertex->pHalfEdge = o1_m1->pNext->pPair;
  }

  cerr << __FUNCTION__ << ": check data consistency" << endl;
  newMesh.checkDataConsistency();

  return move(newMesh);
}
```]

なお、構造化束縛 #footnote[https://en.cppreference.com/w/cpp/language/structured_binding.html] などといった機能を用いるために Makefile に変更を加えている。
Makefile は以下のようにした。

#sourcecode[```Makefile
TARGET=advanced04

$(TARGET): BlinnPhongRenderer.o CatmullClarkSubdivision.o CheckGLError.o EnvironmentMap.o GLSLProgramObject.o GLSLShaderObject.o HalfEdgeDataStructure.o LoopSubdivision.o PolygonMesh.o ReflectionLineRenderer.o arcball_camera.o imgui.o imgui_demo.o imgui_draw.o imgui_impl_glfw.o imgui_impl_opengl2.o imgui_tables.o imgui_widgets.o main.o tinyfiledialogs.o
	g++ -o $(TARGET) BlinnPhongRenderer.o CatmullClarkSubdivision.o CheckGLError.o EnvironmentMap.o GLSLProgramObject.o GLSLShaderObject.o HalfEdgeDataStructure.o LoopSubdivision.o PolygonMesh.o ReflectionLineRenderer.o arcball_camera.o imgui.o imgui_demo.o imgui_draw.o imgui_impl_glfw.o imgui_impl_opengl2.o imgui_tables.o imgui_widgets.o main.o tinyfiledialogs.o -lglfw -lGLEW -lGL -lIL -lILU -lILUT
.cpp.o:
	g++ -c $< -O3 -I../../include -std=c++20
run: $(TARGET)
	./$(TARGET)
clean:
	rm -f *.o $(TARGET)
```]

また、実行結果は以下のようになった。
なお、いずれも `Apply Subdivision` は 2 回適用した。

#stack(
  dir: ltr,
  spacing: 1em,
  figure(
    image("scene04_0.png", width: 48%),
    caption: [課題4の実行結果 (Loop)]
  ),
  figure(
    image("scene04_1.png", width: 48%),
    caption: [課題4の実行結果 (Catmull-Clark)]
  )
)
