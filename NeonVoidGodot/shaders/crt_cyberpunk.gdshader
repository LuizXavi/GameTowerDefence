shader_type canvas_item;

// Cyberpunk CRT & Scanline Overlay Shader para Neon Void
uniform float scanline_count : hint_range(50.0, 800.0) = 360.0;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.08;
uniform float vignette_intensity : hint_range(0.0, 2.0) = 0.35;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.5;
uniform float glitch_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint_color : source_color = vec4(0.05, 0.0, 0.12, 0.0);
uniform sampler2D screen_texture : hint_screen_texture, filter_linear_mipmap;

void fragment() {
	vec2 uv = SCREEN_UV;
	
	// Chromatic aberration se houver glitch
	vec4 col;
	if (glitch_intensity > 0.01) {
		float offset = glitch_intensity * 0.005;
		col.r = texture(screen_texture, uv + vec2(offset, 0.0)).r;
		col.g = texture(screen_texture, uv).g;
		col.b = texture(screen_texture, uv - vec2(offset, 0.0)).b;
		col.a = 1.0;
	} else {
		col = texture(screen_texture, uv);
	}
	
	// Scanlines sutis
	float scanline = sin(uv.y * scanline_count * 3.14159) * 0.5 + 0.5;
	col.rgb -= scanline * scanline_intensity;
	
	// Vinheta cyberpunk nas bordas
	vec2 center_uv = uv - vec2(0.5);
	float dist = length(center_uv);
	float vignette = smoothstep(0.4, 0.9, dist * vignette_intensity);
	col.rgb = mix(col.rgb, tint_color.rgb, vignette * vignette_opacity);
	
	COLOR = col;
}
