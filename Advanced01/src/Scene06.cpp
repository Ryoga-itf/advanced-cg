#include "Scene06.h"
#include "PathFinder.h"
#include "glm/glm.hpp"
#include "glm/gtc/matrix_transform.hpp"
#include "glm/gtc/type_ptr.hpp"
#include <iostream>
#include <random>

using namespace std;

string Scene06::s_VertexShaderFilename = "scene06_lifegame.vert";
string Scene06::s_FragmentShaderFilename = "scene06_lifegame.frag";
GLSLProgramObject *Scene06::s_pShader = 0;

GLuint Scene06::s_VBO = 0;
GLuint Scene06::s_VAO = 0;

GLuint Scene06::s_StateTex[2] = {0, 0};
GLuint Scene06::s_FBO[2] = {0, 0};
int Scene06::s_Ping = 0;

int Scene06::s_GridW = 512;
int Scene06::s_GridH = 512;

bool Scene06::s_Running = true;

void Scene06::Init() {
  ReloadShaders();
  CreateStateResources(s_GridW, s_GridH);
}

void Scene06::ReloadShaders() {
  if (s_pShader)
    delete s_pShader;
  s_pShader = new GLSLProgramObject();

  PathFinder finder;
#ifdef __APPLE__
  finder.addSearchPath("GLSL_Mac");
  finder.addSearchPath("../GLSL_Mac");
  finder.addSearchPath("../../GLSL_Mac");
#else
  finder.addSearchPath("GLSL");
  finder.addSearchPath("../GLSL");
  finder.addSearchPath("../../GLSL");
#endif

  const GLuint vertexPositionLocation = 0;
  const GLuint inTexCoordLocation = 1;

  s_pShader->attachShaderSourceFile(finder.find(s_VertexShaderFilename).c_str(),
                                    GL_VERTEX_SHADER_ARB);
  s_pShader->attachShaderSourceFile(
      finder.find(s_FragmentShaderFilename).c_str(), GL_FRAGMENT_SHADER_ARB);
  s_pShader->setAttributeLocation("vertexPosition", vertexPositionLocation);
  s_pShader->setAttributeLocation("inTexCoord", inTexCoordLocation);
  s_pShader->link();

  if (!s_pShader->linkSucceeded()) {
    cerr << __FUNCTION__ << ": shader link failed" << endl;
    s_pShader->printProgramLog();
    return;
  }

  // build a screen-sized quad

  float quadVertices[] = {-1, -1, 1, -1, 1, 1, -1, -1, 1, 1, -1, 1};
  float quadTexCoords[] = {0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1};

  if (!s_VAO)
    glGenVertexArrays(1, &s_VAO);
  glBindVertexArray(s_VAO);

  if (!s_VBO)
    glGenBuffers(1, &s_VBO);
  glBindBuffer(GL_ARRAY_BUFFER, s_VBO);

  glBufferData(GL_ARRAY_BUFFER, sizeof(quadVertices) + sizeof(quadTexCoords),
               NULL, GL_STATIC_DRAW);
  glBufferSubData(GL_ARRAY_BUFFER, 0, sizeof(quadVertices), quadVertices);
  glBufferSubData(GL_ARRAY_BUFFER, sizeof(quadVertices), sizeof(quadTexCoords),
                  quadTexCoords);

  glEnableVertexAttribArray(vertexPositionLocation);
  glVertexAttribPointer(vertexPositionLocation, 2, GL_FLOAT, GL_FALSE, 0,
                        (const void *)0); // vertices

  glEnableVertexAttribArray(inTexCoordLocation);
  glVertexAttribPointer(
      inTexCoordLocation, 2, GL_FLOAT, GL_FALSE, 0,
      (const void *)sizeof(quadVertices)); // texture coordinates

  glBindBuffer(GL_ARRAY_BUFFER, 0);
  glBindVertexArray(0);
}

void Scene06::Draw() {
  // update
  if (s_Running) {
    UpdateOnce(); // ping -> pong
  }

  // display
  BlitToScreen();
}

void Scene06::Resize(GLFWwindow *window, int w, int h) {
  AbstractScene::Resize(window, w, h);
}

void Scene06::ImGui() {
  ImGui::Text("Scene06 Menu:");

  if (ImGui::Button("Reload Shaders")) {
    ReloadShaders();
  }
}

