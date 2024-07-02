class_name ScriptParameterCreationMenu
extends VBoxContainer


signal request_variable_creation()

const INSPECTOR_PRIMITIVE_SCENES: Dictionary = {
	ScriptBlock.PortType.ANY_DATA: preload("res://creator/selection/inspector/primitive/inspector_line_edit_field.tscn"),
	ScriptBlock.PortType.BOOL: preload("res://creator/selection/inspector/primitive/inspector_bool.tscn"),
	ScriptBlock.PortType.INT: preload("res://creator/selection/inspector/primitive/inspector_integer_field.tscn"),
	ScriptBlock.PortType.FLOAT: preload("res://creator/selection/inspector/primitive/inspector_number_field.tscn"),
	ScriptBlock.PortType.STRING: preload("res://creator/selection/inspector/primitive/inspector_line_edit_field.tscn"),
	ScriptBlock.PortType.VECTOR2: preload("res://creator/selection/inspector/primitive/inspector_vector2.tscn"),
	ScriptBlock.PortType.VECTOR3: preload("res://creator/selection/inspector/primitive/inspector_vector3.tscn"),
	ScriptBlock.PortType.COLOR: preload("res://creator/selection/inspector/primitive/inspector_color.tscn"),
}

## If true, convert "Any Data" ports to a specific type.
@export var convert_any_data: bool = false

var _primitive_value_editor: Control
var _last_edited_data_type: int = ScriptBlock.PortType.ANY_DATA

@onready var _name_line_edit: LineEdit = $VariableName/NameLineEdit
@onready var _data_type_dropdown: OptionButton = $DataType/DataTypeDropdown


func _ready() -> void:
	_on_data_type_selected(_data_type_dropdown.selected)


func clear_fields() -> void:
	_name_line_edit.text = ""
	_on_data_type_selected(_last_edited_data_type)


func focus_variable_editor_name_field() -> void:
	_name_line_edit.grab_focus()


func get_variable_array() -> Array:
	var variable_name: String = _name_line_edit.text
	var data_type: int = _data_type_dropdown.get_item_id(_data_type_dropdown.selected)
	var value: Variant = null
	if is_instance_valid(_primitive_value_editor):
		value = _primitive_value_editor.current_value
	# Special case: Change the String to another type if this port is "Any Data".
	if data_type == ScriptBlock.PortType.ANY_DATA:
		value = Serialization.convert_any_data_string_to_value(value)
		if convert_any_data:
			data_type = typeof(value)
	else:
		value = type_convert(value, data_type)
	return [variable_name, data_type, value]


func erase_type_from_option_button(data_type: int) -> void:
	_data_type_dropdown.remove_item(_data_type_dropdown.get_item_index(data_type))


func _on_value_submitted() -> void:
	request_variable_creation.emit()


func _on_data_type_selected(data_type_index: int) -> void:
	if is_instance_valid(_primitive_value_editor):
		remove_child(_primitive_value_editor)
		_primitive_value_editor.queue_free()
	var data_type: int = _data_type_dropdown.get_item_id(data_type_index)
	if data_type in INSPECTOR_PRIMITIVE_SCENES:
		var primitive_scene: PackedScene = INSPECTOR_PRIMITIVE_SCENES[data_type]
		_primitive_value_editor = primitive_scene.instantiate()
		_primitive_value_editor.theme = theme
		_primitive_value_editor.label_text = "Default Value"
		add_child(_primitive_value_editor)
		_primitive_value_editor.value_submitted.connect(_on_value_submitted)
	_last_edited_data_type = data_type


func _on_name_line_edit_focus_entered() -> void:
	GameUI.instance.grab_input_lock(self)
