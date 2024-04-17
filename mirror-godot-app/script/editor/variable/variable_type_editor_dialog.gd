extends KeyboardGrabbingConfirmationDialog


signal request_variable_editor_refresh()

var _variable_name: String
var _variable_value: Variant
var _variable_node_path: NodePath

@onready var _type_selection_button: OptionButton = $Container/TypeSelectionButtonVarEditor


func edit_variable_type(variable_name: String, current_value: Variant, node_path: NodePath = ^"") -> void:
	_variable_name = variable_name
	_variable_node_path = node_path
	_variable_value = current_value
	title = "Edit '" + _variable_name + "' Type"
	var variable_type: int = typeof(_variable_value)
	var index: int = _type_selection_button.get_item_index(variable_type)
	_type_selection_button.select(index)
	popup_centered()
	GameUI.instance.grab_input_lock(self)


func _on_confirmed() -> void:
	_variable_value = type_convert(_variable_value, _type_selection_button.get_selected_id())
	if _variable_node_path.is_empty():
		Zone.script_network_sync.set_global_variable(_variable_name, _variable_value)
	else:
		Zone.script_network_sync.set_variable_on_node_at_path(_variable_node_path, _variable_name, _variable_value)
	request_variable_editor_refresh.emit()


func _ready():
	get_cancel_button().theme_type_variation = &"ButtonAccent"
