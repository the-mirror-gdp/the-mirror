extends Button


signal texture_dropped(texture_id: String)

@onready var preview = $Preview


func set_preview(texture: Texture2D) -> void:
	preview.texture = texture


func _can_drop_data(_at_position: Vector2, data) -> bool:
	return data.has("asset_id")


func _drop_data(_position, data) -> void:
	texture_dropped.emit(data["asset_id"])
