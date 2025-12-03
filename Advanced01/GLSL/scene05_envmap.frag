#version 130

#define PI 3.141592653589793

in vec3 vWorldEyeDir;
in vec3 vWorldNormal;

out vec4 fragColor;
uniform sampler2D envmap;

float atan2(in float y, in float x) {
    return x == 0.0 ? sign(y)*PI/2 : atan(y, x);
}

void main() {
    vec3 ref = reflect(-normalize(vWorldEyeDir), normalize(vWorldNormal));

    float u = atan2(ref.z, ref.x) / (2.0 * PI) + 0.5;
    float v = 0.5 - asin(clamp(ref.y, -1.0, 1.0)) / PI;

    vec3 rgb = texture2D(envmap, vec2(u, v)).rgb;
    fragColor = vec4(rgb, 1.0);
}
