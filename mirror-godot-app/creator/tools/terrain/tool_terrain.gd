extends Node


signal terrain_tool_settings_changed

const MAX_BRUSH_SIZE: float = 10.0
const MIN_BRUSH_SIZE: float = 0.5
const BRUSH_SIZE_STEP: float = 0.5

var brush_mode := Enums.TERRAIN_MODE.Add
var brush_size: float = 4.0
var brush_strength: float = 4.0
var _creator_ui: CreatorUI


func setup(creator_ui: CreatorUI) -> void:
	_creator_ui = creator_ui
	set_brush_mode(Enums.TERRAIN_MODE.Add)
	set_brush_size(2.0)
	set_brush_strength(0.1)

	creator_ui.terrain_material_browser.material_selected.connect(set_material_selected)


func _input(input_event: InputEvent) -> void:
	if not _creator_ui.is_edit_mode(Enums.EDIT_MODE.Terrain):
		return
	if input_event.is_action_pressed(&"terrain_brush_size_increase"):
		set_brush_size(brush_size + BRUSH_SIZE_STEP)
	elif input_event.is_action_pressed(&"terrain_brush_size_decrease"):
		set_brush_size(brush_size - BRUSH_SIZE_STEP)


func set_brush_mode(mode: Enums.TERRAIN_MODE) -> void:
	brush_mode = mode
	terrain_tool_settings_changed.emit()


func set_brush_size(value: float) -> void:
	if value > MAX_BRUSH_SIZE:
		brush_size = MAX_BRUSH_SIZE
	elif value < MIN_BRUSH_SIZE:
		brush_size = MIN_BRUSH_SIZE
	else:
		brush_size = value
	terrain_tool_settings_changed.emit()


func set_brush_strength(value: float) -> void:
	brush_strength = value
	terrain_tool_settings_changed.emit()

func set_material_selected(index, material_data):
	if Zone.Voxels:
		Zone.Voxels.set_material_params(index, material_data)
