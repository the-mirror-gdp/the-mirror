class_name AnimationController
extends Node3D

signal avatar_changed()
signal footstep_animated(state_compatibility: float, leg: int)

class STANCE:
	const UNARMED: StringName = &"Unarmed"
	const PISTOL: StringName = &"Pistol"
	const RIFLE: StringName = &"Rifle"

# TODO Unify the STANCE with the STANCE_INT
const STANCE_INT = {
	Unarmed = 0,
	Pistol = 1,
	Rifle = 2
}

const _BASIS_ROT_180 = Basis(Vector3.LEFT, Vector3.UP, Vector3.FORWARD)

const _DEFAULT_MODEL: String = "res://player/character_models/astronaut/astronaut.tscn"
const _EYES_POSITION = Vector3(0, 1.7, 0)
const _EYES_POSITION_SITTING = Vector3(0, 1.35, 0)

var hips_height_meters: float = 1.0
var head_top_height_meters: float = 1.75
var scale_multiplier: float = 1.0: set = set_scale_multiplier
var stance: StringName = STANCE.UNARMED

@onready var _animation_player: AnimationPlayer = $AnimationPlayer
@onready var _animation_tree: AnimationTree = $AnimationTree
@onready var head_bone_node: Node3D = $PlayerHeadBone
@onready var right_hand_attachment: BoneAttachment3D = $RightHandAttachment
@onready var equipable_world_model: EquipableWorldModel = $RightHandAttachment/EquipableWorldModel

var _player: Player = null

var _skeleton: Skeleton3D
var _meshes: Array = []
var _shadow_cast_mode := GeometryInstance3D.ShadowCastingSetting.SHADOW_CASTING_SETTING_ON

var _is_avatar_locked: bool = false
var _avatar_url: String = ""
var _currently_loading_avatar: bool = false
var _try_loading_avatar_again_later: bool = false

var _animation_velocity := Vector2.ZERO

# TODO Rename those variables to be public in next PR.
var _movement: Vector2 = Vector2.ZERO
var _running: bool = false
var _grounded: bool = true
var _sitting: bool = false
var _dead: bool = false
var _look_target: Vector3 = Vector3.ZERO
var _is_aiming: bool = false

# These variables are used for the interpolation.
var target_location: Vector3 = Vector3.ZERO
var initial_location: Vector3 = Vector3.ZERO
var target_horizontal_rotation: float = 0.0
var initial_horizontal_rotation: float = 0.0
var initial_look_target: Vector3 = Vector3.ZERO
var target_look_target: Vector3 = Vector3.ZERO
var accumulated_delta: float = 0.0
var movement_delta: float = 0.0

@onready var _avatar: Node3D = $default_model


func setup(player: Player) -> void:
	_player = player
	if Zone.is_host() or not is_instance_valid(_player):
		return
	_player.equipable_controller.equipable_changed.connect(_on_equipable_changed)
	_player.equipable_controller.current_equipable_interacted.connect(_on_current_equipable_interacted)
	# In case of an issue with set_player_avatar_by_url make sure that default avatar is setup
	_set_default_avatar()


func _process(delta: float) -> void:
	if not is_instance_valid(_player):
		return

	_process_model_interpolation(delta)

	_set_animation(delta)
	if not _skeleton:
		return
	head_bone_node.transform = _get_bone_transform("Head").translated_local(Vector3(0.0, 0.08, 0.0))
	_set_body_look()
	_set_head_look()


func _process_model_interpolation(delta):
	if movement_delta <= 0.0001:
		# Nothing to interpolate
		return

	accumulated_delta += delta * 0.4
	var alpha: float = accumulated_delta / movement_delta
	if alpha >= 1.0:
		alpha = 1.0
		# Stop processing
		movement_delta = 0.0
		accumulated_delta = 0.0

	# Smoothly update the Origin, Basis, Look target
	global_transform.origin = lerp(initial_location, target_location, alpha)
	if not _sitting:
		set_model_global_basis(Basis(Vector3(0, 1, 0), lerp_angle(initial_horizontal_rotation, target_horizontal_rotation, alpha)))
	_look_target = lerp(initial_look_target, target_look_target, alpha)


