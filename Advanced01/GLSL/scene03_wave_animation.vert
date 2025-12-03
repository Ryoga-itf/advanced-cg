#version 130

in vec4 vertexPosition;

uniform float temporalSignal;
uniform mat4 projModelViewMatrix;

void main()
{
	float x = vertexPosition.x;
	float z = vertexPosition.z;

	float wave = sin(temporalSignal + x) * 0.5 + cos(temporalSignal + z) * 0.5;
	float y = wave;

	gl_Position = projModelViewMatrix * vec4(x, y, z, 1.0);
}
