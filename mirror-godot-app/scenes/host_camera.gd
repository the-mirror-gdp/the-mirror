# Responsible for movement of the camera on the server session, created for the purpose of helping
# with debugging networked code
extends Camera3D


const CAMERA_MOVEMENT_SPEED = 20.0
const MOUSE_SENSIVITY = 1.0

var rotation_input: RotationInput = RotationInput.new()


func _ready() -> void:
	var use_server_camera = ProjectSettings.get_setting("mirror/use_server_camera", false)
	var is_active = use_server_camera and Zone.is_host() and OS.is_debug_build()
	if not is_active:
		visible = false
		set_process(false)
		set_process_input(false)
		clear_current(false)
		return

	self.current = true
	_cleanup_inputs()


# removes conflicting inputs (inputs which are used only on the client)
func _cleanup_inputs():
	InputMap.action_erase_events(&"build_mode_toggle")
	InputMap.action_erase_events(&"inspect_mode_toggle")
	InputMap.action_erase_events(&"inspect_mode_exit")


func _input(event: InputEvent) -> void:
	rotation_input.process_input(event)


func _process(delta: float) -> void:
	_process_movement(delta)
	_process_rotation(delta)


func _process_movement(in_delta: float) -> void:
	var movement_input = _get_movement_input()
	var no_inputs = movement_input.is_equal_approx(Vector3())
	if no_inputs:
		return

	var input_world_direction = get_global_transform().basis * movement_input
	input_world_direction = input_world_direction.normalized()

	if Input.is_key_pressed(KEY_SHIFT):
		input_world_direction *= 5.0

	global_transform.origin += input_world_direction * CAMERA_MOVEMENT_SPEED * in_delta


static func _get_movement_input() -> Vector3:
	var movement_direction = Vector3.ZERO
	if Input.is_action_pressed(&"player_move_forward"):
		movement_direction.z = -1.0
	if Input.is_action_pressed(&"player_move_back"):
		movement_direction.z = 1.0
	if Input.is_action_pressed(&"player_move_left"):
		movement_direction.x = -1.0
	if Input.is_action_pressed(&"player_move_right"):
		movement_direction.x = 1.0
	# TODO use actions instead of the direct key
	if Input.is_key_pressed(KEY_E):
		movement_direction.y = 1.0
	if Input.is_key_pressed(KEY_Q):
		movement_direction.y = -1.0

	return movement_direction


func _process_rotation(in_delta: float) -> void:
	if not is_instance_valid(rotation_input):
		rotation_input = RotationInput.new()
		return
	var rotation_input_vect = rotation_input.get_rotation_input()
	rotation.x -= rotation_input_vect.x * in_delta * MOUSE_SENSIVITY
	rotation.y -= rotation_input_vect.y * in_delta * MOUSE_SENSIVITY


class RotationInput:
	var rotation_input: Vector2 = Vector2()
	var right_mouse_clicked: bool = false


	func init():
		pass


	func process_input(event: InputEvent):
		rotation_input = Vector2()
		if event is InputEventMouseButton:
			event = event as InputEventMouseButton
			right_mouse_clicked = event.button_index == MOUSE_BUTTON_RIGHT and event.is_pressed()
			if right_mouse_clicked:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

		if not right_mouse_clicked:
			return

		if event is InputEventMouseMotion:
			rotation_input.y = event.relative.x
			rotation_input.x = event.relative.y


	func get_rotation_input() -> Vector2:
		var output_vector := rotation_input
		rotation_input = Vector2()
		return output_vector
