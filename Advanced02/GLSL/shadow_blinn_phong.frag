#version 130

in vec3 vEyePos;
in vec3 vEyeNormal;
in vec4 vShadowCoord;

out vec4 fragColor;

uniform sampler2DShadow shadowTex;

uniform vec3 eLightDir;
uniform vec3 lightColor;
uniform float shininess;
uniform vec3 diffuseCoeff;
uniform vec3 ambient;

void main() {
    vec3 N = normalize(vEyeNormal);
    vec3 V = normalize(-vEyePos);
    vec3 L = normalize(eLightDir);

    // Blinn-Phong
    float NdotL = max(dot(N, L), 0.0);
    vec3 diff = diffuseCoeff * lightColor * NdotL;

    vec3 H = normalize(L + V);
    vec3 spec = lightColor * ((NdotL > 0.0) ? pow(max(dot(N, H), 0.0), max(shininess, 0.0)) : 0.0);
    vec3 amb = ambient * lightColor;

    vec3 color = (amb + diff + spec) * textureProj(shadowTex, vShadowCoord);
    fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);
}
