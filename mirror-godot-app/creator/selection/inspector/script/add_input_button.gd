extends Button


signal create_parameter(parameter_port_array: Array)

@onready var _add_input_dialog = $AddInputDialog
@onready var _variable_creation_menu = $AddInputDialog/VariableCreationMenu


func _on_pressed() -> void:
	_variable_creation_menu.clear_fields()
	_add_input_dialog.popup_centered()
	GameUI.grab_input_lock(self)
	_variable_creation_menu.focus_variable_editor_name_field()


func emit_create_parameter() -> void:
	var parameter_port_array: Array = _variable_creation_menu.get_variable_array()
	if String(parameter_port_array[0]).is_empty():
		Notify.error("Unable to create parameter", "Parameter name cannot be empty.")
		return
	create_parameter.emit(parameter_port_array)
	_add_input_dialog.hide()


func _on_add_input_dialog_focus_entered() -> void:
	GameUI.grab_input_lock(self)


func _on_add_input_dialog_focus_exited() -> void:
	GameUI.release_input_lock(self)
