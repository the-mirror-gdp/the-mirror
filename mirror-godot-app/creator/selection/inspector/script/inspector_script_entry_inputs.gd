extends InspectorCategoryBase


const _TRASH_BUTTON = preload("res://creator/selection/inspector/script/entry_input_trash_button.tscn")

var target_node: Node # SpaceObject or SpaceGlobalScripts
var _target_script_instance: ScriptInstance
var _entry_id: String
var _is_editable: bool = false

var _property_list: Control
var _add_input_button: Control


func _ready() -> void:
	super()
	if not _is_editable:
		return
	var parameters_for_entry: Dictionary = _target_script_instance.entry_parameters[_entry_id]
	for parameter_name in parameters_for_entry:
		var parameter_data: Array = parameters_for_entry[parameter_name]
		_setup_parameter(parameter_name, parameter_data)


## Must run before _ready()
func setup(target_object: Node, script_instance: ScriptInstance, entry_id: String, friendly_name: String, is_editable: bool) -> void:
	target_node = target_object
	_target_script_instance = script_instance
	_entry_id = entry_id
	_property_list = $Properties/MarginContainer/PropertyList
	_add_input_button = $CategoryTitle/ToggleButton/Name/AddInputButton
	_is_editable = is_editable
	set_custom_suffix(friendly_name)


func _setup_parameter(parameter_name: String, parameter_data: Array) -> void:
	var param_type: int = parameter_data[0]
	assert(param_type in ScriptParameterCreationMenu.INSPECTOR_PRIMITIVE_SCENES)
	var param_scene = ScriptParameterCreationMenu.INSPECTOR_PRIMITIVE_SCENES[param_type].instantiate()
	if param_type == ScriptBlock.PortType.INT:
		param_scene.step = 1.0
	param_scene.label_text = parameter_name
	param_scene.reset_value = Serialization.type_convert_any(_target_script_instance.get_default_value_of_entry_inspector_parameter(_entry_id, parameter_name), param_type)
	# Be careful, the order matters here! Value editors with setters
	# that use onready vars can only be used after adding as a child,
	# and then we need to refresh if a refresh method exists.
	_property_list.add_child(param_scene)
	param_scene.current_value = parameter_data[1]
	if param_scene.has_method(&"refresh"):
		param_scene.refresh()
	param_scene.value_changed.connect(_on_parameter_changed.bind(param_scene))
	if _is_editable and GameplaySettings.script_show_add_inspector_input:
		var trash_button: Node = _TRASH_BUTTON.instantiate()
		param_scene.add_child(trash_button)
		trash_button.pressed.connect(_on_delete_parameter.bind(parameter_name))


func _on_parameter_changed(value, which: Control) -> void:
	var parameters_for_entry: Dictionary = _target_script_instance.entry_parameters[_entry_id]
	var param_name = which.label_text
	var param_data = parameters_for_entry[param_name]
	param_data[1] = value
	_target_script_instance.apply_inspector_parameter_values()
	_target_script_instance.script_instance_changed()


func _on_toggle_button_inspector_category_visibility_changed(new_visibility: bool) -> void:
	_add_input_button.visible = new_visibility and _is_editable and GameplaySettings.script_show_add_inspector_input


func _on_create_parameter(parameter_port_array: Array) -> void:
	for entry_block in _target_script_instance.script_builder.entry_blocks:
		if entry_block.entry_id == _entry_id:
			entry_block.parameters.create_inspector_parameter(parameter_port_array)
			entry_block.reset_entry_output_ports()
			break
	_target_script_instance.sync_script_inst_params_with_script_data()
	_target_script_instance.script_data_contents_changed()
	refresh_inspected_nodes.emit()


func _on_delete_parameter(parameter_name: String) -> void:
	for entry_block in _target_script_instance.script_builder.entry_blocks:
		if entry_block.entry_id == _entry_id:
			_target_script_instance.script_builder.disconnect_script_block_outputs(entry_block)
			entry_block.parameters.delete_inspector_parameter(parameter_name)
			entry_block.reset_entry_output_ports()
			break
	_target_script_instance.sync_script_inst_params_with_script_data()
	_target_script_instance.script_data_contents_changed()
	refresh_inspected_nodes.emit()
