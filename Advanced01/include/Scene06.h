#pragma once

#include "AbstractScene.h"
#include "imgui.h"
#include <string>

class Scene06 : public AbstractScene {
public:
  static void Init();
  static void ReloadShaders();
  static void Draw();
  static void Cursor(GLFWwindow *window, double xpos, double ypos) {}
  static void Mouse(GLFWwindow *window, int button, int action, int mods) {}
  static void Resize(GLFWwindow *window, int w, int h);
  static void ImGui();
  static void Destroy();

private:
  static GLSLProgramObject *s_pShader;
  static std::string s_VertexShaderFilename, s_FragmentShaderFilename;

  static GLuint s_VBO, s_VAO;

  static GLuint s_StateTex[2], s_FBO[2];
  static int s_Ping;
  static int s_GridW, s_GridH;
  static bool s_Running;

  static void CreateStateResources(int w, int h);
  static void DestroyStateResources();
  static void UpdateOnce();
  static void BlitToScreen();
};
