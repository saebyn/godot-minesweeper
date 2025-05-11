shader_type canvas_item;

// Adjustable parameters
uniform vec3 big_color : source_color = vec3(0.0, 0.7, 0.7);
uniform vec3 small_color : source_color = vec3(0.8, 0.0, 0.8);
uniform float big_speed : hint_range(-2.0, 2.0) = 0.3;
uniform float small_speed : hint_range(-2.0, 2.0) = 0.35;
uniform float big_size : hint_range(0.1, 2.0) = 1.0;
uniform float small_size : hint_range(0.1, 2.0) = 1.0;

// Constants
const float BRUSH_SHARPNESS = 30.0;
const float BIG_CONNECTION = 0.9;
const int BIG_COUNT = 6;
const float BIG_PITCH = 0.5;
const vec2 BIG_TOP = vec2(-0.4, 0.85);
const vec2 BIG_BOTTOM = vec2(0.4, 0.15);
const vec2 BIG_BRUSH = vec2(-0.17, -0.01);

const float SMALL_CONNECTION = 0.8;
const int SMALL_COUNT = 8;
const float SMALL_PITCH = 0.3;
const vec2 SMALL_TOP = vec2(-0.25, 0.65);
const vec2 SMALL_BOTTOM = vec2(0.25, 0.35);
const vec2 SMALL_BRUSH = vec2(-0.02, -0.05);

// Precalculated constants
const mat2 M = mat2(vec2(1.616, 1.212), vec2(-1.212, 1.616));
const float BS1 = BRUSH_SHARPNESS + 1.0;

// Hash functions adapted from David Hoskins
float hash11(float p) {
    vec2 p2 = fract(p * vec2(5.3983, 5.4427));
    p2 += dot(p2.yx, p2.xy + vec2(21.5351, 14.3137));
    return fract(p2.x * p2.y * 95.4337);
}

vec2 hash21(float p) {
    vec2 p2 = fract(p * vec2(5.3983, 5.4427));
    p2 += dot(p2.yx, p2.xy + vec2(21.5351, 14.3137));
    return fract(vec2(p2.x * p2.y * 95.4337, p2.x * p2.y * 97.597));
}

float hash12(vec2 p) {
    p = fract(p * vec2(5.3983, 5.4427));
    p += dot(p.yx, p.xy + vec2(21.5351, 14.3137));
    return fract(p.x * p.y * 95.4337);
}

float noise12(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash12(i + vec2(0.0, 0.0)), hash12(i + vec2(1.0, 0.0)), u.x),
        mix(hash12(i + vec2(0.0, 1.0)), hash12(i + vec2(1.0, 1.0)), u.x),
        u.y
    );
}

float fbm12(vec2 p) {
    float f = noise12(p); p = M * p;
    f += 0.5 * noise12(p); p = M * p;
    f += 0.25 * noise12(p); p = M * p;
    f += 0.125 * noise12(p);
    return f / 1.875;
}

float add_stroke(vec2 pos, vec2 a, vec2 b, vec2 brush, float edge, float falloff) {
    vec2 dir = b - a;
    vec2 p = pos - a;
    float d = (dir.y * p.x - dir.x * p.y) / (dir.y * brush.x - dir.x * brush.y);
    d = clamp(d, 0.0, 1.0);
    p = pos - d * brush;
    float e = (distance(p, a) + distance(p, b) - length(dir)) / edge;
    return (1.0 - falloff * d) * max(1.0 - e, 0.0);
}

float brush(vec2 pos, float stroke) {
    float p = BRUSH_SHARPNESS * fbm12(70.0 * pos);
    float s = 0.75 * stroke;
    return 1.0 / (pow(1.0 / (1.0 - s), p) * pow(1.0 / s, p - BS1) / (s - 1.0) - 1.0) + 1.0;
}

void fragment() {
    vec3 color = vec3(1.0);
    vec3 big_c = vec3(1.0) - big_color;
    vec3 small_c = vec3(1.0) - small_color;

    // Calculate position based on UV coordinates
    vec2 pos = UV + vec2(big_speed * TIME, 0.0);
    float id_offset = floor(big_speed * TIME / BIG_PITCH);
    float stroke = 0.0;
    vec2 last = vec2(-0.5, 0.5);

    // Big strokes
    for (int i = 0; i < BIG_COUNT; ++i) {
        float id = float(i) + id_offset;

        vec2 offset = vec2(id * BIG_PITCH, 0.0);
        vec2 top = offset + big_size * BIG_TOP + 0.1 - 0.2 * hash21(id);
        vec2 bottom = offset + big_size * BIG_BOTTOM + 0.1 - 0.2 * hash21(id + 0.1);

        if (hash11(id + 0.2) < BIG_CONNECTION) {
            stroke = max(stroke, add_stroke(pos, last, top, big_size * BIG_BRUSH, 0.02, 0.6));
        }
        stroke = max(stroke, add_stroke(pos, top, bottom, big_size * BIG_BRUSH, 0.02, 0.6));

        last = bottom;
    }
    color *= vec3(1.0) - brush(pos, stroke) * big_c;

    // Small strokes
    pos = UV + vec2(small_speed * TIME, 0.0);
    id_offset = floor(small_speed * TIME / SMALL_PITCH);
    stroke = 0.0;
    last = vec2(-0.5, 0.5);

    for (int i = 0; i < SMALL_COUNT; ++i) {
        float id = float(i) + id_offset;

        vec2 offset = vec2(id * SMALL_PITCH, 0.0);
        vec2 top = offset + small_size * SMALL_TOP + 0.05 - 0.1 * hash21(id + 0.3);
        vec2 bottom = offset + small_size * SMALL_BOTTOM + 0.05 - 0.1 * hash21(id + 0.4);

        if (hash11(id + 0.5) < SMALL_CONNECTION) {
            stroke = max(stroke, add_stroke(pos, last, top, small_size * SMALL_BRUSH, 0.01, 0.6));
        }
        stroke = max(stroke, add_stroke(pos, top, bottom, small_size * SMALL_BRUSH, 0.01, 0.6));

        last = bottom;
    }
    color *= vec3(1.0) - brush(pos, stroke) * small_c;

    COLOR = vec4(color, 1.0);
}