extends BaseSetting

@onready var _number_slider = $InspectorSlider


func _ready():
	GameplaySettings.concurrent_downloads_changed.connect(update_ui_scale)
	_number_slider.min_value = GameplaySettings.MIN_HTTP_REQUESTS
	_number_slider.max_value = GameplaySettings.MAX_HTTP_REQUESTS
	_number_slider.reset_value = 20
	super()


func update_ui_scale(value: int) -> void:
	_number_slider.current_value = value
	_number_slider.refresh_full()


func apply_setting_to_ui(value) -> void:
	_number_slider.current_value = value
	# Do the rest of the applying, update the menu and scale the UI.
	apply_setting_to_gameplay()


func apply_setting_to_gameplay() -> void:
	GameplaySettings.concurrent_http_requests = _number_slider.current_value


func convert_gameplay_value_for_ui():
	return GameplaySettings.concurrent_http_requests
