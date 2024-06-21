extends OpenXRCompositionLayerQuad

const NO_INTERSECTION = Vector2(-1.0, -1.0)

@onready var controller : XRController3D = $"../LeftHand"
@onready var pointer = $"../Pointer"
@export var button_action : String = "trigger_click"

var was_pressed : bool = false
var was_intersect : Vector2 = NO_INTERSECTION

func _intersect_to_global_pos(intersect : Vector2) -> Vector3:
	if intersect != NO_INTERSECTION:
		var local_pos : Vector2 = (intersect - Vector2(0.5, 0.5)) * quad_size
		return global_transform * Vector3(local_pos.x, -local_pos.y, 0.0)
	else:
		return Vector3()


func _intersect_to_viewport_pos(intersect : Vector2) -> Vector2i:
	if layer_viewport and intersect != NO_INTERSECTION:
		var pos : Vector2 = intersect * Vector2(layer_viewport.size)
		return Vector2i(pos)
	else:
		return Vector2i(-1, -1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Hide our pointer, we'll make it visible if we're interacting with the viewport.
	pointer.visible = false

	if controller and layer_viewport:
		var controller_t : Transform3D = controller.global_transform
		var intersect : Vector2 = intersects_ray(controller_t.origin, -controller_t.basis.z)
		if intersect != NO_INTERSECTION:
			# DisplayServer.virtual_keyboard_show("test")
			var is_pressed : bool = controller.is_button_pressed(button_action)
			# Place our pointer where we're pointing
			var pos : Vector3 = _intersect_to_global_pos(intersect)
			pointer.visible = true
			pointer.global_position = pos
			if was_intersect != NO_INTERSECTION and intersect != was_intersect:
				# Pointer moved
				var event : InputEventMouseMotion = InputEventMouseMotion.new()
				var from : Vector2 = _intersect_to_viewport_pos(was_intersect)
				var to : Vector2 = _intersect_to_viewport_pos(intersect)
				if was_pressed:
					event.button_mask = MOUSE_BUTTON_MASK_LEFT
				event.relative = to - from
				event.position = to
				layer_viewport.push_input(event)
			if not is_pressed and was_pressed:
				# Button was let go?
				var event : InputEventMouseButton = InputEventMouseButton.new()
				event.button_index = 1
				event.pressed = false
				event.position = _intersect_to_viewport_pos(intersect)
				layer_viewport.push_input(event)
			elif is_pressed and not was_pressed:
				# Button was pressed?
				var event : InputEventMouseButton = InputEventMouseButton.new()
				event.button_index = 1
				event.button_mask = MOUSE_BUTTON_MASK_LEFT
				event.pressed = true
				event.position = _intersect_to_viewport_pos(intersect)
				layer_viewport.push_input(event)
				
			else:
				was_pressed = false
				was_intersect = NO_INTERSECTION
			was_pressed = is_pressed
			was_intersect = intersect
