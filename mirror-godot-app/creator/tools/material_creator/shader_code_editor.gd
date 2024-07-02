extends CodeEdit


# Based on Material-Maker
# MIT License
#Copyright (c) 2018-2021 Rodolphe Suescun and contributors

const _KEYWORDS: Array[String]  = [ "attribute", "uniform", "varying", "const", "in", "out",
									"inout", "discard", "return", "break", "continue", "do",
									"for", "while", "if", "else", "switch", "case", "default",
									"true", "false", "highp", "mediump", "lowp", "precision",
									"struct", "shader_type", "render_mode", "#include" ]
const _TYPES: Array[String] = [ "void", "bool", "int", "uint", "float", "double", "bvec2",
								"bvec3", "bvec4", "ivec2", "ivec3", "ivec4", "uvec2",
								"uvec3", "uvec4", "vec2", "vec3", "vec4", "dvec2",
								"dvec3", "dvec4", "mat2", "mat3", "mat4", "mat2x2",
								"mat2x3", "mat2x4", "mat3x2", "mat3x3", "mat3x4",
								"mat4x2", "mat4x3", "mat4x4", "sampler1D", "sampler2D",
								"sampler3D", "samplerCube" ]

const _FUNCTIONS: Array[String] = [ "radians", "degrees", "sin", "cos", "tan", "asin",
									"acos", "atan", "pow", "exp", "log", "exp2", "log2",
									"sqrt", "inversesqrt", "abs", "sign", "floor", "ceil",
									"fract", "mod", "min", "max", "clamp", "mix", "step",
									"smoothstep", "length", "distance", "dot", "cross",
									"normalize", "texture", "textureLod" ]

const _MAGIC_VARIABLES: Array[String] = ["VERTEX", "NORMAL", "BINORMAL", "TANGENT",
 									"MODEL_MATRIX", "PROJECTION_MATRIX", "MODELVIEW_MATRIX",
 									"INV_VIEW_MATRIX", "UV", " SCREEN_UV",
									"NORMAL_MAP", "NORMAL_MAP_DEPTH", "ALBEDO", "METALLIC",
									 "ROUGHNESS", "SPECULAR", "ALPHA",
									"TIME", "FRONT_FACING", "ALPHA_SCISSOR_THRESHOLD", "BACKLIGHT",
									"blend_mix", "depth_draw_opaque", "cull_back", "diffuse_burley", "specular_schlick_ggx",
									"cull_disabled"
									]


@onready var _erorr_label = $ErorrLabel
@onready var _validate_timer = $ValidateTimer

var _shader_validator = TMShaderLanguage.new()

var _highlight_error_line: int = -1:
	set(value):
		set_line_background_color(_highlight_error_line, Color(0,0,0,0))
		_highlight_error_line = value
		set_line_background_color(_highlight_error_line, Color(0.42, 0.29, 0.29))


func safe_set_text(new_text) -> void:
	var carets = get_caret_count()
	var tmp_pos: Array[Vector2i] = []
	for caret in carets:
		tmp_pos.push_back(Vector2i(
			get_caret_column(caret),
			get_caret_line(caret)
		))
	text = new_text
	for index in range(tmp_pos.size()):
		var caret = tmp_pos[index]
		set_caret_column(caret.x, true, index)
		set_caret_line(caret.y, true, true, 0, index)


func _ready() -> void:
	add_comment_delimiter("//", "", true)
	add_comment_delimiter("/*", "*/", false)
	for t in _KEYWORDS:
		syntax_highlighter.add_keyword_color(t, Color(0.859, 0.392, 0.463))
	for t in _TYPES:
		syntax_highlighter.add_keyword_color(t, Color(0.859, 0.392, 0.463))
	for t in _FUNCTIONS:
		syntax_highlighter.add_keyword_color(t, Color(1, 0.439, 0.518))
	for t in _MAGIC_VARIABLES:
		syntax_highlighter.add_keyword_color(t, Color(0.643, 0.824, 0.773))


func _on_focus_entered() -> void:
	GameUI.instance.grab_input_lock(self)


func _on_focus_exited() -> void:
	GameUI.instance.release_input_lock(false)


func _on_visibility_changed() -> void:
	# there is a bug with Theming, we need to clear it on visibility change
	# otherwise highlighter is not working
	remove_theme_stylebox_override("normal")
	remove_theme_stylebox_override("focus")
	remove_theme_stylebox_override("read_only")
	remove_theme_stylebox_override("completion")


func _on_validate_timer_timeout() -> void:
	var errors: String = _shader_validator.compile_spatial(text)
	_erorr_label.text = errors
	var error_line = "error("
	if errors.begins_with(error_line):
		var close_parentheisis = errors.find(")")
		var error_line_len = error_line.length()
		_highlight_error_line = int(errors.substr(error_line_len, close_parentheisis - error_line_len)) - 1
	else:
		_highlight_error_line = -1


func _on_text_changed() -> void:
	_validate_timer.start()
