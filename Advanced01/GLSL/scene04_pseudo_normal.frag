#version 130

in vec3 vVertexNormal;
out vec4 fragColor;

void main()
{
	vec3 c = 0.5 * normalize(vVertexNormal) + 0.5;
	fragColor = vec4(c, 1.0);
}
