shader_type canvas_item;
render_mode unshaded, blend_mix;

// Replace this slot's atlas region, retaining its clipping and animation.
uniform sampler2D replacement_texture : source_color, filter_linear, repeat_disable;
uniform vec4 atlas_region;
uniform vec2 content_scale = vec2(1.0);
uniform float mesh_scale = 1.0;
uniform vec2 mesh_center = vec2(0.0);
uniform bool enabled = false;
varying vec4 slot_color;

void vertex() {
	slot_color = COLOR;
	VERTEX = mesh_center + (VERTEX - mesh_center) * mesh_scale;
}

void fragment() {
	vec2 local_uv = (UV - atlas_region.xy) / atlas_region.zw;
	vec2 content_uv = (local_uv - vec2(0.5)) / content_scale + vec2(0.5);
	float inside = float(all(greaterThanEqual(content_uv, vec2(0.0))) && all(lessThanEqual(content_uv, vec2(1.0))));
	COLOR = enabled ? texture(replacement_texture, content_uv) * slot_color * inside : vec4(0.0);
}
