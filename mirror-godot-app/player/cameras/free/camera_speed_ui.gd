extends Label


@onready var _camera_speed_label: Label = $MarginContainer/Label


func _process(delta: float) -> void:
	visible = not GameUI.is_cinematic_mode_enabled()
	var safe_area: Rect2 = GameUI.get_safe_area()
	position = safe_area.position + Vector2(20.0, safe_area.size.y - 60.0)
	modulate.a -= delta * 0.5
	if modulate.a < 0.0:
		modulate.a = 0.0


func _on_scroll_speed_changed(value: float) -> void:
	modulate.a = 1.0
	text = "Speed: %sm/s" % _metric_number_to_friendly_string(value)


func _metric_number_to_friendly_string(number: float) -> String:
	if number < 0.1:
		return "%1.1f m" % (number * 1000.0)
	elif number < 2.0:
		return "%1.0f m" % (number * 1000.0)
	elif number < 100.0:
		return "%1.1f " % number
	elif number < 2000.0:
		return "%1.0f " % number
	elif number < 100000.0:
		return "%1.1f k" % (number * 0.001)
	else:
		return "%1.0f k" % (number * 0.001)
