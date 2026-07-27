#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 uItemSize;
    vec2 uHexCenter;
    float uHexR;
    float uPointyTop;
    float uBevelWidth;
    float uStrength;
    vec2 uLightDir;
};

layout(binding = 1) uniform sampler2D source;

// Inigo Quilez's regular-hexagon SDF (flat-top: vertices left/right, flat
// edges top/bottom). Returns negative inside, positive outside, distance
// in the same units as r and p.
float sdHexagon(vec2 p, float r) {
    const vec3 k = vec3(-0.8660254, 0.5, 0.5773503);
    p = abs(p);
    p -= 2.0 * min(dot(k.xy, p), 0.0) * k.xy;
    p -= vec2(clamp(p.x, -k.z * r, k.z * r), r);
    return length(p) * sign(p.y);
}

void main() {
    vec4 col = texture(source, qt_TexCoord0);

    vec2 fragPx = qt_TexCoord0 * uItemSize;
    vec2 local = fragPx - uHexCenter;
    // Our pointy-top hexagon is the flat-top one rotated -90°; sample the
    // SDF in flat-top space by rotating the point the opposite way first.
    if (uPointyTop > 0.5)
        local = vec2(local.y, -local.x);

    float d = sdHexagon(local, uHexR);
    // t: 1 right at the true edge (d=0), ramps down to 0 by the time we're
    // uBevelWidth px into the interior (d=-uBevelWidth) and stays 0 beyond
    // that — flat interior, raised band only near the rim. Smooth and
    // continuous across corners since it comes from one analytic distance
    // field, not from stitched-together stroke segments.
    float t = clamp(1.0 + d / uBevelWidth, 0.0, 1.0);
    t = smoothstep(0.0, 1.0, t);

    float lightSide = dot(normalize(local + vec2(0.0001)), uLightDir);
    float shade = 1.0 + t * lightSide * uStrength;
    col.rgb *= shade;

    fragColor = col * qt_Opacity;
}
