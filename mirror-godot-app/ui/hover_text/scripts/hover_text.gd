extends PanelContainer


const _TEXT_OFFSET: Vector2 = Vector2(0.0, 24.0)

@onready var _primary_label: Label = $MarginContainer/VBoxContainer/PrimaryText
@onready var _secondary_label: Label = $MarginContainer/VBoxContainer/SecondaryText


func _process(_delta: float) -> void:
	var desired_pos: Vector2 = get_viewport().get_mouse_position() + _TEXT_OFFSET
	var furthest: Vector2 = get_viewport().get_visible_rect().size - size
	desired_pos = desired_pos.clamp(Vector2.ZERO, furthest)
	position = desired_pos


func set_text(primary_text: String, secondary_text: String = "") -> void:
	_primary_label.text = primary_text
	_secondary_label.text = secondary_text
	_secondary_label.visible = not secondary_text.is_empty()
	if primary_text.length() < 100 and secondary_text.length() < 120:
		_primary_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		_secondary_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		size = Vector2.ZERO
	else:
		_primary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_secondary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		size = Vector2(500.0, 0.0)
		# When enabling autowrap we need to set the size twice.
		await get_tree().process_frame
		size = Vector2(500.0, 0.0)
