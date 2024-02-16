extends HBoxContainer


@export var value: float:
	set(x):
		value = x
		if is_instance_valid(_progress_bar):
			_progress_bar.value = x
			_update()
@export var min_value: float:
	set(x):
		min_value = x
		if is_instance_valid(_progress_bar):
			_progress_bar.min_value = min_value
			_update()
@export var max_value: float:
	set(x):
		max_value = x
		if is_instance_valid(_progress_bar):
			_progress_bar.max_value = max_value
			_update()

@onready var _progress_bar = $progress_bar
@onready var _value_label = $value_label


func _colors_update():
	var stylebox = _progress_bar.get_theme_stylebox("fill")
	var ratio: float = clamp((value - min_value) / (max_value - min_value), 0.0, 1.0)
	stylebox.bg_color = Color.from_hsv((1.0 - ratio * ratio) / 3.0, 1.0, 1.0)


func _ready():
	var stylebox = _progress_bar.get_theme_stylebox("fill")
	_progress_bar.add_theme_stylebox_override("fill", stylebox.duplicate())
	_update()


func _on_progress_bar_value_changed(value):
	_update()


func _update():
	_colors_update()
	_value_label.text = "%d/%d" % [value, max_value]
