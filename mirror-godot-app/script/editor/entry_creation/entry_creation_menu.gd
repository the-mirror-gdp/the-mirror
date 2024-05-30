extends VBoxContainer


signal script_entry_creation_confirmed()

## If you increase this, add more *adic methods to entry.gd and
## reference them in _get_callable_for_event_signal().
const _MAX_SIGNAL_PARAMETERS = 5

var _custom_signal_parameters: Dictionary = {}
var _target_node: Node # SpaceObject or SpaceGlobalScripts

@onready var _signal_selection = $SignalSelection
@onready var _custom_signal = $CustomSignal
@onready var _custom_signal_name: LineEdit = $CustomSignal/SignalName/LineEdit
@onready var _signal_parameters_label: RichTextLabel = $CustomSignal/SignalParameters
@onready var _add_input_button: Button = $CustomSignal/AddInputButton


func setup(signal_tree_populator: ScriptEntrySignalTreePopulator) -> void:
	_signal_selection.setup(signal_tree_populator)


func populate_selection_tree(target_node: Node, for_custom: bool) -> void:
	_target_node = target_node
	_custom_signal_parameters.clear()
	_add_input_button.show()
	_custom_signal_name.text = ""
	_signal_parameters_label.text = "Signal Inputs:"
	if for_custom:
		_show_custom_entry_menu()
	else:
		_signal_selection.populate_selection_tree(target_node)
		_signal_selection.show()
		_custom_signal.hide()


func focus_search_bar() -> void:
	_signal_selection.focus_search_bar()


func get_desired_signal_signature():
	if _signal_selection.visible:
		return _get_selected_signal_signature()
	# If signal selection is not visible, we must be making a custom signal.
	return _get_custom_signal_signature()


func _show_custom_entry_menu() -> void:
	_signal_selection.hide()
	_custom_signal.show()


func _get_selected_signal_signature():
	var signal_dict = _signal_selection.get_selected_signal()
	if signal_dict == null:
		return null
	if String(signal_dict["signal"]) == "custom_signal":
		_show_custom_entry_menu()
		return null
	return signal_dict


func _get_custom_signal_signature():
	var signal_name: String = _custom_signal_name.text
	if signal_name.is_empty():
		Notify.error("Unable to create custom signal", "Custom signal must have a non-empty name.")
		return null
	var signal_sname := StringName(signal_name)
	if _target_node.has_signal(signal_sname) and not _target_node.has_user_signal(signal_sname):
		Notify.error("Unable to create custom signal", "Custom signal cannot be named '" + signal_name + "'.")
		return null
	var existing_signature: Dictionary = ScriptSignalRegistration.get_signature_from_user_signal_name(signal_sname)
	if not existing_signature.is_empty():
		existing_signature = existing_signature.duplicate()
		existing_signature["path"] = "self"
		existing_signature["type"] = "entry"
		return existing_signature
	var ret = {
		"entry_id": "self_" + signal_name + "_" + str(randi() % 1000000),
		"name": "On " + signal_name.capitalize(),
		"path": "self",
		"signal": signal_name,
		"type": "entry",
	}
	if not _custom_signal_parameters.is_empty():
		ret["signalParameters"] = _custom_signal_parameters.duplicate(true)
	return ret


func _on_request_parameter_creation(param_array: Array) -> void:
	var param_data: Array = param_array.slice(1)
	_custom_signal_parameters[param_array[0]] = param_data
	_custom_signal_parameters.sort()
	_update_custom_signal_parameters()


func _on_signal_name_text_changed(signal_name: String) -> void:
	var signal_sname := StringName(signal_name)
	if _target_node.has_signal(signal_sname) and not _target_node.has_user_signal(signal_sname):
		_signal_parameters_label.text = "Signal cannot be named '" + signal_name + "'."
		_add_input_button.hide()
		return
	var signature: Dictionary = ScriptSignalRegistration.get_signature_from_user_signal_name(signal_sname)
	if signature.is_empty():
		_update_custom_signal_parameters() # In case we hid it before.
		return # Name does not match any existing user signal.
	_signal_parameters_label.text = "Existing signature found for\n'" + signal_name + "', using that."
	_add_input_button.hide()


func _update_custom_signal_parameters() -> void:
	_add_input_button.visible = _custom_signal_parameters.size() < _MAX_SIGNAL_PARAMETERS
	if _custom_signal_parameters.is_empty():
		_signal_parameters_label.text = "Signal Inputs:"
		return
	var new_text: String = "Signal Inputs:"
	for param_name in _custom_signal_parameters:
		var param_data: Array = _custom_signal_parameters[param_name]
		var param_str: String = _convert_parameter_to_gdscript_style_string(param_name, param_data[0], param_data[1])
		new_text += "\n" + param_str
	_signal_parameters_label.text = new_text


func _convert_parameter_to_gdscript_style_string(param_name: String, param_type: ScriptBlock.PortType, param_value: Variant) -> String:
	var type_color: String = _get_port_type_color_as_hex(param_type)
	var type_str: String = Serialization.type_enum_to_friendly_string(param_type)
	var value_color: String = _get_port_value_color_as_hex(param_value)
	var value_str: String = _get_port_value_as_string(param_value)
	return "[color=cdcfd2]%s[/color][color=abc9ff]: [/color][color=%s]%s[/color][color=abc9ff] = [/color][color=%s]%s[/color]" % [param_name, type_color, type_str, value_color, value_str]


func _get_port_type_color_as_hex(port_type: ScriptBlock.PortType) -> String:
	if port_type == TYPE_BOOL or port_type == TYPE_INT or port_type == TYPE_FLOAT:
		return "ff7085"
	return "41ffc2"


func _get_port_value_color_as_hex(port_value: Variant) -> String:
	var port_value_type: int = typeof(port_value)
	if port_value_type == TYPE_BOOL:
		return "ff7085"
	if port_value_type == TYPE_STRING:
		return "ffeda1"
	return "a1ffe0"


func _get_port_value_as_string(port_value: Variant) -> String:
	if typeof(port_value) == TYPE_STRING:
		return '"' + port_value + '"'
	return str(port_value)


func _on_tree_item_activated() -> void:
	script_entry_creation_confirmed.emit()
