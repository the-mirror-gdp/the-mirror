extends KeyboardGrabbingConfirmationDialog


signal request_variable_editor_refresh()

var _primitive_value_editor: HBoxContainer
var _variable_name: String
var _variable_value: Variant
var _variable_node_path: NodePath


func edit_variable_value(variable_name: String, current_value: Variant, node_path: NodePath = ^"") -> void:
	if _primitive_value_editor:
		_cleanup()
	_variable_name = variable_name
	_variable_node_path = node_path
	_variable_value = current_value
	title = "Edit '" + _variable_name + "' Value"
	# Set up an editor for the variable's value depending on its type.
	var variable_type: int = typeof(_variable_value)
	var inspector_prim_scenes = ScriptParameterCreationMenu.INSPECTOR_PRIMITIVE_SCENES
	if not variable_type in inspector_prim_scenes:
		Notify.error("Unable to edit", "Can't edit a value of this type.")
		return
	var editor_scene: PackedScene = ScriptParameterCreationMenu.INSPECTOR_PRIMITIVE_SCENES[variable_type]
	_primitive_value_editor = editor_scene.instantiate()
	_primitive_value_editor.label_text = _variable_name
	# Be careful, the order matters here! Value editors with setters
	# that use onready vars can only be used after adding as a child,
	# and then we need to refresh if a refresh method exists.
	add_child(_primitive_value_editor)
	_primitive_value_editor.current_value = _variable_value
	if _primitive_value_editor.has_method(&"refresh"):
		_primitive_value_editor.refresh()
	popup_centered()


func cleanup_and_close() -> void:
	_cleanup()
	hide()


func _cleanup() -> void:
	if _primitive_value_editor:
		_primitive_value_editor.cleanup_and_delete()
		_primitive_value_editor = null


func _on_confirmed() -> void:
	_variable_value = _primitive_value_editor.current_value
	if _variable_node_path.is_empty():
		Zone.script_network_sync.set_global_variable(_variable_name, _variable_value)
	else:
		Zone.script_network_sync.set_variable_on_node_at_path(_variable_node_path, _variable_name, _variable_value)
	_cleanup()
	request_variable_editor_refresh.emit()


func _ready():
	get_cancel_button().theme_type_variation = &"ButtonAccent"
