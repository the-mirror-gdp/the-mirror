extends Control


signal value_dropped(value)

var drop_enabled: bool = true


func _can_drop_data(_position: Vector2, data) -> bool:
	return drop_enabled and data.has("string_to_drop")


func _drop_data(_position: Vector2, data) -> void:
	if data.has("string_to_drop"):
		value_dropped.emit(data["string_to_drop"])
