#version 130

in vec2 outTexCoord;
out vec4 fragColor;

uniform vec4 checkerColor0;
uniform vec4 checkerColor1;
uniform vec2 checkerScale;

void main() {
    vec2 uv = outTexCoord / checkerScale;
    vec2 st = fract(uv);

    bool f = (st.x <= 0.5) ^^ (st.y <= 0.5);

    fragColor = f ? checkerColor1 : checkerColor0;
}
