#version 130

in vec4 vertexPosition;
in vec3 vertexNormal;

out vec3 vVertexNormal;

uniform mat4 modelViewMatrix;
uniform mat4 projMatrix;
uniform mat3 modelViewInvTransposed;

void main() {
    gl_Position = projMatrix * modelViewMatrix * vertexPosition;

    vec3 n_view = normalize(modelViewInvTransposed * vertexNormal);
    vVertexNormal = n_view;
}
