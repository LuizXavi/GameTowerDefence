shader_type canvas_item;
void fragment() {
 vec2 p = UV;
 vec3 c = vec3(0.0196,0.0039,0.0588);
 c += vec3(0.38,0.015,0.32)*exp(-7.0*length((p-vec2(0.1,0.07))*vec2(1.0,0.8)));
 c += vec3(0.005,0.25,0.32)*exp(-7.0*length(p-vec2(0.94,0.4)));
 c += vec3(0.17,0.04,0.32)*exp(-8.0*length(p-vec2(0.5,1.0)));
 c += 0.008*step(0.67,fract(FRAGCOORD.y/3.0));
 COLOR = vec4(c,1.0);
}
