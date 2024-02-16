extends PanelContainer


@onready var _label = $MarginContainer/Label

var _fade_delay: float = 5.0
var _fade_speed: float = 0.5
var _time_since_said: float = 0.0


func _process(delta: float) -> void:
	_time_since_said += delta
	if _time_since_said < _fade_delay:
		return
	if modulate.a <= 0.0:
		queue_free()
	modulate.a -= delta * _fade_speed


func set_text(text: String) -> void:
	_label.text = text


func set_text_size(size: int) -> void:
	_label.label_settings.font_size = size
