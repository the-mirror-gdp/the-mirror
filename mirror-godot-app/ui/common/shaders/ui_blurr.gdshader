shader_type canvas_item;
// intentionally disabled as this doesn't work on intel or meta quest 3 without introducing 50ms of delay in the rendering pipeline.
// Still linked to UI elements so cannot easily be removed, commenting out is sufficient.

//uniform float blur: hint_range(0.0, 8.0);
//uniform vec4 color: source_color;
//uniform float strength: hint_range(0.0, 1.0, 0.05);
//uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

//void fragment() {
	//
	//COLOR = textureLod(SCREEN_TEXTURE, SCREEN_UV, blur);
	//COLOR = mix(COLOR, color, strength);
//}