func update_character_status(in_movement_delta: float, location: Vector3, in_horizontal_rotation: float, in_vertical_rotation: float):
	# Clamp is needed to avoid overshot that would cause the character body to flip upside down.
	in_vertical_rotation = clamp(in_vertical_rotation, -(PI - (PI * 0.6)), PI - (PI * 0.6))

	var player_camera_view := Basis.from_euler(Vector3(in_vertical_rotation, in_horizontal_rotation, 0.0))
	# Reconstructs the target location. This is needed to reduce the amount of data transfered for each frame.
	# Notice the 100 multiplication is needed by the look_at function used by the model. Check this to know more `camera_get_look_target`.
	var reconstructed_input_look_target: Vector3 = get_parent().get_head_global_transform().origin + player_camera_view * Vector3(0, 0, 100)

	accumulated_delta = 0.0
	target_location = location
	initial_location = global_transform.origin
	target_horizontal_rotation = in_horizontal_rotation
	initial_horizontal_rotation = get_model_global_basis().get_euler().y
	initial_look_target = _look_target
	target_look_target = reconstructed_input_look_target
	movement_delta = in_movement_delta

	if movement_delta <= 0.0001:
		# This is a teleport
		global_transform.origin = target_location
		if not _sitting:
			set_model_global_basis(Basis(Vector3(0, 1, 0), target_horizontal_rotation))
		_look_target = target_look_target
		initial_location = target_location
		initial_horizontal_rotation = target_horizontal_rotation
		initial_look_target = target_look_target


func get_model_global_basis() -> Basis:
	return global_transform.basis * (1.0 / scale_multiplier) * _BASIS_ROT_180


func set_model_global_basis(b: Basis) -> void:
	global_transform.basis = b * scale_multiplier * _BASIS_ROT_180


func get_current_animation() -> StringName:
	return _animation_player.current_animation


func get_current_animation_position() -> float:
	return _animation_player.current_animation_position

## We use advance because we also want to call functions that are in the animation,
## and not skip over: https://www.reddit.com/r/godot/comments/lzxzk3/is_seek_the_oncurrent_stately_method_you_can_use_to_play_an/gq4wuk2
func advance_animation_to_position(position: float) -> void:
	_animation_tree.advance(position)


func _set_animation(delta: float) -> void:
	var request: String = "parameters/Stance/transition_request"
	var current_state: String = _animation_tree.get("parameters/Stance/current_state")
	var state_machine: AnimationNodeStateMachinePlayback = _animation_tree.get("parameters/%s/Main_State/playback" % [current_state])
	if _sitting:
		_animation_tree.set(request, "Sitting")
		return
	if _dead:
		_animation_tree.set(request, "Dead")
		return
	if current_state != stance:
		_animation_tree.set(request, stance)
	if current_state != "Sitting" and current_state != "Dead":
		if _grounded:
			if not _running:
				if current_state == "Unarmed":
					state_machine.travel("Walking")
				else:
					if _is_aiming:
						state_machine.travel("Walking_ADS")
					else:
						state_machine.travel("Walking_Hip")
			else:
				if current_state == "Unarmed":
					state_machine.travel("Running")
				else:
					state_machine.travel("Running_Hip")
		else:
			state_machine.travel("Fall")
	_animation_velocity = _animation_velocity.lerp(Vector2(_movement.x, -_movement.y), clampf(8.0 * delta, 0.0, 1.0))
	if current_state == "Unarmed":
		_animation_tree.set("parameters/%s/Main_State/Running/blend_position" % [current_state], _animation_velocity)
		_animation_tree.set("parameters/%s/Main_State/Walking/blend_position" % [current_state], _animation_velocity)
	else:
		_animation_tree.set("parameters/%s/Main_State/Running_Hip/blend_position" % [current_state], _animation_velocity)
		_animation_tree.set("parameters/%s/Main_State/Walking_Hip/blend_position" % [current_state], _animation_velocity)
		_animation_tree.set("parameters/%s/Main_State/Walking_ADS/blend_position" % [current_state], _animation_velocity)


