class_name DraggableTree
extends Tree


var _ready_to_drag: bool = false
var _drag_from: Vector2
var _mouse_position: Vector2


func _process(_delta: float) -> void:
	if not Input.is_action_pressed(&"primary_action"):
		_ready_to_drag = false


func _gui_input(input_event: InputEvent) -> void:
	if input_event is InputEventMouseMotion:
		_mouse_position = input_event.position
		if _ready_to_drag and _mouse_position.distance_squared_to(_drag_from) > 10.0:
			_try_begin_dragging()
			_ready_to_drag = false
	elif input_event.is_action(&"primary_action"):
		_ready_to_drag = input_event.pressed
		_drag_from = _mouse_position


func _try_begin_dragging() -> void:
	var drag_data: Variant = _get_drag_data(_drag_from)
	if drag_data == null:
		return
	var drag_preview := TextureRect.new()
	drag_preview.set_expand_mode(TextureRect.EXPAND_IGNORE_SIZE)
	drag_preview.size = Vector2(64, 64)
	drag_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	drag_preview.texture = _get_drag_icon()
	force_drag(drag_data, drag_preview)


func _get_drag_icon(_drag_position := Vector2.ZERO) -> Texture2D:
	assert(false)
	return null
