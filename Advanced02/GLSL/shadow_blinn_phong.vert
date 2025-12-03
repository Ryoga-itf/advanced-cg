#version 130

in vec4 vertexPosition;
in vec3 vertexNormal;

out vec3 vEyePos;
out vec3 vEyeNormal;
out vec4 vShadowCoord;

uniform mat4 biasedShadowProjModelView;
uniform mat3 modelViewInverseTransposed;
uniform mat4 projMatrix;
uniform mat4 modelViewMatrix;

void main()
{
  vec4 eyePos = modelViewMatrix * vertexPosition;
  vEyePos = eyePos.xyz;
  vEyeNormal = normalize(modelViewInverseTransposed * vertexNormal);

  vShadowCoord = biasedShadowProjModelView * vertexPosition;

  gl_Position = projMatrix * eyePos;
}
