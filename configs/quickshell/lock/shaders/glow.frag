#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 accent;
    vec4 band0;
    vec4 band1;
    vec4 band2;
};

void acc(inout float num, inout float den, float x, float c, float v) {
    float d = (x - c) * 13.0;
    float w = exp(-0.5 * d * d);
    num += w * v;
    den += w;
}

void main() {
    float x = qt_TexCoord0.x;
    float num = 0.0;
    float den = 0.0;
    acc(num, den, x, 0.041667, band0.x);
    acc(num, den, x, 0.125,    band0.y);
    acc(num, den, x, 0.208333, band0.z);
    acc(num, den, x, 0.291667, band0.w);
    acc(num, den, x, 0.375,    band1.x);
    acc(num, den, x, 0.458333, band1.y);
    acc(num, den, x, 0.541667, band1.z);
    acc(num, den, x, 0.625,    band1.w);
    acc(num, den, x, 0.708333, band2.x);
    acc(num, den, x, 0.791667, band2.y);
    acc(num, den, x, 0.875,    band2.z);
    acc(num, den, x, 0.958333, band2.w);
    float v = num / max(den, 0.0001);

    float h = 0.1 + 0.9 * v;
    float yUp = 1.0 - qt_TexCoord0.y;
    float g = exp(-1.9 * yUp / h) * smoothstep(1.0, 0.85, yUp);
    g *= 0.55 + 0.45 * v;

    float t = clamp(yUp / h, 0.0, 1.0);
    vec3 deep = accent.rgb * 0.55;
    vec3 tip = accent.rgb;
    vec3 col = mix(deep, tip, t);

    float a = g * qt_Opacity;
    fragColor = vec4(col * a, a);
}
