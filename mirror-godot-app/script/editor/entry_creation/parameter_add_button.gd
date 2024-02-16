extends Button


signal request_parameter_creation(param_array: Array)

@export var dialog_title_text: String = "Add Parameter"

@onready var _parameter_creation_dialog: ConfirmationDialog = $ParameterCreationDialog
@onready var _parameter_creation_menu: Control = $ParameterCreationDialog/ParameterCreationMenu


func _ready() -> void:
	_parameter_creation_dialog.title = dialog_title_text
	_parameter_creation_menu.theme = theme


func erase_type_from_option_button(data_type: int) -> void:
	_parameter_creation_menu.erase_type_from_option_button(data_type)


func _on_pressed() -> void:
	GameUI.grab_input_lock(self)
	_parameter_creation_dialog.popup_centered()


func _on_parameter_creation_dialog_confirmed() -> void:
	var param_array: Array = _parameter_creation_menu.get_variable_array()
	if String(param_array[0]).is_empty():
		Notify.error("Unable to create parameter", "Parameter must have a non-empty name.")
		_parameter_creation_dialog.popup_centered()
		return
	_parameter_creation_menu.clear_fields()
	request_parameter_creation.emit(param_array)


func _on_focus_entered():
	GameUI.grab_input_lock(self)


func _on_focus_exited():
	GameUI.release_input_lock(self)
