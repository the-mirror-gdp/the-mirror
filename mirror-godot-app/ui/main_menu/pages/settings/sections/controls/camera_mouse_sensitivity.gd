extends BaseSetting


@onready var _number_slider = $InspectorNumberSlider


func apply_setting_to_ui(value: float):
	_number_slider.current_value = value
	_number_slider.refresh()
	apply_setting_to_gameplay()


func apply_setting_to_gameplay()-> void:
	GameplaySettings.camera_mouse_sensitivity = _number_slider.current_value * 0.01


func convert_gameplay_value_for_ui() -> float:
	# We store radians per pixel, but since those numbers are
	# so small, for the UI we show centiradians per pixel.
	return GameplaySettings.camera_mouse_sensitivity * 100.0
