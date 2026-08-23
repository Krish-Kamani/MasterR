#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 srcSize;
    float darken;
};
layout(binding = 1) uniform sampler2D source;

vec4 cubicW(float t) {
    float t2 = t * t;
    float t3 = t2 * t;
    return vec4(
        (-t3 + 3.0 * t2 - 3.0 * t + 1.0) / 6.0,
        (3.0 * t3 - 6.0 * t2 + 4.0) / 6.0,
        (-3.0 * t3 + 3.0 * t2 + 3.0 * t + 1.0) / 6.0,
        t3 / 6.0
    );
}

vec3 bicubic(vec2 uv) {
    vec2 pos = uv * srcSize - 0.5;
    vec2 base = floor(pos);
    vec2 f = pos - base;
    vec4 wx = cubicW(f.x);
    vec4 wy = cubicW(f.y);
    vec3 acc = vec3(0.0);
    for (int j = -1; j <= 2; j++) {
        for (int i = -1; i <= 2; i++) {
            vec2 tc = (base + vec2(float(i), float(j)) + 0.5) / srcSize;
            acc += texture(source, clamp(tc, vec2(0.0), vec2(1.0))).rgb * wx[i + 1] * wy[j + 1];
        }
    }
    return acc;
}

void main() {
    vec3 c = bicubic(qt_TexCoord0) * darken;

    vec2 d = qt_TexCoord0 - vec2(0.5);
    float vig = smoothstep(0.95, 0.40, length(d));
    c *= mix(0.86, 1.0, vig);

    float n = fract(sin(dot(qt_TexCoord0, vec2(12.9898, 78.233))) * 43758.5453);
    c += (n - 0.5) * (3.0 / 255.0);

    fragColor = vec4(c, 1.0) * qt_Opacity;
}
