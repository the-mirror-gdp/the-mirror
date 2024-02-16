extends VBoxContainer

signal material_selected(index, material_data)

@export var material_panel_list_item: PackedScene
@export var material_panel_list_item_selected_theme: Theme

@onready var _materials_container = $Materials/Panel/MaterialsList/GridContainer

var selected_material = 0

const stubbed_data = [
	{
		"name": "Mars Material",
		"material": {
			"AB_mix_offset": 0.0,
			"AB_mix_normal": 0.0,
			"AB_mix_blend": 0.0,
			"A_albedo_map": "res://",
			"A_albedo_tint": Color(),
			"A_normal_map": "res://",
			"A_normal_strength": 0.0,
			"A_ao_map": "res://",
			"A_ao_strength": 0.0,
			"A_tri_blend_sharpness": 0.0,
			"B_albedo_map": "res://",
			"B_albedo_tint": Color(),
			"B_normal_map": "res://",
			"B_normal_strength": 0.0,
			"B_normal_distance": 0.0,
			"B_ao_map": "res://",
			"B_ao_strength": 0.0,
			"B_tri_blend_sharpness": 0.0,
		},
	},
	{
		"name": "Gravel Material",
		"material": {
			"AB_mix_offset": 0.0,
			"AB_mix_normal": 0.0,
			"AB_mix_blend": 0.0,
			"A_albedo_map": "res://",
			"A_albedo_tint": Color(),
			"A_normal_map": "res://",
			"A_normal_strength": 0.0,
			"A_ao_map": "res://",
			"A_ao_strength": 0.0,
			"A_tri_blend_sharpness": 0.0,
			"B_albedo_map": "res://",
			"B_albedo_tint": Color(),
			"B_normal_map": "res://",
			"B_normal_strength": 0.0,
			"B_normal_distance": 0.0,
			"B_ao_map": "res://",
			"B_ao_strength": 0.0,
			"B_tri_blend_sharpness": 0.0,
		},
	},
]


# Called when the node enters the scene tree for the first time.
func _ready():
	if material_panel_list_item != null:
		for i in range(stubbed_data.size()):
			var item = material_panel_list_item.instantiate()
			item.get_node("Label").text = stubbed_data[i].name
			item.connect("gui_input", Callable(self, "_on_material_panel_list_item_input").bind(i))
			_materials_container.add_child(item)


func _on_material_panel_list_item_input(input_event: InputEvent, selected_index: int):
	if not input_event.is_action_pressed(&"primary_action"):
		return
	for i in range(_materials_container.get_child_count()):
		var _theme = material_panel_list_item_selected_theme if selected_index == i else null
		_materials_container.get_child(i).theme = _theme
	$BottomButtons/HBoxContainer/Done.disabled = false
	selected_material = selected_index


func _on_done_pressed():
	material_selected.emit(selected_material, stubbed_data[selected_material])
	_on_close()


func _on_close():
	hide()
