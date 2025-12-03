#pragma once

#include "AbstractScene.hpp"
#include "imgui.h"
#include <string>
#include <vector>

class Scene02ImageSmoothing : public AbstractScene {
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

    static int s_TexWidth, s_TexHeight;
    static GLuint s_TexID;

    static int s_HalfKernelSize;

    static GLuint s_VBO, s_VAO;
};
