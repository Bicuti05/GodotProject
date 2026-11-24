shader_type canvas_item;
render_mode unshaded, blend_mix;
uniform float wave_progress = 0.0;
uniform float tail_progress = 0.0;
void fragment() {
 vec4 tex=texture(TEXTURE,UV);
 vec2 c=UV-vec2(.5);
 float r=length(c);
 // Broad soft wave at birth, narrowing continuously as it expands.
 float age=clamp(wave_progress,0.0,1.0);
 float half_width=mix(.085,.018,pow(age,.65));
 float softness=mix(.030,.008,age)+tail_progress*.004;
 float ring=smoothstep(.42-half_width-softness,.42-half_width+softness,r)
  *(1.0-smoothstep(.42+half_width-softness,.42+half_width+softness,r));
 float mask=tex.a*sqrt(max(tex.r,max(tex.g,tex.b)));
 vec3 tint=mix(vec3(.56,.91,1),vec3(1,.59,.88),.5+.5*sin(atan(c.y,c.x)*2.0));
 tint=mix(tint,vec3(1,.89,.5),smoothstep(.1,.45,c.y)*.65);
 tint=mix(tint,vec3(1.0,.96,.90),.42);
 COLOR=vec4(tint,ring*mask*COLOR.a);
}
