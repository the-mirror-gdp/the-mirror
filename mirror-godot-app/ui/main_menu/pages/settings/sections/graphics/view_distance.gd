extends BaseSetting


@onready var _number_slider = $InspectorNumberSlider


func apply_setting_to_ui(value) -> void:
	_number_slider.min_value = GameplaySettings.MIN_VIEW_DISTANCE
	_number_slider.max_value = GameplaySettings.MAX_VIEW_DISTANCE
	# Do the rest of the applying, update the menu and scale the UI.
	_number_slider.current_value = value
	_number_slider.refresh_full()

	apply_setting_to_gameplay()


func apply_setting_to_gameplay() -> void:
	GameplaySettings.view_distance = _number_slider.current_value


func convert_gameplay_value_for_ui():
	return GameplaySettings.view_distance
