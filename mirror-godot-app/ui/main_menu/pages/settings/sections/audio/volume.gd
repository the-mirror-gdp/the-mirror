extends BaseSetting


@onready var _number_slider = $InspectorNumberSlider


func apply_setting_to_ui(value):
	_number_slider.current_value = value
	_number_slider.refresh()
	apply_setting_to_gameplay()


func convert_gameplay_value_for_ui() -> float:
	return db_to_linear(GameplaySettings.sound_volume_db) * 100.0


func apply_setting_to_gameplay() -> void:
	GameplaySettings.sound_volume_db = linear_to_db(_number_slider.current_value / 100.0)
