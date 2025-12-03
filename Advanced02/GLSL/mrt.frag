#version 130

in vec3 vEyePos;
in vec3 vEyeNormal;

void main() {
    gl_FragData[0] = vec4(vEyePos, 1.0); // 座標

    vec3 n = normalize(vEyeNormal);
    gl_FragData[1] = vec4(0.5 * n + 0.5, 1.0); // 法線

    float d = gl_FragCoord.z;
    gl_FragData[2] = vec4(d, d, d, 1.0); // デプス値
}