void Scene06::Destroy() {
  if (s_pShader)
    delete s_pShader;
  if (s_VAO)
    glDeleteVertexArrays(1, &s_VAO);
  if (s_VBO)
    glDeleteBuffers(1, &s_VBO);
  DestroyStateResources();
}

static GLuint CreateStateTexture(int w, int h, const void *data) {
  GLuint tex = 0;
  glGenTextures(1, &tex);
  glBindTexture(GL_TEXTURE_2D, tex);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE,
               data);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
  glBindTexture(GL_TEXTURE_2D, 0);
  return tex;
}

void Scene06::CreateStateResources(int w, int h) {
  DestroyStateResources();

  std::vector<unsigned char> img(w * h * 4);
  std::mt19937 rng(std::random_device{}());
  std::uniform_int_distribution<int> b01(0, 1);
  for (int i = 0; i < w * h; ++i) {
    unsigned char v = b01(rng) ? 255 : 0;
    img[i * 4 + 0] = v;
    img[i * 4 + 1] = v;
    img[i * 4 + 2] = v;
    img[i * 4 + 3] = 255;
  }

  s_StateTex[0] = CreateStateTexture(w, h, img.data());
  s_StateTex[1] = CreateStateTexture(w, h, img.data());

  glGenFramebuffers(2, s_FBO);
  for (int i = 0; i < 2; ++i) {
    glBindFramebuffer(GL_FRAMEBUFFER, s_FBO[i]);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D,
                           s_StateTex[i], 0);
  }
  glBindFramebuffer(GL_FRAMEBUFFER, 0);

  s_Ping = 0;
}

void Scene06::DestroyStateResources() {
  if (s_FBO[0] || s_FBO[1]) {
    glDeleteFramebuffers(2, s_FBO);
    s_FBO[0] = s_FBO[1] = 0;
  }
  if (s_StateTex[0] || s_StateTex[1]) {
    glDeleteTextures(2, s_StateTex);
    s_StateTex[0] = s_StateTex[1] = 0;
  }
}

void Scene06::UpdateOnce() {
  const int pong = 1 - s_Ping;

  // current viewport
  GLint prevVP[4];
  glGetIntegerv(GL_VIEWPORT, prevVP);

  glBindFramebuffer(GL_FRAMEBUFFER, s_FBO[pong]);
  glViewport(0, 0, s_GridW, s_GridH);

  glDisable(GL_DEPTH_TEST);
  glDisable(GL_CULL_FACE);
  glDisable(GL_BLEND);

  s_pShader->use();
  s_pShader->sendUniform1i("stateTex", 0);
  s_pShader->sendUniform2f("pixelSize", 1.0f / s_GridW, 1.0f / s_GridH);
  s_pShader->sendUniform1i("doUpdate", 1); // update

  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, s_StateTex[s_Ping]);

  glBindVertexArray(s_VAO);
  glDrawArrays(GL_TRIANGLES, 0, 6);
  glBindVertexArray(0);

  s_pShader->disable();

  glBindTexture(GL_TEXTURE_2D, 0);
  glBindFramebuffer(GL_FRAMEBUFFER, 0);

  // restore
  glViewport(prevVP[0], prevVP[1], prevVP[2], prevVP[3]);

  s_Ping = pong; // swap
}

void Scene06::BlitToScreen() {
  glBindFramebuffer(GL_FRAMEBUFFER, 0);

  glDisable(GL_DEPTH_TEST);
  glDisable(GL_CULL_FACE);
  glDisable(GL_BLEND);

  s_pShader->use();
  s_pShader->sendUniform1i("stateTex", 0);
  s_pShader->sendUniform2f("pixelSize", 1.0f / s_GridW, 1.0f / s_GridH);
  s_pShader->sendUniform1i("doUpdate", 0); // display

  glActiveTexture(GL_TEXTURE0);
  glBindTexture(GL_TEXTURE_2D, s_StateTex[s_Ping]);

  glBindVertexArray(s_VAO);
  glDrawArrays(GL_TRIANGLES, 0, 6);
  glBindVertexArray(0);

  s_pShader->disable();

  glBindTexture(GL_TEXTURE_2D, 0);
}
