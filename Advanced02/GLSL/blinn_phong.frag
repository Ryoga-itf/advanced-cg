#version 130

in vec3 vEyePos;
in vec3 vEyeNormal;

out vec4 fragColor;

uniform vec3 eLightDir;
uniform vec3 lightColor;
uniform float shininess;
uniform vec3 diffuseCoeff;
uniform vec3 ambient;

void main()
{
  vec3 N = normalize(vEyeNormal);
  vec3 V = normalize(-vEyePos);
  vec3 L = normalize(eLightDir);

  // 拡散
  float NdotL = max(dot(N, L), 0.0);
  vec3  diff  = diffuseCoeff * lightColor * NdotL;

  // 鏡面
  vec3  H = normalize(L + V);
  vec3 spec = lightColor * pow(max(dot(N, H), 0.0), max(shininess, 0.0));

  vec3 color = (ambient * lightColor) + diff + spec;
  fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
