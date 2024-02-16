extends BaseSetting


@onready var _number_slider = $InspectorSlider


func refresh_ui():
	super.refresh_ui()
	_number_slider.enabled = !GameplaySettings.auto_performance


func apply_setting_to_ui(value) -> void:
	_number_slider.current_value = value
	_number_slider.refresh()
	apply_setting_to_gameplay()


func apply_setting_to_gameplay() -> void:
	GameplaySettings.resolution_scale = _number_slider.current_value


func convert_gameplay_value_for_ui() -> float:
	return GameplaySettings.resolution_scale
