extends BaseSetting


@onready var _color_picker = $InspectorPropertyColor


func apply_setting_to_ui(_value: Color) -> void:
	_color_picker.current_value = _value
	apply_setting_to_gameplay()


func apply_setting_to_gameplay() -> void:
	GameplaySettings.crosshair_color = _color_picker.current_value


func convert_gameplay_value_for_ui() -> Color:
	return GameplaySettings.crosshair_color
