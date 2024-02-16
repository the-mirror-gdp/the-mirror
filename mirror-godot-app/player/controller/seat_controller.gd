class_name SeatController
extends Node


const _ROTATE_180_XZ_BASIS := Basis(Vector3.LEFT, Vector3.UP, Vector3.FORWARD)

var _player: Player = null
var _movement_controller: PlayerMovementController = null

var _current_seat: Node3D = null
var _omi_seat: Dictionary = {}
var _can_leave_seat: bool = true
var _is_local: bool = false


var is_changing_sitting_state = false:
	set(value):
		is_changing_sitting_state = value
		await get_tree().process_frame
		await get_tree().process_frame
		is_changing_sitting_state = false


func setup(player: Player, movement_controller: PlayerMovementController, is_local: bool) -> void:
	_player = player
	_movement_controller = movement_controller
	_is_local = is_local


func _process(delta: float) -> void:
	# If not sitting, return. If the seat is invalid, get off it, and return.
	if _current_seat == null:
		return
	elif not is_instance_valid(_current_seat) or not _current_seat.is_inside_tree():
		get_off_seat()
		return

	# The seat is valid. Set the player's rotation to be on the seat.
	var global_ortho: Transform3D = _current_seat.global_transform.orthonormalized()
	var local_rot := Basis.looking_at(_omi_seat.get("upper_leg_dir"), _omi_seat.get("upper_leg_norm"))
	_player.set_model_global_basis(global_ortho.basis * local_rot)

	# Set the player's position to be on the seat.
	var seat_knee: Vector3 = _omi_seat.get("knee") * _current_seat.global_transform.basis.get_scale()
	var player_knee: Vector3 = _player.model.get_knee_pose_position() * _player.scale
	var local_sit_pos: Vector3 = seat_knee - (local_rot * _ROTATE_180_XZ_BASIS) * player_knee
	_player.position = global_ortho * local_sit_pos


func player_interact(interaction_target: Node) -> void:
	# NOTE: This code needs to handle a lot of things, including the same seat,
	# other seats, parents of seats, non-seats, and null. Please don't touch :)
	var target_seat: Node3D = get_seat_node(interaction_target)
	if interaction_target == null or target_seat == _current_seat:
		if _current_seat != null and _can_leave_seat:
			is_changing_sitting_state = true
			get_off_seat()
	elif target_seat != null:
		is_changing_sitting_state = true
		_try_sit_on_valid_seat(target_seat)


func _is_trigger_jbody(jbody: Node) -> bool:
	return jbody is JBody3D and jbody.is_sensor()


func get_seat_node(target: Node) -> Node3D:
	if target == null:
		return null
	# If this is already a seat, use that.
	if _is_trigger_jbody(target) and target.has_meta(&"OMI_seat"):
		return target
	# Else, look for seat nodes, and return one if it is not a trigger body.
	# This allows interacting with a SpaceObject seat without a trigger body.
	# See https://github.com/the-mirror-megaverse/mirror-godot-app/pull/1385#discussion_r1228323905
	var seats: Array = Util.recursive_find_nodes_with_meta(target, &"OMI_seat")
	for seat in seats:
		if not _is_trigger_jbody(seat):
			return seat
	return null


func get_current_seat() -> Node3D:
	if _current_seat:
		if is_instance_valid(_current_seat):
			return _current_seat
		get_off_seat()
	return null


func try_sit_on_seat(seat_node: Node3D) -> void:
	if seat_node:
		_try_sit_on_valid_seat(seat_node)
	else:
		get_off_seat()


func _try_sit_on_valid_seat(seat_node: Node3D) -> void:
	if _is_any_player_on_seat(seat_node):
		return
	if _current_seat != null:
		# This case runs when already sitting and trying to sit on a different seat.
		_enable_player_collision(true)
		_current_seat.emit_signal(&"player_unsit_here", _player)
	_current_seat = seat_node
	_omi_seat = seat_node.get_meta(&"OMI_seat")
	_enable_player_collision(false)
	_player.set_body_mode(JBody3D.STATIC)
	if _is_local:
		var look_dir: Vector3 = _current_seat.global_transform.basis * _omi_seat.get("upper_leg_dir")
		var look_angle: float = Vector2(look_dir.z, look_dir.x).angle() + PI
		_player.camera_set_rotation_y(look_angle)
		_player.set_frozen(true)
		if VRManager.vr_is_active:
			_player.vr_controller.origin_set_rotation_y(look_angle)
	_current_seat.emit_signal(&"player_sit_here", _player)


func get_off_seat() -> void:
	if not is_instance_valid(_player):
		return
	if is_instance_valid(_current_seat):
		var local_offset: Vector3 = _omi_seat.get("upper_leg_dir") * (_player.scale.y * 1.5)
		var global_ortho_basis: Basis = _current_seat.global_transform.basis.orthonormalized()
		_player.position += global_ortho_basis * local_offset
		_enable_player_collision(true)
		_player.set_body_mode(JBody3D.KINEMATIC)
		_player.set_frozen(false)
		_current_seat.emit_signal(&"player_unsit_here", _player)
	_current_seat = null


func _is_any_player_on_seat(target_seat: Node3D) -> bool:
	for player in Zone.social_manager.get_all_players():
		var seat = player.get_current_seat()
		if seat == target_seat:
			# If the player we find is ourself, return true but don't print an error message.
			if player != _player:
				Notify.error("Unable to sit", "Seat is already occupied.")
			return true
	return false


func _enable_player_collision(is_enabled: bool) -> void:
	var layer_name: String = "CHARACTER" if is_enabled else "NO_COLLIDE"
	_player.set_layer_name(layer_name)
