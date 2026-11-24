shader_type canvas_item;
render_mode skip_vertex_transform;

uniform vec4 reference_items[16];
uniform float visible_count = 0.0;
uniform vec2 atlas_grid = vec2(10.0, 8.0);
uniform float art_scale = 1.0;

varying vec4 petal_tint;
varying float petal_visibility;
varying vec2 frame_origin;

void vertex() {
	int item_index = int(INSTANCE_ID) % 16;
	vec4 reference_item = reference_items[item_index];
	float sprite_scale = reference_item.w * art_scale;
	vec2 local_vertex = (VERTEX / atlas_grid) * sprite_scale;
	VERTEX = (MODEL_MATRIX * vec4(local_vertex, 0.0, 1.0)).xy;
	VERTEX += reference_item.xy;
	frame_origin = vec2(mod(reference_item.z, atlas_grid.x), floor(reference_item.z / atlas_grid.x));
	petal_tint = COLOR;
	petal_visibility = float(INSTANCE_ID) < visible_count ? 1.0 : 0.0;
}

void fragment() {
	vec2 atlas_uv = (UV + frame_origin) / atlas_grid;
	vec4 petal_sample = texture(TEXTURE, atlas_uv);
	COLOR = petal_sample * petal_tint;
	COLOR.a *= petal_visibility;
}
