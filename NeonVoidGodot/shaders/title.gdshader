shader_type canvas_item;
void fragment() {
 vec4 original = COLOR;
 float t = clamp((SCREEN_UV.x-0.3)*2.5 + sin(TIME*0.5)*0.1,0.0,1.0);
 vec3 c;
 if(t<0.3) c=mix(vec3(1.,0.17,0.84),vec3(1.,0.69,0.18),t/0.3);
 else if(t<0.55) c=mix(vec3(1.,0.69,0.18),vec3(0.71,1.,0.18),(t-0.3)/0.25);
 else c=mix(vec3(0.71,1.,0.18),vec3(0.13,0.9,1.),(t-0.55)/0.45);
 COLOR=vec4(c,original.a);
}
