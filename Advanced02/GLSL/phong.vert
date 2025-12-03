#version 130

in vec4 vertexPosition;
in vec3 vertexNormal;

out vec3 vEyePos;
out vec3 vEyeNormal;

uniform mat4 projMatrix;
uniform mat4 modelViewMatrix;
uniform mat3 modelViewInverseTransposed;

void main()
{
  vec4 eyePos = modelViewMatrix * vertexPosition;
  vEyePos     = eyePos.xyz;
  vEyeNormal  = normalize(modelViewInverseTransposed * vertexNormal);

  gl_Position = projMatrix * eyePos;
}
