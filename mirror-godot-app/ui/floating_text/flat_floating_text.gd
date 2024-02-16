extends Control


var target_position := Vector2.ZERO

@onready var _label = $Label


func _process(delta: float) -> void:
	position = position.lerp(target_position, 0.9)
	if modulate.a < 0.0:
		queue_free()
	modulate.a -= minf(delta * 40.0, 0.5)


func setup(text: String, initial_pos: Vector2) -> void:
	_label.text = text
	position = initial_pos
	target_position = initial_pos


func get_text() -> String:
	return _label.text
