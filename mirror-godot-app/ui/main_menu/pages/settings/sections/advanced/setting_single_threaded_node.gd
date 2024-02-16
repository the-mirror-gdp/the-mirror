extends BaseSetting

@onready var bool_ui = $InspectorPropertyToggle


func apply_setting_to_ui(_value: bool):
	bool_ui.current_value = _value
	apply_setting_to_gameplay()


func apply_setting_to_gameplay()-> void:
	GameplaySettings.force_single_threaded_mode = bool_ui.current_value


func convert_gameplay_value_for_ui() -> bool:
	return GameplaySettings.force_single_threaded_mode
