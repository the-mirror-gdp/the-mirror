class_name PlayerHeadCamera
extends CameraHolder


enum CameraPerspective
{
	FIRST_PERSON,
	THIRD_PERSON,
}

@onready var _first_person_camera: Camera3D = %FirstPersonCamera
@onready var equipable_view_model: EquipableViewModel = %EquipableViewModel
@onready var _third_person_camera_arm: Node3D = %ThirdPersonCameraArm
@onready var _third_person_camera: Camera3D = %ThirdPersonCamera
@onready var _camera_recoil_offset: Node3D = %CameraRecoilOffset

var _default_fov: float = 75.0
var _camera_zoom_speed: float = 12.0
var _camera_drop_speed: float = 4.0
var _was_in_first_person_before_entering_vr: bool = false
var _perspective_locked: bool = false
var _default_perspective: CameraPerspective = CameraPerspective.THIRD_PERSON


func _process(delta: float) -> void:
	if VRManager.vr_is_active:
		return
	var camera_rotation: Vector2 = _local_player.get_intended_camera_rotation_change()
	if camera_rotation:
		if _third_person_camera_arm.is_second_person:
			camera_rotation.x *= -1.0
		clamped_camera_rotation(camera_rotation)
	_camera_recoil_offset.transform = _camera_recoil_offset.transform.interpolate_with(Transform3D.IDENTITY, delta * 10.0)


func setup(player: TMCharacter3D, camera_manager: CameraManager, gizmo: Gizmo) -> void:
	_default_fov = _camera.fov
	_local_player = player
	_first_person_camera.setup(camera_manager, gizmo)
	_third_person_camera.setup(camera_manager, gizmo)
	player.vr_controller.vr_started.connect(_on_vr_enter)
	player.vr_controller.vr_ended.connect(_on_vr_exit)
	Zone.mode_changed.connect(_on_zone_mode_changed)
	Zone.script_network_sync.variables_ready.connect(_space_vars_loaded)
	Zone.script_network_sync.global_variable_changed.connect(_space_var_updated)


func update(in_delta: float) -> void:
	super.update(in_delta)
	if _local_player.damage_handler.get_health() <= 0.0:
		var height: float = _local_player.global_position.y + (_local_player.get_player_height_meters() * 0.1)
		global_position.y = lerpf(global_position.y, height, in_delta * _camera_drop_speed)
		return
	if VRManager.vr_is_active and _camera == _first_person_camera:
		global_transform = _local_player.get_vr_camera().global_transform
	else:
		global_position = _local_player.get_global_eyes_position()
	_third_person_camera_arm.update_camera_arm_run_zoom(_local_player)
	var can_zoom: bool = _local_player.equipable_controller.is_current_equipable_aiming() and not _local_player.is_intent_to_run()
	_camera.fov = lerpf(_camera.fov, _default_fov * 0.8 if can_zoom else _default_fov, _camera_zoom_speed * in_delta)


func handle_input(input_event: InputEvent):
	if input_event.is_action_pressed(&"player_change_camera") and not _perspective_locked:
		if _camera == _third_person_camera:
			_set_active_camera(_first_person_camera)
		else:
			_set_active_camera(_third_person_camera)
		return
	if _camera == _third_person_camera:
		_third_person_camera_arm.handle_input(input_event, _local_player)


func enter(target_transform: Transform3D) -> void:
	var back: Vector3 = target_transform.basis.z
	basis = Basis.looking_at(back if _third_person_camera_arm.is_second_person else -back)
	position = _local_player.get_global_eyes_position()
	_refresh_camera()


func exit() -> void:
	_camera.clear_current(false)
	_set_is_camera_first_person(false)


func get_next_camera_target_transform() -> Transform3D:
	return _third_person_camera.global_transform


func set_camera_zoom_scale(camera_zoom_scale: float) -> void:
	_first_person_camera.set_camera_zoom_scale(camera_zoom_scale)
	_third_person_camera_arm.set_camera_zoom_scale(camera_zoom_scale)


