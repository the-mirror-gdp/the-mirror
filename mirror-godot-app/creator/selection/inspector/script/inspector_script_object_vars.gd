extends InspectorCategoryBase


const _TRASH_BUTTON = preload("res://creator/selection/inspector/script/entry_input_trash_button.tscn")

var target_node: Node # SpaceObject or SpaceGlobalScripts
var _is_editable: bool = false
var _object_vars: Dictionary
var _property_list: Control


## Must run before _ready()
func setup(target_object: Node, is_editable: bool) -> void:
	target_node = target_object
	_property_list = $Properties/MarginContainer/PropertyList
	_is_editable = is_editable


func setup_object_vars(object_vars: Dictionary) -> void:
	_object_vars = object_vars
	for obj_var_name in _object_vars:
		_setup_object_var(obj_var_name, _object_vars[obj_var_name])
	if _property_list.get_child_count() < 5:
		if _property_list.get_child_count() != 0:
			$CategoryTitle/ToggleButton.hover_tooltip_text = ""
			set_visible_to_maximum_size()


func _setup_object_var(obj_var_name: String, obj_var_value: Variant) -> void:
	var obj_var_type: int = typeof(obj_var_value)
	if obj_var_type == TYPE_NIL or not obj_var_type in ScriptParameterCreationMenu.INSPECTOR_PRIMITIVE_SCENES:
		return
	var obj_var_scene = ScriptParameterCreationMenu.INSPECTOR_PRIMITIVE_SCENES[obj_var_type].instantiate()
	obj_var_scene.label_text = obj_var_name
	obj_var_scene.reset_value = Serialization.type_convert_any(_get_default_value_of_obj_var(obj_var_name), obj_var_type)
	# Be careful, the order matters here! Value editors with setters
	# that use onready vars can only be used after adding as a child,
	# and then we need to refresh if a refresh method exists.
	_property_list.add_child(obj_var_scene)
	obj_var_scene.current_value = obj_var_value
	if obj_var_scene.has_method(&"refresh"):
		obj_var_scene.refresh()
	obj_var_scene.value_changed.connect(_on_object_var_changed.bind(obj_var_scene))
	if _is_editable and GameplaySettings.script_show_add_inspector_input:
		var trash_button: Node = _TRASH_BUTTON.instantiate()
		obj_var_scene.add_child(trash_button)
		trash_button.pressed.connect(_on_delete_object_var.bind(obj_var_name))


func _on_object_var_changed(value, which: Control) -> void:
	var obj_var_name: String = which.label_text
	Zone.script_network_sync.set_variable_on_node(target_node, obj_var_name, value)


func _on_delete_object_var(obj_var_name: String) -> void:
	Zone.script_network_sync.set_variable_on_node(target_node, obj_var_name, null)
	for child in _property_list.get_children():
		child.cleanup_and_delete()
		_property_list.remove_child(child)
	var vars = target_node.get_meta(&"MirrorScriptObjectVariables")
	vars.erase(obj_var_name)
	setup_object_vars(vars)


func _get_default_value_of_obj_var(obj_var_name: String) -> Variant:
	var script_instances: Array[ScriptInstance] = target_node.get_script_instances()
	for script_inst in script_instances:
		if script_inst.has_method(&"get_default_value_of_exposed_variable"):
			var def = script_inst.get_default_value_of_exposed_variable(obj_var_name)
			if def != null:
				return def
	return null
