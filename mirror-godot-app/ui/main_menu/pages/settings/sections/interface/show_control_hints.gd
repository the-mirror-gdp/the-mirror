extends BaseSetting

@onready var bool_ui = $InspectorPropertyBool


func apply_setting_to_ui(_value: bool) -> void:
	bool_ui.current_value = _value
	apply_setting_to_gameplay()


func apply_setting_to_gameplay()-> void:
	GameplaySettings.show_floating_control_hints = bool_ui.current_value


func convert_gameplay_value_for_ui() -> bool:
	return GameplaySettings.show_floating_control_hints