func set_collide_with_object(collision_object: CollisionObject3D, is_enabled: bool) -> void:
	if is_enabled:
		_third_person_camera_arm.remove_excluded_object(collision_object.get_rid())
	else:
		_third_person_camera_arm.add_excluded_object(collision_object.get_rid())


func _activate_current_camera() -> void:
	_camera.make_current()
	_camera.fov = _default_fov
	_set_is_camera_first_person(_camera == _first_person_camera)
	rotation.z = 0.0


func _set_active_camera(camera_node: Camera3D) -> void:
	_camera = camera_node
	_activate_current_camera()


func _set_camera_based_on_perspective() -> void:
	match _default_perspective:
		CameraPerspective.FIRST_PERSON:
			_camera = _first_person_camera
		CameraPerspective.THIRD_PERSON:
			_camera = _third_person_camera
	_activate_current_camera()


func _refresh_camera() -> void:
	if not GameUI.instance.creator_ui.is_game_mode(GameMode.Mode.NORMAL) and not Zone.is_in_play_mode():
		return
	if _perspective_locked:
		_set_camera_based_on_perspective()
		return
	_activate_current_camera()


func add_camera_punch(camera_punch: float) -> void:
	_camera_recoil_offset.position += Vector3(randf(), randf(), 0.0) * camera_punch
	var rand_pitch_yaw = Vector3(randf(), randf(), 0.0) * camera_punch
	_camera_recoil_offset.basis = Basis.from_euler(rand_pitch_yaw) * _camera_recoil_offset.basis


func _set_is_camera_first_person(is_first_person: bool) -> void:
	if is_first_person:
		_local_player.show_shadow_hide_player()
		_local_player.social_ui.hide_social()
		_local_player.model.equipable_world_model.hide()
		equipable_view_model.show()
		_third_person_camera_arm.is_second_person = false
	else:
		_local_player.show_player_and_shadow()
		_local_player.social_ui.show_social()
		_local_player.model.equipable_world_model.show()
		equipable_view_model.hide()


# Mirror the VR camera to desktop
func _on_vr_enter() -> void:
	_was_in_first_person_before_entering_vr = ( _camera == _first_person_camera )
	_set_active_camera(_first_person_camera)


func _on_vr_exit() -> void:
	if _was_in_first_person_before_entering_vr:
		_set_active_camera(_first_person_camera)
	else:
		_set_active_camera(_third_person_camera)


# Perspective Locking
func _set_camera_lock_perspective() -> void:
	var locked = Zone.script_network_sync.get_global_variable("camera_is_perspective_locked")
	if locked is bool:
		_perspective_locked = locked
		return
	# Default to unlocked.
	Zone.script_network_sync.set_global_variable("camera_is_perspective_locked", false)


func _set_camera_default_perspective() -> void:
	var perspective = Zone.script_network_sync.get_global_variable("camera_default_perspective")
	if perspective is int or perspective is float:
		_default_perspective = perspective as CameraPerspective
		return
	# Default to third-person.
	Zone.script_network_sync.set_global_variable("camera_default_perspective", CameraPerspective.THIRD_PERSON)


func _on_zone_mode_changed(_new_zone_mode) -> void:
	# Set to default perspective when we enter play mode.
	_set_camera_based_on_perspective()


func _space_var_updated(variable_name: String, _variable_value: Variant) -> void:
	if variable_name in ["camera_default_perspective", "camera_is_perspective_locked"]:
		_update_camera_perspective_vars()
		_refresh_camera()


func _space_vars_loaded() -> void:
	_update_camera_perspective_vars()
	# Used when the player initally joins a space and spawns.
	_set_camera_based_on_perspective()


func _update_camera_perspective_vars() -> void:
	_set_camera_lock_perspective()
	_set_camera_default_perspective()
