extends HBoxContainer


signal value_changed(value: int)

@export var current_value: int = 0:
	set = _set_current_value

@onready var _stars: Array = [
	$RateButton1, $RateButton2, $RateButton3, $RateButton4, $RateButton5
]


func _set_current_value(value: int) -> void:
	current_value = value
	for index in _stars.size():
		_stars[index].set_pressed_no_signal(index <= value - 1)


func _button_pressed(index: int) -> void:
	var new_value = index + 1
	if new_value == current_value:
		current_value = 0
	else:
		current_value = new_value
	value_changed.emit(current_value)


func _button_hover_start(value: int) -> void:
	for index in _stars.size():
		_stars[index].set_pressed_no_signal(index <= value)


func _button_hover_end() -> void:
	_set_current_value(current_value)


func _ready() -> void:
	for index in _stars.size():
		_stars[index].set_pressed_no_signal(false)
		_stars[index].pressed.connect(_button_pressed.bind(index))
		_stars[index].mouse_entered.connect(_button_hover_start.bind(index))
		_stars[index].mouse_exited.connect(_button_hover_end)