func _set_head_look() -> void:
	var pose_strength: float = 1.0
	if (stance != STANCE.UNARMED and not _sitting) or _player.damage_handler.get_health() <= 0.0:
		pose_strength = 0.0
	var head_id: int = _skeleton.find_bone("Head")
	var head_pose: Transform3D = _skeleton.get_bone_global_pose_no_override(head_id)
	# Convert the world target transform to a global pose.
	var target: Vector3 = _skeleton.global_transform.inverse() * _look_target
	head_pose = head_pose.looking_at(target, Vector3.UP)
	head_pose.basis = _look_at_camera_adjust(head_pose.basis)
	_skeleton.set_bone_global_pose_override(head_id, head_pose, pose_strength, true)


func _set_body_look() -> void:
	if stance == STANCE.UNARMED or _sitting or _player.damage_handler.get_health() <= 0.0:
		_skeleton.clear_bones_global_pose_override()
		return
	var spine_id: int = _skeleton.find_bone("Spine")
	var spine_pose: Transform3D = _skeleton.get_bone_global_pose_no_override(spine_id)
	var initial_spine_pose: Transform3D = spine_pose
	# Convert the world target transform to a global pose.
	var target: Vector3 = _skeleton.global_transform.inverse() * _look_target
	spine_pose = spine_pose.looking_at(target, Vector3.UP)
	spine_pose.basis = _look_at_camera_adjust(spine_pose.basis)
	spine_pose.basis *= initial_spine_pose.basis
	_skeleton.set_bone_global_pose_override(spine_id, spine_pose, 1, true)


## Adjust the rotation to allow looking at the camera in third person.
func _look_at_camera_adjust(head_basis: Basis) -> Basis:
	var euler: Vector3 = head_basis.get_euler()
	# Caution: Linear algebra black magic.
	if head_basis.z.z > 0.0:
		euler.y = clampf(euler.y, -TAU / 8.0, TAU / 8.0)
	elif euler.y > TAU * 3.0 / 8.0 or euler.y < -TAU * 3.0 / 8.0:
		euler.x = -euler.x
		euler.y += TAU / 2.0
	elif euler.y > 0.0:
		euler.x = euler.x * remap(euler.y, TAU / 4.0, TAU * 3.0 / 8.0, 1.0, -1.0)
		euler.y = remap(euler.y, TAU / 4.0, TAU * 3.0 / 8.0, TAU / 8.0, -TAU / 8.0)
	else:
		euler.x = euler.x * remap(euler.y, -TAU / 4.0, -TAU * 3.0 / 8.0, 1.0, -1.0)
		euler.y = remap(euler.y, -TAU / 4.0, -TAU * 3.0 / 8.0, -TAU / 8.0, TAU / 8.0)
	euler.x = clampf(euler.x, -deg_to_rad(80.0), deg_to_rad(80.0))
	return Basis.from_euler(euler)


func update(
		movement: Vector2, running: bool, grounded: bool,
		sitting: bool,  dead := _dead, is_aiming := _is_aiming,
		new_stance := stance
) -> void:
	_movement = movement
	_running = running
	_grounded = grounded
	_sitting = sitting
	_dead = dead
	_is_aiming = is_aiming
	stance = new_stance


func is_avatar_locked() -> bool:
	return _is_avatar_locked


