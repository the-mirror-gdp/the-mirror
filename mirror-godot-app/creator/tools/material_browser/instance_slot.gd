class_name MaterialInstanceSlot
extends AssetSlot

@onready var _preview = $Panel/Preview
@onready var _custom_shader_label = $Panel/CustomShaderLabel

var _material: MirrorMaterial

func _ready() -> void:
	pass # override parent


func populate_item_slot(asset_dict: Dictionary) -> void:
	_preview.texture = asset_dict.preview
	_material = asset_dict.material
	_custom_shader_label.visible = _material.feature_supported(MirrorMaterial.MATERIAL_FEATURE.CUSTOM_SHADER)
	asset_data = AssetData.new()
	asset_data.asset_id = asset_dict.material.resource_name


func _on_mouse_entered() -> void:
	if not is_instance_valid(_material):
		return
	tooltip_text = "%s\n(%s)" % [_material.instance_name, _material.get_material_type_name()]



func _on_gui_input(input_event: InputEvent) -> void:
	if input_event.is_action_released(&"primary_action"):
		slot_activated.emit(self, true)
