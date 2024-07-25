extends KeyboardGrabbingConfirmationDialog


signal request_variable_editor_refresh()

var _variable_node_path: NodePath

@onready var _variable_creation_menu: Control = $VariableCreationMenu


func open_creation_dialog(node_path: NodePath = ^""):
	_variable_creation_menu.clear_fields()
	_variable_node_path = node_path
	if _variable_node_path == ^"":
		title = tr("Create Global Variable")
	else:
		title = tr("Create Variable on '%s'" % node_path)
	_variable_node_path = ^""
	popup_centered()
	GameUI.instance.grab_input_lock(self)


func _on_confirmed() -> void:
	var variable_array = _variable_creation_menu.get_variable_array()
	if variable_array[0].is_empty():
		Notify.error("Unable to create variable", "Variable name cannot be empty.")
		return
	if _variable_node_path.is_empty():
		Zone.script_network_sync.set_global_variable(variable_array[0], variable_array[2])
	else:
		Zone.script_network_sync.set_variable_on_node_at_path(_variable_node_path, variable_array[0], variable_array[2])
	_variable_creation_menu.clear_fields()
	hide()
	request_variable_editor_refresh.emit()


func _ready():
	get_cancel_button().theme_type_variation = &"ButtonAccent"
