shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

uniform float time : hint_range(0, 1000) = 0.0;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.15;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.35;
uniform float grid_pulse : hint_range(0.0, 1.0) = 0.0;
uniform vec4 border_color : source_color = vec4(0.24, 0.97, 1.0, 1.0);
uniform vec4 secondary_border_color : source_color = vec4(1.0, 0.22, 0.82, 1.0);
uniform float screen_shake_x : hint_range(-10.0, 10.0) = 0.0;
uniform float screen_shake_y : hint_range(-10.0, 10.0) = 0.0;
uniform float eat_flash : hint_range(0.0, 1.0) = 0.0;
uniform float death_flash : hint_range(0.0, 1.0) = 0.0;

vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float noise(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

void fragment() {
    vec2 uv = SCREEN_UV;
    
    // Apply screen shake
    uv += vec2(screen_shake_x, screen_shake_y) * 0.002;
    
    vec4 col = texture(screen_texture, uv);
    
    // Scanlines
    float scanline = sin(uv.y * 1080.0 * 0.5 + time * 0.1) * 0.5 + 0.5;
    col.rgb *= 1.0 - scanline_intensity * (1.0 - scanline) * 0.3;
    
    // Subtle horizontal interference lines
    float interference = sin(uv.y * 1080.0 * 2.0 + time * 3.0) * 0.005;
    col.rgb += vec3(0.0, 0.2, 0.4) * interference;
    
    // Vignette
    float dist = distance(uv, vec2(0.5));
    float vignette = smoothstep(0.5, 0.9, dist) * vignette_strength;
    col.rgb *= 1.0 - vignette;
    
    // Eat flash pulse
    if (eat_flash > 0.0) {
        float pulse = eat_flash * (0.5 + 0.5 * sin(time * 30.0));
        col.rgb += vec3(0.2, 1.0, 1.0) * pulse * 0.15;
    }
    
    // Death flash
    if (death_flash > 0.0) {
        float pulse = death_flash * (0.5 + 0.5 * sin(time * 15.0));
        col.rgb += vec3(1.0, 0.2, 0.3) * pulse * 0.3;
    }
    
    // Subtle chromatic aberration at edges
    float ca = smoothstep(0.7, 1.0, dist) * 0.001;
    vec2 offset = (uv - 0.5) * ca;
    col.r = texture(screen_texture, uv + offset).r;
    col.b = texture(screen_texture, uv - offset).b;
    
    COLOR = col;
}