func set_player_avatar_by_url(avatar_url: String, is_avatar_locked: bool) -> void:
	_is_avatar_locked = is_avatar_locked
	# If the avatar URL is the same as the current one, we don't need to do anything.
	if _avatar_url == avatar_url:
		return
	_avatar_url = avatar_url
	# If we're in the middle of reloading, exit and let that finish.
	if _currently_loading_avatar:
		_try_loading_avatar_again_later = true
		return
	# Load the avatar and keep reloading if we need to try again.
	_avatar_url = avatar_url
	_currently_loading_avatar = true
	await _set_player_avatar_internal(_avatar_url)
	while _try_loading_avatar_again_later:
		_try_loading_avatar_again_later = false
		await _set_player_avatar_internal(_avatar_url)
	_currently_loading_avatar = false
	avatar_changed.emit()


func _set_player_avatar_internal(avatar_url: String) -> void:
	# If empty, set the default avatar and exit.
	if avatar_url.is_empty():
		_set_default_avatar()
		return
	# Special case: If the avatar is stored in resources, load from resources.
	if Net.file_client.resource_avatars.has(avatar_url):
		var resource_path = Net.file_client.resource_avatars[avatar_url]
		set_avatar_with_resource_path(resource_path)
		return
	# If the avatar has been previously downloaded, load it from the files.
	if Net.file_client.files.has(avatar_url):
		var promise = Net.file_client.get_model_instance_promise(avatar_url)
		await(promise.wait_till_fulfilled())
		if promise.is_error():
			return
		set_avatar_with_node(promise.get_result())
		return
	# Otherwise we may need to download it. Ensure it is an HTTP location.
	if not avatar_url.to_lower().begins_with("http"):
		Notify.error("Cannot Load Avatar", "The avatar URL '" + avatar_url + "' is not a valid URL.")
		return
	# Download the avatar.
	var promise_file = Net.file_client.get_file(avatar_url, Enums.DownloadPriority.AVATAR_DEFAULT)
	await promise_file.wait_till_fulfilled()
	if promise_file.is_error():
		print("Error during downloading avatar file: %s" % [promise_file.get_error_message()])
		return
	# Load the avatar.
	var promise = Net.file_client.get_model_instance_promise(avatar_url)
	await promise.wait_till_fulfilled()
	if promise.is_error():
		print("Error during loading avatar file: %s" % [promise.get_error_message()])
		return
	set_avatar_with_node(promise.get_result())


func _set_default_avatar() -> void:
	set_avatar_with_resource_path(_DEFAULT_MODEL)


func set_avatar_with_resource_path(resource_path: String) -> void:
	var model = load(resource_path)
	var model_scene = model.instantiate()
	set_avatar_with_node(model_scene)


func set_avatar_with_node(new_avatar: Node) -> void:
	if new_avatar == _avatar:
		# This may happen when multiple promises are fulfilled on the same frame.
		return
	if is_instance_valid(_avatar):
		remove_child(_avatar)
		_avatar.queue_free()
	_avatar = _cleanup_avatar_node_structure(new_avatar)
	add_child(_avatar)
	_set_meshes()
	_set_meshes_layer()
	_adjust_model_height()
	_set_shadow_mode(_shadow_cast_mode)
	_animation_player.set_root(_avatar.get_path())
	_animation_tree.set_active(true)
	_animation_tree.set("parameters/Stance/transition_request", "Unarmed")
	_animation_tree.get("parameters/Unarmed/Main_State/playback").travel("Walking")


func set_scale_multiplier(new_scale_multiplier: float) -> void:
	scale_multiplier = new_scale_multiplier
	equipable_world_model.basis = Basis.from_scale(Vector3.ONE / scale_multiplier)


func set_movement_scale(movement_scale: float) -> void:
	var animation_scale: float = 1.4 / sqrt(movement_scale) - 0.15
	_animation_tree.set("parameters/TimeScale/scale", animation_scale)


func get_eyes_position(force_rest: bool = false) -> Vector3:
	if _skeleton:
		var center: Vector3 = _center_of_two_bones("LeftEye", "RightEye", not _sitting or force_rest)
		if center:
			return center
		center = _get_bone_transform("Head", true).origin
		if center:
			return center
	# Fallback for when the bones can't be found.
	if _sitting:
		return _EYES_POSITION_SITTING
	return _EYES_POSITION


