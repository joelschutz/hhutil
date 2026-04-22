// precision highp float;
extern LOVE_HIGHP_OR_MEDIUMP float time ;
extern float scale;
extern vec2 resolution;
extern vec2 offset;

#define PI 3.14159265358979323846


vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    // Wrap time to prevent precision loss at large values.
    // 1290 is the Least Common Multiple of the divisors used (1, 2, 3, 4, 5).
    float t = mod(time, 60.0 * 2.0 * PI);

    // Scale the coordinates. Higher scale = smaller/denser patterns.
    vec2 p = ((screen_coords + offset) / resolution) * scale;

    // sum of sine waves to create the plasma pattern
    float v = 0.0;
    
    // Horizontal and vertical waves
    v += sin(p.x + t);
    v += sin((p.y + t) / 2.0);
    v += sin((p.y + t) / 4.0);
    v += sin((p.x + p.y + t) / 2.0);
    v += sin((p.x + p.y + t) / 5.0);

    // Circular moving wave
    vec2 center = p + vec2(5.0 * sin(t / 5.0), 5.0 * cos(t / 3.0));
    v += sin(sqrt(dot(center, center) + 1.0) + t);

    v = v / 2.0;

    // Color mapping using phase-shifted sine waves
    vec3 col = vec3(
        sin(v * 3.14159), 
        sin(v * 3.14159 + 2.0 * 3.14159 / 3.0), 
        sin(v * 3.14159 + 4.0 * 3.14159 / 3.0)
    );

    return vec4(col * 0.5 + 0.5, 1.0) * color;
}