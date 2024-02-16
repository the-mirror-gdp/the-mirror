extends BaseSetting


const MIN_SLIDER = 0.6
const MAX_SLIDER = 1.5

@onready var _number_slider = $InspectorNumberSlider


func _ready() -> void:
	GameplaySettings.ui_scale_changed.connect(update_ui_slider)
	super()


func is_value_valid(value: Variant) -> bool:
	return value is float and value > 0.2 and value < 8.0


func apply_setting_to_ui(value) -> void:
	# For this specific slider, since it resizes the UI, we should
	# instantly release the mouse when someone clicks on the slider.
	var input_event = InputEventMouseButton.new()
	input_event.button_index = MOUSE_BUTTON_LEFT
	Input.parse_input_event(input_event)
	# Also specific to the UI slider, adjust the min/max to limit to allowed values.
	var base_res := Vector2(1920, 1080)
	var window_size: Vector2 = get_viewport().size
	var scale: float = min(window_size.x / base_res.x, window_size.y / base_res.y)
	# calculate minum scale for window, in which font be readable
	var min_slider: float = max(min(MIN_SLIDER / scale, 1.0), MIN_SLIDER)
	_number_slider.min_value = min_slider
	_number_slider.max_value = MAX_SLIDER
	# Do the rest of the applying, update the menu and scale the UI.
	apply_setting_to_gameplay()


func apply_setting_to_gameplay() -> void:
	GameplaySettings.ui_scale = _number_slider.current_value


func convert_gameplay_value_for_ui():
	return GameplaySettings.ui_scale


func update_ui_slider(scale: float):
	_number_slider.current_value = scale
	_number_slider.refresh_full()