func get_knee_pose_position() -> Vector3:
	var center = _center_of_two_bones("LeftLeg", "RightLeg")
	return center * 0.8


func _center_of_two_bones(bone_a: String, bone_b: String, is_rest: bool = false) -> Vector3:
	if not _skeleton:
		return Vector3.ZERO
	var bone_a_index: int = _skeleton.find_bone(bone_a)
	var bone_b_index: int = _skeleton.find_bone(bone_b)
	if bone_a_index == -1 or bone_b_index == -1:
		return Vector3.ZERO
	var a: Vector3
	var b: Vector3
	if is_rest:
		a = _skeleton.get_bone_global_rest(bone_a_index).origin
		b = _skeleton.get_bone_global_rest(bone_b_index).origin
		return (a + b) * 0.5
	# For the pose, use a different Skeleton3D method, and transform by the avatar transform.
	a = _skeleton.get_bone_global_pose(bone_a_index).origin
	b = _skeleton.get_bone_global_pose(bone_b_index).origin
	var center: Vector3 = (a + b) * 0.5
	return _avatar.transform * center


func _get_bone_transform(bone: String, is_rest: bool = false) -> Transform3D:
	var bone_index: int = _skeleton.find_bone(bone)
	if bone_index == -1:
		return Transform3D.IDENTITY
	if is_rest:
		return _skeleton.get_bone_global_rest(bone_index)
	return _avatar.transform * _skeleton.get_bone_global_pose(bone_index)


func _find_skeleton(node: Node) -> Skeleton3D:
	var skeleton = TMNodeUtil.recursive_get_node_by_type(node, Skeleton3D)
	return skeleton if skeleton is Skeleton3D else null


func _get_mesh_children(node: Node) -> Array:
	var meshes = []
	for child in node.get_children():
		if child is MeshInstance3D:
			meshes.append(child)
	return meshes


func _set_meshes() -> void:
	_skeleton = _find_skeleton(_avatar)
	_meshes.clear()
	if _skeleton:
		_meshes = _get_mesh_children(_skeleton)
		right_hand_attachment.set_use_external_skeleton(true)
		right_hand_attachment.set_external_skeleton(_skeleton.get_path())
		right_hand_attachment.set_bone_name("RightHand")


func set_visibility_state(_is_visible: bool) -> void:
	if _is_visible:
		show_player()
	else:
		hide_player()


func hide_player() -> void:
	_avatar.visible = false


func show_player() -> void:
	_avatar.visible = true


func show_player_and_shadow() -> void:
	_set_shadow_mode(GeometryInstance3D.ShadowCastingSetting.SHADOW_CASTING_SETTING_ON)


func show_shadow_hide_player() -> void:
	_set_shadow_mode(GeometryInstance3D.ShadowCastingSetting.SHADOW_CASTING_SETTING_SHADOWS_ONLY)


func _set_shadow_mode(mode: GeometryInstance3D.ShadowCastingSetting) -> void:
	_shadow_cast_mode = mode
	for mesh in _meshes:
		mesh.set_cast_shadows_setting(_shadow_cast_mode)


func _set_meshes_layer() -> void:
	# This is mainly used to hide the player model in the VR camera
	if not is_instance_valid(_player) or Zone.is_host() or not _player.is_local_player():
		return
	for mesh in _meshes:
		mesh.set_layer_mask_value(1, false)
		mesh.set_layer_mask_value(20, true)


