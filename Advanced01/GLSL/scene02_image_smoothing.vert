#version 130

in vec4 vertexPosition;
in vec2 inTexCoord;

out vec2 outTexCoord;

void main() {
    gl_Position = vertexPosition;
    outTexCoord = inTexCoord;
}
