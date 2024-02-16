extends Control


@export var button_selected_style: StyleBox
@export var button_deselected_style: StyleBox

@export var _add_button: Button
@export var _subtract_button: Button
@export var _flat_button: Button
@export var _paint_button: Button
@export var _brush_size: HSlider
@export var _brush_strength: HSlider

var _terrain_tool: Node
var _material_browser: Node


func setup(creator_ui: CreatorUI) -> void:
	_terrain_tool = creator_ui.terrain_tool
	_material_browser = creator_ui.terrain_material_browser
	_brush_size.min_value = _terrain_tool.MIN_BRUSH_SIZE
	_brush_size.max_value = _terrain_tool.MAX_BRUSH_SIZE
	_terrain_tool.terrain_tool_settings_changed.connect(_terrain_tool_settings_changed)
	_update_options()


func _terrain_tool_settings_changed() -> void:
	_update_options()


func _update_options() -> void:
	_set_brush_mode(_terrain_tool.brush_mode)
	_set_brush_size(_terrain_tool.brush_size)
	_set_brush_strength(_terrain_tool.brush_strength)


func _set_brush_mode(new_mode: Enums.TERRAIN_MODE) -> void:
	_set_button_style(_add_button, button_deselected_style)
	_set_button_style(_subtract_button, button_deselected_style)
	_set_button_style(_flat_button, button_deselected_style)
	_set_button_style(_paint_button, button_deselected_style)
	match new_mode:
		Enums.TERRAIN_MODE.Add:
			_set_button_style(_add_button, button_selected_style)
		Enums.TERRAIN_MODE.Subtract:
			_set_button_style(_subtract_button, button_selected_style)
		Enums.TERRAIN_MODE.Flatten:
			_set_button_style(_flat_button, button_selected_style)
		Enums.TERRAIN_MODE.Paint:
			_set_button_style(_paint_button, button_selected_style)


func _set_brush_size(new_value: float) -> void:
	if _brush_size:
		_brush_size.value = new_value


func _set_brush_strength(new_value: float) -> void:
	if _brush_strength:
		_brush_strength.value = new_value


func _on_material_button_pressed():
	_material_browser.show()


func _on_add_button_pressed() -> void:
	_terrain_tool.set_brush_mode(Enums.TERRAIN_MODE.Add)


func _on_subtract_button_pressed() -> void:
	_terrain_tool.set_brush_mode(Enums.TERRAIN_MODE.Subtract)


func _on_flat_button_pressed() -> void:
	_terrain_tool.set_brush_mode(Enums.TERRAIN_MODE.Flatten)


func _on_paint_button_pressed() -> void:
	_terrain_tool.set_brush_mode(Enums.TERRAIN_MODE.Paint)


func _on_brush_size_changed(new_value: float) -> void:
	_terrain_tool.set_brush_size(new_value)


func _on_brush_strength_changed(new_value: float) -> void:
	_terrain_tool.set_brush_strength(new_value)


func _set_button_style(button: Button, style: StyleBox) -> void:
	button.add_theme_stylebox_override("normal", style)