func _adjust_model_height() -> void:
	# Adjust the model node's height based on the Hips rest position.
	# This allows us to support multiple sized characters without
	# actually changing the animations or doing any retargeting.
	# Note that the root translation still moves to the side at the
	# amount of meters in the animation, so this isn't perfect, it will
	# product wonky results for VERY small or VERY tall characters...
	if not _skeleton or _skeleton.get_bone_count() == 0:
		return
	var hips_index: int = _skeleton.find_bone("Hips")
	if hips_index == -1:
		hips_index = 0
	hips_height_meters = _skeleton.get_bone_global_rest(hips_index).origin.y
	_skeleton.motion_scale = hips_height_meters
	var eyes_height_meters: float = maxf(hips_height_meters * 1.6, get_eyes_position(true).y)
	head_top_height_meters = eyes_height_meters * 1.1
	if not _player:
		return
	_player.refresh_player_scale()


func _cleanup_avatar_node_structure(new_avatar: Node) -> Node:
	if new_avatar.get_child_count() != 0:
		# Determine if we need an extra Armature node (we need this for VRM avatars).
		var first_child: Node = new_avatar.get_child(0)
		if first_child is Skeleton3D:
			var extra_root = Node3D.new()
			extra_root.name = new_avatar.name
			new_avatar.name = &"Armature"
			extra_root.add_child(new_avatar)
			return extra_root
		# Determine if we need to rename the existing node to Armature.
		if new_avatar.get_node(^"Armature") == null:
			first_child.name = &"Armature"
	return new_avatar


func _on_equipable_changed(equipable: Node) -> void:
	if equipable == null:
		stance = STANCE.UNARMED
		return
	if equipable.has_meta(&"MIRROR_equipable"):
		var dict: Dictionary = equipable.get_meta(&"MIRROR_equipable")
		if dict.has("hand_nodes"):
			var hand_nodes: Dictionary = dict["hand_nodes"]
			# For now, all 2 handed weapons are held like a rifle.
			# TODO: support other weapon stances too.
			if hand_nodes.has("hand_secondary"):
				stance = STANCE.RIFLE
			else:
				stance = STANCE.PISTOL
		else:
			stance = STANCE.UNARMED


func _on_current_equipable_interacted(_equipable: Node) -> void:
	var shoot_anim: String = "Shoot_ADS" if _is_aiming else "Shoot_Hip"
	match stance:
		STANCE.UNARMED:
			return
		STANCE.PISTOL:
			_animation_tree.get("parameters/Pistol/Shoot_State/playback").travel(shoot_anim)
			_animation_tree.set("parameters/Pistol/Shoot_OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		STANCE.RIFLE:
			_animation_tree.get("parameters/Rifle/Shoot_State/playback").travel(shoot_anim)
			_animation_tree.set("parameters/Rifle/Shoot_OneShot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)

func _on_damage_handler_health_changed(_target_object: Node, new_health: float, _old_health: float, _event_source: String) -> void:
	_dead = new_health <= 0.0


func _calculate_footstep_event(dir: Vector2, leg_index: int) -> void:
	# blend is common for running and walking
	var current_state: String = _animation_tree.get("parameters/Stance/current_state")
	var anim_name: String = "Running" if _running else "Walking"
	if current_state != "Unarmed":
		if _is_aiming:
			anim_name = "Walking_ADS"
		else:
			anim_name = "Running_Hip" if _running else "Walking_Hip"
	var param_name: StringName = "parameters/%s/Main_State/%s/blend_position" % [current_state, anim_name]
	var movement = _animation_tree.get(param_name)
	if movement != null:
		var adjusted_dir: Vector2 = dir * movement.length()
		var strength_diff: float = 1.0 - clampf((movement - adjusted_dir).length(), 0.0, 1.0)
		# See https://github.com/the-mirror-megaverse/mirror-godot-app/pull/1766#discussion_r1399210671 on how to improve this code, in context.
		var current_abs: float = clampf(adjusted_dir.dot(movement), 0.0, 1.0) * strength_diff
		footstep_animated.emit(current_abs, leg_index)


func _on_left_foot_step(dir: Vector2) -> void:
	_calculate_footstep_event(dir, 0)


func _on_right_foot_step(dir: Vector2) -> void:
	_calculate_footstep_event(dir, 1)
