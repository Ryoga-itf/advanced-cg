#version 130

in vec2 outTexCoord;
out vec4 fragColor;

uniform sampler2D tex;
uniform int halfKernelSize;
uniform float uScale;
uniform float vScale;

void main()
{
	if (halfKernelSize <= 0) {
		fragColor = texture2D(tex, outTexCoord);
		return;
	}

	float div = halfKernelSize * halfKernelSize;

	vec4 acc = vec4(0.0);
	float wsum = 0.0;

	for (int j = -halfKernelSize; j <= halfKernelSize; ++j) {
		for (int i = -halfKernelSize; i <= halfKernelSize; ++i) {
			float dx = float(i);
			float dy = float(j);
			float r2 = dx * dx + dy * dy;
			float w = exp(-r2 / div);

			vec2 offset = vec2(dx * uScale, dy * vScale);
			vec4 c = texture2D(tex, outTexCoord + offset);

			acc += c * w;
			wsum += w;
		}
	}

	if (wsum > 0.0) {
		acc /= wsum;
	}

	fragColor = acc;
}
