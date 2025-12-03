#version 130

in vec2 outTexCoord;
out vec4 fragColor;

uniform sampler2D stateTex;
uniform vec2 pixelSize;
uniform int doUpdate;

float alive(vec2 uv) {
    return step(0.5, texture2D(stateTex, uv).r);
}

void main() {
    if (doUpdate == 0) {
        fragColor = texture2D(stateTex, outTexCoord);
        return;
    }

    vec2 uv = outTexCoord;
    vec2 px = pixelSize;

    vec2 o[8];
    o[0] = vec2(-1.0, -1.0);
    o[1] = vec2( 0.0, -1.0);
    o[2] = vec2( 1.0, -1.0);
    o[3] = vec2(-1.0,  0.0);
    o[4] = vec2( 1.0,  0.0);
    o[5] = vec2(-1.0,  1.0);
    o[6] = vec2( 0.0,  1.0);
    o[7] = vec2( 1.0,  1.0);

    float c = alive(uv);
    float n = 0.0;
    for (int i = 0; i < 8; ++i) {
        n += alive(uv + o[i] * px);
    }

    // Conway rule
    float born    = step(2.5, n) * step(n, 3.5); // 3
    float survive = step(1.5, n) * step(n, 3.5); // 2 or 3
    float next    = mix(born, survive, c);       // c=0: born, c=1: survive

    fragColor = vec4(next, next, next, 1.0);
}
