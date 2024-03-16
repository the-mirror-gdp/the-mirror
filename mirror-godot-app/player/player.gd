class_name Player
extends TMCharacter3D


#signal selected_asset_id_changed(asset_id: String)
signal camera_zoom_scale_updated(camera_zoom_scale: float)

const SPAWN_RADIUS = 1.5
const _CAMERA_MANAGER_SCENE = preload("res://player/cameras/camera_manager.tscn")
const _VR_CONTROLLER_SCENE = preload("res://player/vr/vr_controller.tscn")
const _INTERACT_COLOR = Color(0.02, 0.64, 0.7)

const _DEG_TO_RAD = 0.0174532925199432957692369077
const _RAD_TO_DEG = 57.295779513082320876798154814

const _SELECTABLE_ASSET_TYPES: PackedStringArray = [
	Enums.ASSET_TYPE.MESH,
	Enums.ASSET_TYPE.AUDIO,
	Enums.ASSET_TYPE.MAP,
]

var model_rotation_degrees: Vector3: get = get_model_rotation_degrees, set = set_model_rotation_degrees
var player_height_multiplier: float: get = get_player_height_multiplier, set = _set_player_height_multiplier

var _camera_manager: CameraManager
var _interaction_distance: float = 3.0
var _lower_y_limit: int
var _peer_id: int
var _player_team: String = ""
var _profile: Dictionary = {}
var _desired_horizontal_rotation: float = 0.0
var _desired_vertical_rotation: float = 0.0
var _queue_set_height_in_meters: float = -1.0

# Vars used to network the Simulation.
var _input_compression_level = DataBuffer.COMPRESSION_LEVEL_2
var _hori_rotation_compression_level = DataBuffer.COMPRESSION_LEVEL_2
var _vert_rotation_compression_level = DataBuffer.COMPRESSION_LEVEL_2
var _vr_compression_level = DataBuffer.COMPRESSION_LEVEL_1
var _constant_buffer_size = -1
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Vars used to network the Trickled.
var _scale_compression_level = DataBuffer.COMPRESSION_LEVEL_2
var _position_compression_level = DataBuffer.COMPRESSION_LEVEL_1
var _rotation_compression_level = DataBuffer.COMPRESSION_LEVEL_2
var _velocity_compression_level = DataBuffer.COMPRESSION_LEVEL_2
var _stance_compression_level = DataBuffer.COMPRESSION_LEVEL_3

@onready var damage_handler: DamageHandler = $DamageHandler
@onready var data_store: DataStoreGlobalVariable = $DataStore
@onready var model = $PlayerModel
@onready var social_ui = $SocialUI
@onready var _capsule_shape: CollisionShape3D = $PlayerCapsuleShape
@onready var _mouse_capture = $MouseCapture

@onready var equipable_controller: EquipableController = $EquipableController
@onready var vr_controller: VRController = $VRController
@onready var _audio_controller = $AudioController
@onready var _input_controller = $InputController
@onready var _movement_controller = $MovementController
@onready var _audio_input_controller = $AudioInputController


func _ready() -> void:
	TMSceneSync.register_controller(get_multiplayer_authority(), [self])

	body_created.connect(_on_body_created)

	if TMSceneSync.is_server() or not TMSceneSync.is_networked():
		# On the server, create the body and set the `desired_body_id` that will be networked
		# so the client can spawn the body with the same ID.
		desired_body_id = TMSceneSync.fetch_free_sync_body_id()
		create_body()

	elif TMSceneSync.is_client():
		on_desired_body_id_change([])

	if not Zone.is_host() and is_local_player():
		respawn_player()

	_setup_player()
	_get_user_profile()
	add_to_group(&"prevent_voxel_placement")
	# Simply respawn a local player at spawn_position after preload is done
	# Do this after player setup otherwise there will be a lot of race condition issues
	if not Zone.is_host() and is_local_player() and not Zone.space_preload_done:
		await Zone.space_preloaded
		respawn_player()


func _setup_synchronizer(local_id) -> void:
	TMSceneSync.setup_controller(self, get_multiplayer_authority(), _collect_inputs, _count_input_size, _are_inputs_different, _controller_process)
	TMSceneSync.register_variable(self, "desired_body_id")
	TMSceneSync.track_variable_changes([self], ["desired_body_id"], on_desired_body_id_change, TMSceneSync.ALWAYS)
	TMSceneSync.register_variable(self, "frozen")
	TMSceneSync.register_variable(self, "movement_scale")
	# NOTICE: No need to network the TRANSFORM, VELOCITY, etc.. because this is already handled by
	#         the TMSceneSync by networking `jolt_sync_data`.
	TMSceneSync.register_variable(self, "jolt_sync_data")
	TMSceneSync.register_variable(self, "jolt_char_sync_data")
	TMSceneSync.setup_trickled_sync(self, trickled_sync_state_collect, trickled_sync_state_apply)
	TMSceneSync.register_process(self, GdSceneSynchronizer.PROCESS_PHASE_LATE, update_interpolated_node)

	register_interaction(&"_interaction_update_selected_nodes")
	register_interaction(&"_interaction_translation_offset_all_selected_nodes")

	start_updating.connect(_on_net_sync_start_updating)
	stop_updating.connect(_on_net_sync_stop_updating)


# ------------------------------------------------------------------- Networking
func _collect_inputs(delta: float, buffer: DataBuffer) -> void:
	var camera_transform = get_head_global_transform()
	var input_move = camera_transform.basis * get_intended_movement_direction()
	input_move = Vector2(input_move.x, input_move.z).normalized()
	var input_run = is_intent_to_run()
	var input_jump = is_intent_to_jump()
	var character_horizontal_rotation = camera_get_rotation().y
	var character_head_vertical_rotation = camera_get_rotation().x
	var look_target = get_look_target()
	var is_aiming = equipable_controller.is_current_equipable_aiming()

	write_pending_interactions_to_buffer(buffer)
	buffer.add_optional_variant(get_current_seat_path_or_null(), null)

	var vr_is_active: bool = VRManager.vr_is_active
	buffer.add_bool(vr_is_active)

	if vr_is_active:
		var vr_body_position = get_body_position()
		vr_body_position.y = 0.0
		vr_body_position = global_transform * vr_body_position
		var vr_old_position = global_position
		buffer.add_vector3(vr_body_position, _vr_compression_level)
		buffer.add_vector3(vr_old_position, _vr_compression_level)

	buffer.add_normalized_vector2(input_move.normalized(), _input_compression_level)
	buffer.add_bool(input_run)
	buffer.add_bool(input_jump)
	buffer.add_real(character_horizontal_rotation, _hori_rotation_compression_level)
	buffer.add_real(character_head_vertical_rotation, _vert_rotation_compression_level)
	buffer.add_bool(is_aiming)


func _count_input_size(inputs: DataBuffer) -> int:
	var variable_buffer_size = 0
	variable_buffer_size += count_interactions_buffer_size(inputs)
	variable_buffer_size += inputs.read_optional_variant_size(null)

	var vr_is_active: bool = inputs.read_bool()
	if vr_is_active:
		variable_buffer_size += inputs.get_vector3_size(_vr_compression_level)
		variable_buffer_size += inputs.get_vector3_size(_vr_compression_level)

	# Define it once, as if it was a const
	if _constant_buffer_size == -1:
		_constant_buffer_size = (
			inputs.get_bool_size()
			+ inputs.get_normalized_vector2_size(_input_compression_level)
			+ inputs.get_bool_size()
			+ inputs.get_bool_size()
			+ inputs.get_real_size(_hori_rotation_compression_level)
			+ inputs.get_real_size(_vert_rotation_compression_level)
			+ inputs.get_bool_size()
		)
	return _constant_buffer_size + variable_buffer_size


func _are_inputs_different(inputs_A: DataBuffer, inputs_B: DataBuffer) -> bool:
	if inputs_A.size != inputs_B.size:
		return true

	if are_interactions_different(inputs_A, inputs_B):
		return true

	var seat_path_A = inputs_A.read_optional_variant(null)
	var seat_path_B = inputs_B.read_optional_variant(null)
	if seat_path_A != seat_path_B:
		return true

	var vr_is_active_A: bool = inputs_A.read_bool()
	var vr_is_active_B: bool = inputs_B.read_bool()
	if vr_is_active_A != vr_is_active_B:
		return true

	if vr_is_active_A:
		var vr_body_position_A: Vector3 = inputs_A.read_vector3(_vr_compression_level)
		var vr_body_position_B: Vector3 = inputs_B.read_vector3(_vr_compression_level)
		if vr_body_position_A != vr_body_position_B:
			return true

		var vr_old_position_A: Vector3 = inputs_A.read_vector3(_vr_compression_level)
		var vr_old_position_B: Vector3 = inputs_B.read_vector3(_vr_compression_level)
		if vr_old_position_A != vr_old_position_B:
			return true

	var input_move_A: Vector2 = inputs_A.read_normalized_vector2(_input_compression_level)
	var input_move_B: Vector2 = inputs_B.read_normalized_vector2(_input_compression_level)
	if input_move_A != input_move_B:
		return true

	var input_run_A = inputs_A.read_bool()
	var input_run_B = inputs_B.read_bool()
	if input_run_A != input_run_B:
		return true

	var input_jump_A = inputs_A.read_bool()
	var input_jump_B = inputs_B.read_bool()
	if input_jump_A != input_jump_B:
		return true

	var h_rotation_A = inputs_A.read_real(_hori_rotation_compression_level)
	var h_rotation_B = inputs_B.read_real(_hori_rotation_compression_level)
	if h_rotation_A != h_rotation_B:
		return true

	var v_rotation_A = inputs_A.read_real(_vert_rotation_compression_level)
	var v_rotation_B = inputs_B.read_real(_vert_rotation_compression_level)
	if v_rotation_A != v_rotation_B:
		return true

	var is_aiming_A = inputs_A.read_bool()
	var is_aiming_B = inputs_B.read_bool()
	if is_aiming_A != is_aiming_B:
		return true

	return false


func _controller_process(delta: float, buffer: DataBuffer) -> void:
	execute_interactions(buffer)
	var seat_path = buffer.read_optional_variant(null)

	var vr_body_position: Vector3 = Vector3.ZERO
	var vr_old_position: Vector3 = Vector3.ZERO

	var vr_is_active: bool = buffer.read_bool()
	if vr_is_active:
		vr_body_position = buffer.read_vector3(_vr_compression_level)
		vr_old_position = buffer.read_vector3(_vr_compression_level)

	var input_move: Vector2 = buffer.read_normalized_vector2(_input_compression_level)
	var input_run = buffer.read_bool()
	var input_jump = buffer.read_bool()
	var character_horizontal_rotation = buffer.read_real(_hori_rotation_compression_level)
	var character_head_vertical_rotation = buffer.read_real(_vert_rotation_compression_level)
	var is_aiming = buffer.read_bool()

	var sitting = seat_path != null and not seat_path.is_empty()
	var gravity = _gravity if not sitting else 0.0
	if is_dead() or sitting:
		input_move = Vector2.ZERO
		input_run = false
		input_jump = false

	global_transform.basis = Basis()
	process_character(delta, input_move, input_run, input_jump, gravity)

	if not is_dead():
		_desired_horizontal_rotation = character_horizontal_rotation
		_desired_vertical_rotation = character_head_vertical_rotation

	if not TMSceneSync.is_rewinding():
		var room_scale_velocity = Vector3.ZERO
		if vr_is_active:
			room_scale_velocity = (vr_body_position - vr_old_position) / delta
			room_scale_velocity = room_scale_velocity.clamp(Vector3.ONE * -2.0, Vector3.ONE * 2.0)
			global_position += room_scale_velocity * delta
			if VRManager.vr_is_active:
				# Move our origin by the difference in position from the last frame
				var origin_delta = global_position - vr_old_position
				origin_delta.y = 0.0
				vr_controller._origin.global_position -= origin_delta

		room_scale_velocity = (global_transform.basis.inverse() * room_scale_velocity) / 2.0
		var animation_movement: Vector3 = get_local_movement_velocity() + room_scale_velocity
		if sitting:
			var seat_node: Node3D = get_node(seat_path)
			try_sit_on_seat(seat_node)
		else:
			try_get_off_seat()
		model.update(
			Vector2(animation_movement.x, animation_movement.z),
			input_run,
			is_on_floor(),
			sitting,
			is_dead(),
			is_aiming,
		)


func update_interpolated_node(sync_delta):
	model.update_character_status(sync_delta, global_transform.origin, _desired_horizontal_rotation, _desired_vertical_rotation)


func _process(delta: float) -> void:
	if Zone.is_host(): # server authoratative value
		if global_transform.origin.y <= _lower_y_limit:
			damage_handler.damage(1.0, damage_handler.SERVER_ORIGIN)
		return
	elif not is_local_player() or damage_handler.get_health() == 0.0:
		return
	RenderingServer.global_shader_parameter_set("local_player_position", global_transform.origin)
	# Everything below this check needs the input controller to be enabled.
	if not is_player_input_enabled():
		return
	if not VRManager.vr_is_active:
		process_interaction(camera_get_raycast_dict(), is_intent_to_interact())
	if (
			Input.is_action_just_pressed("player_kill") and
			ProjectSettings.get_setting("feature_flags/suicide_keybinding", false)
	):
		damage_handler.damage(1e6, get_user_id()) # A million damage should do.


func encode_stance(decoded_value) -> int:
	return AnimationController.STANCE_INT[decoded_value]


func decode_stance(encoded: int) -> StringName:
	return AnimationController.STANCE_INT.keys()[encoded]


func lerp_phase(a, b, alpha: float):
	if alpha > 0.5:
		return b
	else:
		return a


func trickled_sync_state_collect(db: DataBuffer, update_rate: float) -> void:
	var rotation_y: float = global_transform.basis.get_euler().y
	var rotation_x: float = global_transform.basis.get_euler().x
	db.add_unit_real(clamp(rotation_y / PI, -1, 1), _rotation_compression_level)
	db.add_unit_real(clamp(rotation_x / (PI / 2.0), -1, 1), _rotation_compression_level)
	# TODO constrain the scale depending on Netsync, then we can use unit_real instead
	db.add_real(scale.y, _scale_compression_level)
	db.add_vector3(position, _position_compression_level)

	var animation_details_velocity := Vector2(linear_velocity.x, linear_velocity.z)
	# TODO rename those private variables to be public, but in the next PR.
	var animation_details_running: bool = model._running
	var animation_details_grounded: bool = model._grounded
	var animation_details_sitting: bool = model._sitting
	var animation_details_dead: bool = model._dead
	var animation_details_is_aiming: bool = model._is_aiming
	# A StringName is not sent correctly over-the-wire
	var animation_details_stance: int = encode_stance(model.stance)

	db.add_vector2(animation_details_velocity, _velocity_compression_level)
	db.add_bool(animation_details_running)
	db.add_bool(animation_details_grounded)
	db.add_bool(animation_details_sitting)
	db.add_bool(animation_details_dead)
	db.add_bool(animation_details_is_aiming)
	db.add_uint(animation_details_stance, _stance_compression_level)


func trickled_sync_state_apply(dt: float, alpha: float, db_from: DataBuffer, db_to: DataBuffer) -> void:
	notify_received_net_sync_update()

	var old_rotation_y: float = db_from.read_unit_real(_rotation_compression_level) * PI
	var old_rotation_x: float = db_from.read_unit_real(_rotation_compression_level) * (PI / 2.0)
	var old_scale: float = db_from.read_real(_scale_compression_level)
	var old_position: Vector3 = db_from.read_vector3(_position_compression_level)

	var old_animation_details_velocity := db_from.read_vector2(_velocity_compression_level)
	var old_animation_details_running := db_from.read_bool()
	var old_animation_details_grounded := db_from.read_bool()
	var old_animation_details_sitting := db_from.read_bool()
	var old_animation_details_dead := db_from.read_bool()
	var old_animation_details_is_aiming := db_from.read_bool()
	var old_animation_details_stance := db_from.read_uint(_stance_compression_level)

	var new_rotation_y: float = db_to.read_unit_real(_rotation_compression_level) * PI
	var new_rotation_x: float = db_to.read_unit_real(_rotation_compression_level) * (PI / 2.0)
	var new_scale: float = db_to.read_real(_scale_compression_level)
	var new_position: Vector3 = db_to.read_vector3(_position_compression_level)
	var new_animation_details_velocity := db_to.read_vector2(_velocity_compression_level)
	var new_animation_details_running := db_to.read_bool()
	var new_animation_details_grounded := db_to.read_bool()
	var new_animation_details_sitting := db_to.read_bool()
	var new_animation_details_dead := db_to.read_bool()
	var new_animation_details_is_aiming := db_to.read_bool()
	var new_animation_details_stance := db_to.read_uint(_stance_compression_level)

	scale = Vector3.ONE * lerp(old_scale, new_scale, alpha)
	position = lerp(old_position, new_position, alpha)
	_desired_horizontal_rotation = lerp_angle(old_rotation_y, new_rotation_y, alpha)
	_desired_vertical_rotation = lerp_angle(old_rotation_x, new_rotation_x, alpha)

	# Updates the character location right away. No need to interpolate in this case
	# because this method is already interpolated.
	model.update_character_status(0.0, position, _desired_horizontal_rotation, _desired_vertical_rotation)

	var animation_details_velocity := old_animation_details_velocity.lerp(new_animation_details_velocity, alpha)
	var animation_details_running: bool = lerp_phase(old_animation_details_running, new_animation_details_running, alpha)
	var animation_details_grounded: bool = lerp_phase(old_animation_details_grounded, new_animation_details_grounded, alpha)
	var animation_details_sitting: bool = lerp_phase(old_animation_details_sitting, new_animation_details_sitting, alpha)
	var animation_details_dead: bool = lerp_phase(old_animation_details_dead, new_animation_details_dead, alpha)
	var animation_details_is_aiming: bool = lerp_phase(old_animation_details_is_aiming, new_animation_details_is_aiming, alpha)
	var animation_details_stance: int = lerp_phase(old_animation_details_stance, new_animation_details_stance, alpha)

	linear_velocity = Vector3(animation_details_velocity.x, 0, animation_details_velocity.y)
	var mv: Vector3 = get_local_movement_velocity()

	model.update(
		Vector2(mv.x, mv.z),
		animation_details_running,
		animation_details_grounded,
		animation_details_sitting,
		animation_details_dead,
		animation_details_is_aiming,
		#decode_stance(animation_details_stance)
		model.stance
	)


func _on_body_created() -> void:
	if TMSceneSync.is_server():
		set_desired_body_id(get_body_id())
		#print("[SERVER] Character `" + str(get_path()) + "` body spawned with ID `" + str(get_desired_body_id()) + "`")


func on_desired_body_id_change(old_values) -> void:
	if not TMSceneSync.is_client():
		return

	if not has_desired_body_id():
		return

	if has_body_id():
		# The body IS created already.
		# TODO Add support to node ID change, needed to implement the game-server-instance switch.
		assert(get_body_id() == get_desired_body_id())
		return

	#print("[CLIENT] Character `" + str(get_path()) + "` body spawned with ID `" + str(get_desired_body_id()) + "`")
	create_body()


func _setup_player() -> void:
	if is_instance_valid(Zone.Scene):
		_lower_y_limit = Zone.Scene.lower_y_limit
	var is_local: bool = not Zone.is_host() and is_local_player()
	if is_local:
		_setup_vr_controller()
		_setup_camera_manager()
		social_ui.name_label.visible = false
		PlayerData.game_mode_changed.connect(_on_game_mode_changed)
		Zone.mode_changed.connect(_on_zone_mode_changed)
		Zone.script_network_sync.variables_ready.connect(_space_vars_loaded)
		_input_controller.does_game_mode_accept_input = true
		_mouse_capture.enable()
	damage_handler.setup_damage_handler(self)
	_movement_controller.setup(self, is_local)
	model.setup(self)
	equipable_controller.setup(self)
	load_equipables.rpc_id(Zone.SERVER_PEER_ID)
	social_ui.setup(self)
	_audio_controller.setup(self)
	_audio_input_controller.setup(self, is_local)
	if not Zone.is_host():
		model.footstep_animated.connect(_audio_controller.footsteps_event_process)


func _setup_camera_manager() -> void:
	assert(is_local_player())
	_camera_manager = _CAMERA_MANAGER_SCENE.instantiate()
	add_child(_camera_manager)
	_camera_manager.enable_for_player(self)
	camera_zoom_scale_updated.connect(_camera_manager.set_camera_zoom_scale)


func serialize_player_data_for_network() -> Dictionary:
	return {
		"user_id": get_user_id(),
		"peer_id": _peer_id,
		"team_name": _player_team,
		"team_color": social_ui.name_label.self_modulate,
	}


func populate_from_player_data(player_data: Dictionary) -> void:
	name = player_data.user_id
	_peer_id = player_data.peer_id
	set_multiplayer_authority(player_data.peer_id)
	#if player_data.has("selected_asset_id"):
	#	_selected_asset_id = player_data.selected_asset_id


func cleanup_and_delete() -> void:
	set_process_mode(Node.PROCESS_MODE_DISABLED)
	get_parent().remove_child(self)
	queue_free()


func _setup_vr_controller() -> void:
	assert(is_local_player())
	vr_controller = _VR_CONTROLLER_SCENE.instantiate()
	add_child(vr_controller)
	vr_controller.setup(self)


func respawn_player() -> void:
	if Zone.is_host():
		_respawn_player_server()
	else:
		_respawn_player_server.rpc_id(Zone.SERVER_PEER_ID)


@rpc("call_remote", "any_peer", "reliable")
func _respawn_player_server() -> void:
	# In the network context only the server can decide which spawn point to use.
	assert(is_instance_valid(Zone.Scene))
	var spawn_point_path: NodePath = Zone.Scene.get_spawn_point_random(_player_team)
	var spawn_transform: Transform3D = _calculate_spawn_transform(spawn_point_path)
	_respawn_player_network(spawn_point_path, spawn_transform)
	_respawn_player_network.rpc_id(_peer_id, spawn_point_path, spawn_transform)


@rpc("call_remote", "any_peer", "reliable")
func _respawn_player_network(spawn_point_path: NodePath, spawn_transform: Transform3D) -> void:
	# when we die respawn is called and we must unfreeze the client
	set_frozen(false)
	try_get_off_seat()
	transform = spawn_transform
	linear_velocity = Vector3()
	angular_velocity = Vector3()
	if _camera_manager:
		_camera_manager.reset_camera_transforms(spawn_transform)
	if not spawn_point_path.is_empty():
		var spawn_point_node = get_node(spawn_point_path)
		if spawn_point_node:
			spawn_point_node.emit_signal("player_spawned_here", self)
	Zone.social_manager.player_spawned.emit(self)
	GameUI.health_display.play_respawn_sound()


func _calculate_spawn_transform(spawn_point_path: NodePath) -> Transform3D:
	var spawn_transform := Transform3D.IDENTITY
	# TODO: spawn_point_path can be null if object not ready
	var spawn_point_node: Node3D = get_node(spawn_point_path)
	if spawn_point_node:
		spawn_transform = spawn_point_node.global_transform
	spawn_transform.origin = spawn_transform * _random_point_in_circle_vec3(SPAWN_RADIUS)
	# Our player controller must remain upright and does not support non-uniform scaling.
	var rot = Basis.from_euler(Vector3(0.0, spawn_transform.basis.get_euler().y, 0.0))
	spawn_transform.basis = rot * clampf(spawn_transform.basis.y.length(), 0.05, 20.0)
	return spawn_transform


@rpc("call_local", "any_peer", "reliable")
func teleport(destination: Vector3, orientation: Vector3 = Vector3.ZERO) -> void:
	try_get_off_seat()
	position = destination
	orientation = get_model_rotation_euler() if orientation == Vector3.ZERO else orientation
	model.update_character_status(0.0, global_transform.origin, orientation.y, orientation.x)
	if not Zone.is_host() and is_local_player():
		camera_set_rotation_y(orientation.y)


func get_player_team() -> String:
	return _player_team


@rpc("call_remote", "any_peer", "reliable")
func set_player_team(team: String, color: Color) -> void:
	team = team.to_lower()
	_set_player_team(team, color)
	if Zone.is_host():
		# The server should propagate the team to other clients.
		_set_player_team.rpc(team, color)
	else:
		set_player_team.rpc_id(Zone.SERVER_PEER_ID, team, color)


@rpc("call_remote", "any_peer", "reliable")
func _set_player_team(team: String, color: Color) -> void:
	_player_team = team
	social_ui.name_label.self_modulate = color
	data_store.set_value("team_name", team)
	data_store.set_value("team_color", color)


func set_random_player_team() -> void:
	# TODO: In the future we should implement a spectator mode
	# for the player and not just automatically set their team on join.
	var teams = Zone.get_global_teams()
	if teams.is_empty():
		return
	var chosen_team = teams.pick_random()
	if not chosen_team or not chosen_team.has("team_name") or not chosen_team.has("team_color"):
		return
	set_player_team(chosen_team.team_name, chosen_team.team_color)


@rpc("call_remote", "any_peer", "reliable")
func set_peer_id(new_peer_id: int) -> void:
	_peer_id = new_peer_id


func get_user_id() -> StringName:
	return get_name()


func get_peer_id() -> int:
	return _peer_id


func get_player_name() -> String:
	return social_ui.name_label.text


func get_player_team_color() -> Color:
	return social_ui.name_label.self_modulate


func get_global_eyes_position() -> Vector3:
	return model.global_transform * model.get_eyes_position()


func is_local_player() -> bool:
	# all players are local from server point of view, cannot be called on a server
	assert(not Zone.is_host())
	return is_multiplayer_authority()


func set_collide_with_object(collision_object: CollisionObject3D, is_enabled: bool) -> void:
	printerr("TODO please implement `set_collide_with_object`.")
	#if is_enabled:
	#	remove_collision_exception_with(collision_object)
	#else:
	#	add_collision_exception_with(collision_object)
	if _camera_manager:
		_camera_manager.set_collide_with_object(collision_object, is_enabled)


func set_placement_preview_asset_id(new_selected_asset_id: String) -> void:
	assert(_camera_manager != null)
	_camera_manager.set_placement_preview_asset_id(new_selected_asset_id)


func get_equipable_view_model() -> EquipableViewModel:
	return _camera_manager.get_view_model()


func get_equipable_world_model() -> EquipableWorldModel:
	return model.equipable_world_model


@rpc("call_remote", "any_peer", "reliable")
func add_equipable(asset_id: String) -> void:
	if Zone.is_host():
		add_equipable.rpc_id(_peer_id, asset_id)
	if not Zone.is_host() and is_local_player():
		GameUI.hotbar.add_equipable(asset_id)


@rpc("call_remote", "any_peer", "reliable")
func clear_equipables() -> void:
	if Zone.is_host():
		clear_equipables.rpc_id(_peer_id)
	elif is_local_player():
		GameUI.hotbar.clear_equipables()


@rpc("call_remote", "any_peer", "reliable")
func save_equipables(key: String, items: Dictionary = {}) -> void:
	data_store.set_value(key, items)


@rpc("call_remote", "any_peer", "reliable")
func load_equipables() -> void:
	if Zone.is_host():
		load_equipables.rpc_id(_peer_id)
	if not Zone.is_host() and is_local_player():
		GameUI.hotbar.load_equipables()


func refresh_player_scale() -> void:
	var camera_zoom_scale: float = model.scale_multiplier * model.hips_height_meters
	var _movement_scale: float = sqrt(camera_zoom_scale)
	set_movement_scale(_movement_scale)
	model.set_movement_scale(_movement_scale)
	# Extend the reach of short players a bit farther (ex: 0.25x scale, 0.5x reach).
	if _movement_scale < 1.0:
		_interaction_distance = 3.0 * _movement_scale
	else:
		_interaction_distance = 3.0 * camera_zoom_scale
	camera_zoom_scale_updated.emit(camera_zoom_scale)
	model.basis = model.basis.orthonormalized() * model.scale_multiplier
	# Inform the Jolt character body of the change.
	character_height = get_player_height_meters()
	character_radius = character_height * 0.17


func get_player_height_meters() -> float:
	return model.scale_multiplier * model.head_top_height_meters


func set_player_height_meters(height_meters: float) -> void:
	var height_multiplier: float = height_meters / model.head_top_height_meters
	if Zone.is_host():
		_set_player_height_multiplier.rpc(height_multiplier)
	else:
		_set_player_height_multiplier_client_to_server.rpc_id(Zone.SERVER_PEER_ID, height_multiplier)


func get_player_height_multiplier() -> float:
	return model.scale_multiplier


func set_player_height_multiplier(height_multiplier: float) -> void:
	if Zone.is_host():
		_set_player_height_multiplier.rpc(height_multiplier)
	else:
		_set_player_height_multiplier_client_to_server.rpc_id(Zone.SERVER_PEER_ID, height_multiplier)


@rpc("any_peer", "call_local", "reliable")
func _set_player_height_multiplier_client_to_server(height_multiplier: float) -> void:
	_set_player_height_multiplier.rpc(height_multiplier)


@rpc("any_peer", "call_local", "reliable")
func _set_player_height_multiplier(height_multiplier: float) -> void:
	if height_multiplier < 0.01:
		height_multiplier = 0.01
	model.scale_multiplier = height_multiplier
	refresh_player_scale()


func get_movement_velocity() -> Vector3:
	# `get_character_relative_velocity()` is used to get the character velocity
	# relative to the body the charcter is on: In this way, when the ground is moving
	# while the character is not, the returned velocity is 0 so we can properly
	# animate the character.
	return get_character_relative_velocity() / get_cached_max_walk_speed()


func get_local_movement_velocity() -> Vector3:
	return get_model_global_basis().inverse() * get_movement_velocity()


func get_model_global_basis() -> Basis:
	return model.get_model_global_basis()


func set_model_global_basis(b: Basis) -> void:
	model.set_model_global_basis(b)


func get_model_rotation_degrees() -> Vector3:
	return get_model_rotation_euler() * _RAD_TO_DEG


func set_model_rotation_degrees(rot_degrees: Vector3) -> void:
	_desired_horizontal_rotation = rot_degrees.y * _DEG_TO_RAD


func get_model_rotation_euler() -> Vector3:
	return get_model_global_basis().get_euler()


func get_profile() -> Dictionary:
	return _profile


func _handle_net_user_profile_received(profile: Dictionary) -> void:
	if profile.get("_id", "") != get_user_id():
		return
	print("Profile: ", profile)
	_profile = profile
	social_ui.name_label.text = str(_profile.get("displayName", ""))
	data_store.configure("players", get_user_id(), {
		"name" : get_player_name(),
		"health" : damage_handler.get_health(),
		"team" : get_player_team(), # TODO: use the team format from the teams table!
		"deaths" : 0,
		"kills" : 0,
		"points" : 0
	})

	# default avatar handling
	# setting defaults/avatar_url can be used to have a per-client avatar
	var default_avatar = ProjectSettings.get_setting("defaults/avatar_url", "themirror://avatar/astronaut-male")
	var avatar_url: String = _profile.get("avatarUrl", default_avatar)
	set_player_avatar_from_user(avatar_url)


func set_player_avatar_from_script(avatar_url: String, is_avatar_locked: bool, new_height: float, height_type: String) -> void:
	if height_type == "Multiplier":
		set_player_height_multiplier(new_height)
	else:
		# If the user requested that the new avatar have a specific height in
		# meters, we need to wait until the model loads in order to determine
		# what scale to use so that we know what height the model is modeled at.
		_queue_set_height_in_meters = new_height
	_set_player_avatar_by_url(avatar_url, is_avatar_locked)


func set_player_avatar_from_user(avatar_url: String) -> void:
	if model.is_avatar_locked():
		return
	_set_player_avatar_by_url(avatar_url, false)


@rpc("call_remote", "any_peer", "reliable")
func _set_player_avatar_by_url(avatar_url: String, is_avatar_locked: bool) -> void:
	if Zone.is_host(): # Likely
		_set_player_avatar_by_url_network.rpc(avatar_url, is_avatar_locked)
	else:
		_set_player_avatar_by_url.rpc_id(Zone.SERVER_PEER_ID, avatar_url, is_avatar_locked)


@rpc("call_local", "any_peer", "reliable")
func _set_player_avatar_by_url_network(avatar_url: String, is_avatar_locked: bool) -> void:
	model.set_player_avatar_by_url(avatar_url, is_avatar_locked)


func _get_user_profile() -> void:
	if not Zone.is_host() and is_local_player():
		_handle_net_user_profile_received(Net.user_client.get_current_user_profile())
		return
	var promise := Net.user_client.get_user_profile(get_user_id())
	var profile = await promise.wait_till_fulfilled()
	if promise.is_error():
		print(promise.get_error_message())
		return
	_handle_net_user_profile_received(profile)


func set_player_visibility(_is_visible: bool) -> void:
	model.set_visibility_state(_is_visible)


func _on_zone_mode_changed(_new_zone_mode) -> void:
	# TODO: Apply space specified control when entering play mode.
	_input_controller.does_game_mode_accept_input = true


func _space_vars_loaded() -> void:
	# Set player's team when they intially join the space if it's in play-mode.
	if Zone.is_in_play_mode():
		set_random_player_team()


func _on_game_mode_changed(new_mode, _previous_mode) -> void:
	_input_controller.does_game_mode_accept_input = new_mode == GameMode.Mode.NORMAL


func setup_play_mode():
	printerr("TODO please add support to `setup_play_mode`.")
	#set_collision_mask_value(Constants.PHYSICS_LAYER_SPACE_OBJECT, false)


func setup_build_mode():
	printerr("TODO please add support to setup_build_mode`.")
	#set_collision_mask_value(Constants.PHYSICS_LAYER_SPACE_OBJECT, true)


func show_player_and_shadow() -> void:
	model.show_player_and_shadow()


func show_shadow_hide_player() -> void:
	model.show_shadow_hide_player()


func get_look_target() -> Vector3:
	if VRManager.vr_is_active:
		return vr_controller.camera_get_look_target()
	return _camera_manager.camera_get_look_target()


# # # # # # #
# # Camera
func camera_change_focus_point(new_focus_point: Vector3) -> void:
	_camera_manager.change_focus_point(new_focus_point)


func camera_change_focus_point_zoom(new_zoom: float) -> void:
	_camera_manager.change_focus_point_zoom(new_zoom)


func camera_clear_focus_point() -> void:
	_camera_manager.clear_focus_point()


func camera_get_raycast_dict(ignored_bodies=[]) -> Dictionary:
	return _camera_manager.get_camera_raycast_dict(ignored_bodies)


func camera_get_viewport() -> SubViewport:
	return _camera_manager.get_camera_viewport()


func camera_set_3d_resolution_scale(new_resolution_scale: float):
	_camera_manager.set_camera_3d_scale(new_resolution_scale)


func get_head_global_transform():
	if is_instance_valid(vr_controller) and VRManager.vr_is_active:
		return vr_controller.get_camera().global_transform
	if is_instance_valid(_camera_manager):
		return _camera_manager.get_head_global_transform()
	return global_transform * Transform3D(Basis.IDENTITY, Vector3(0, character_height, 0))


func camera_get_rotation() -> Vector3:
	if is_instance_valid(vr_controller) and VRManager.vr_is_active:
		return vr_controller.get_camera_rotation()
	if _camera_manager:
		return _camera_manager.get_camera_rotation()
	return Vector3.ZERO


func camera_get_active_player_head_camera() -> Camera3D:
	return _camera_manager.get_active_player_head_camera()


func camera_get_placement_transform_or_null(): # -> Transform3D?
	return _camera_manager.get_camera_placement_transform()


func camera_set_rotation_y(rot: float) -> void:
	_camera_manager.set_camera_rotation_y(rot)


func camera_unproject_position_to_screen(pos: Vector3) -> Vector2:
	return _camera_manager.unproject_position_to_screen(pos)


func camera_is_position_behind(pos: Vector3) -> bool:
	return _camera_manager.is_position_behind_camera(pos)


# # # # # # #
# # Controller
@rpc("call_remote", "any_peer", "reliable")
func set_player_input_allowed(is_allowed: bool) -> void:
	if Zone.is_host(): # Likely
		set_player_input_allowed_network.rpc(is_allowed)
	else:
		set_player_input_allowed.rpc_id(Zone.SERVER_PEER_ID, is_allowed)
		_input_controller.is_player_input_allowed = is_allowed


@rpc("call_local", "any_peer", "reliable")
func set_player_input_allowed_network(is_allowed: bool) -> void:
	_input_controller.is_player_input_allowed = is_allowed


func is_player_input_allowed() -> bool:
	return _input_controller.is_player_input_allowed


func is_player_input_enabled() -> bool:
	return _input_controller.is_avatar_input_enabled()


func get_intended_movement_direction() -> Vector3:
	if not is_local_player():
		return Vector3(0,0,0)
	return _input_controller.get_intended_movement_direction() + \
		vr_controller.get_intended_movement_direction()


func get_intended_camera_rotation_change() -> Vector2:
	if not is_local_player():
		return Vector2(0,0)
	return _input_controller.get_intended_camera_rotation_change() + \
		vr_controller.get_intended_camera_rotation_change()


func process_interaction(raycast_dict: Dictionary, intent_to_interact: bool) -> bool:
	var interaction_target: Node = get_interaction_target(raycast_dict)
	if intent_to_interact:
		# This code always run even if interaction_target is null, so that we
		# can allow the player to get off a seat by interacting with nothing.
		_movement_controller.seat_controller.player_interact(interaction_target)
	if interaction_target == null:
		return false
	if intent_to_interact and interaction_target.has_user_signal(&"player_interact"):
		interaction_target.emit_signal(&"player_interact", self)
		Zone.script_network_sync.client_to_server_player_interact(interaction_target, self)
	if interaction_target.has_method("hover_panel"):
		interaction_target.hover_panel(raycast_dict.position)
		if intent_to_interact and interaction_target.has_method("click_panel"):
			interaction_target.click_panel()
	# Draw interaction outlines using a local AABB when the target isn't null.
	draw_interaction_outline(interaction_target)
	return true


func get_interaction_target(raycast_dict: Dictionary) -> Node3D:
	if not raycast_dict.has("position") or not raycast_dict.has("collider"):
		return null
	if position.distance_to(raycast_dict.position) > _interaction_distance:
		return null
	if not is_instance_valid(raycast_dict.collider):
		return null
	var target: Node3D = raycast_dict.collider
	if target == null:
		return null
	if target.has_method("hover_panel") and target.has_method("click_panel"):
		return target
	if target.has_user_signal(&"player_interact"):
		return target
	return _movement_controller.seat_controller.get_seat_node(target)


func draw_interaction_outline(target: Node3D) -> void:
	var aabb: AABB = TMNodeUtil.get_local_aabb_of_descendants(target)
	var transf: Transform3D = target.global_transform
	transf = transf.translated_local(aabb.position)
	transf.basis *= Basis.from_scale(aabb.size)
	GameUI.object_outlines.draw_wireframe_box_transform(transf, _INTERACT_COLOR)
	if GameplaySettings.show_floating_control_hints:
		var screen_pos: Vector2 = camera_unproject_position_to_screen(
				transf * Vector3(0.5, 0.5, 0.5))
		GameUI.floating_text.draw_text_at_screen_position("Interact (E)", screen_pos)


# TODO: make this network synced
# This is currently hiding a bug because the input controller will be unavailable on the other clients.
func is_intent_to_jump() -> bool:
	if not is_local_player():
		return false
	assert(TMSceneSync.is_client())
	return (_input_controller and _input_controller.is_intent_to_jump()) or (vr_controller and vr_controller.is_intent_to_jump())


# TODO: make this network synced
func is_intent_to_interact() -> bool:
	if not is_local_player():
		return false
	assert(TMSceneSync.is_client())
	return _input_controller.is_intent_to_interact()


# TODO: make this network synced
func is_intent_to_run() -> bool:
	# This check fails when:
	# - means you were disconnected from the server, which can be when:
	# - when you stopped execution for too long on the client side (breakpoint)
	# - when the player's code calls this function expecting it to be networked.
	if not is_local_player() or get_local_movement_velocity().length() <= 0.0:
		return false
	return _input_controller.is_intent_to_run() or vr_controller.is_intent_to_run()


# Health
func damage(amount: float, source: String) -> void:
	if damage_handler and is_instance_valid(damage_handler):
		var player_damage_enabled = Zone.script_network_sync.get_global_variable("player_damage_is_enabled")
		if player_damage_enabled == null:
			Zone.script_network_sync.set_global_variable("player_damage_is_enabled", true)
			player_damage_enabled = true
		if not player_damage_enabled:
			return
		var friendly_fire = Zone.script_network_sync.get_global_variable("match_settings/friendly_fire")
		if typeof(friendly_fire) != TYPE_STRING:
			Zone.script_network_sync.set_global_variable("match_settings/friendly_fire", "Enabled")
			friendly_fire = "Enabled"
		if friendly_fire != "Enabled":
			var killer = Zone.social_manager.get_player(source)
			if killer and is_instance_valid(killer):
				if killer.get_player_team() == get_player_team():
					if friendly_fire == "Disabled":
						return
					elif friendly_fire == "Reflect":
						killer.damage_handler.damage(amount, source)
						return
					else: # No Kills mode.
						var max_damage: float = maxf(0.0, damage_handler.get_health() - 1.0)
						if amount > max_damage:
							amount = max_damage
		damage_handler.damage(amount, source)


func heal(amount: float, source: String) -> void:
	if damage_handler and is_instance_valid(damage_handler):
		damage_handler.heal(amount, source)


func revive():
	if damage_handler and is_instance_valid(damage_handler) and Zone.is_host():
		damage_handler.server_revive_after_delay() # delay is statically 5 seconds


func get_health() -> float:
	if damage_handler and is_instance_valid(damage_handler):
		return damage_handler.get_health()
	return 0.0


func is_dead() -> bool:
	if damage_handler and is_instance_valid(damage_handler):
		return damage_handler.get_health() <= 0
	return true


func _on_damage_handler_death(_target_object: Node, murderer_id: String) -> void:
	if not Zone.is_host():
		return
	damage_handler.server_revive_after_delay()
	data_store.set_value("health", damage_handler.get_health())
	data_store.add_to_value("deaths", 1, 0)
	data_store.add_to_value("points", -10, 0)
	var murderers_name: StringName = murderer_id
	if Zone.has_player(murderers_name):
		var murderer_player: Player = Zone.get_player(murderers_name)
		murderer_player.data_store.add_to_value("points", 10, 0)
		murderer_player.data_store.add_to_value("kills", 1, 0)
		murderer_id = murderer_player.get_player_name()
	print("Player ", get_player_name(), " was killed by ", murderer_id)


func _on_damage_handler_health_changed(_target_object: Node, new_health: float, old_health: float, event_origin: String):
	if Zone.is_host() or not is_local_player():
		return
	data_store.set_value("health", new_health)
	if new_health < old_health:
		GameUI.health_display.show_damage_screen()
	if Zone.has_player(event_origin):
		var killer: Player = Zone.get_player(event_origin)
		if killer != self:
			GameUI.health_display.add_damage_indicator(killer.global_position)
	GameUI.health_display.set_health(ceili(new_health))
	if new_health <= 0.0:
		GameUI.health_display.play_death_sound()


# Important: this is server-side only!
func _on_damage_handler_server_revive(target_object: Node, _event_origin: String) -> void:
	if not Zone.is_host():
		return
	print("Player ", target_object.get_player_name(), " revived from death, respawning: ", Zone.get_instance_type())
	respawn_player()
	data_store.set_value("health", damage_handler.get_health())


# # # # # # #
# # Seat Controller
func is_sitting():
	return get_current_seat() != null


func get_current_seat() -> Node3D:
	return _movement_controller.seat_controller.get_current_seat()


func get_current_seat_path_or_null():
	var seat: Node3D = get_current_seat()
	if seat:
		return String(seat.get_path())
	return null


func try_get_off_seat() -> void:
	if get_current_seat() != null:
		_movement_controller.seat_controller.get_off_seat()


func try_sit_on_seat(seat_node: Node3D) -> void:
	_movement_controller.seat_controller.try_sit_on_seat(seat_node)


# # # # # # #
# # VR
func get_vr_camera() -> XRCamera3D:
	return vr_controller.get_camera()


func get_body_position() -> Vector3:
	if is_instance_valid(vr_controller):
		return vr_controller.get_body_position()
	return Vector3.ZERO


# # # # # # #
# # Misc
func _random_point_in_circle_vec3(max_radius: float) -> Vector3:
	var radius = sqrt(randf()) * max_radius
	var angle = randf() * TAU
	var vec = Vector2.from_angle(angle) * radius
	return Vector3(vec.x, 0.0, vec.y)


func _on_net_sync_start_updating() -> void:
	model.show()
	set_layer_name(&"CHARACTER")


func _on_net_sync_stop_updating() -> void:
	model.hide()
	set_layer_name(&"")


func is_audio_input_detected() -> bool:
	return _audio_input_controller.audio_input_active


# # # # # # #
# # Coopeartive editing
var locally_selected_space_objects: Array
var has_pending_update: bool = false
var currently_selected_space_object_ids: Array


func update_selected_nodes(selected_nodes: Array[Node]):
	# Here, we should only have space_objects selected,
	# If not, we will not be able to find net_ids for some of the selected nodes
	locally_selected_space_objects = selected_nodes
	_try_update_selected_nodes()


func _try_update_selected_nodes():
	if has_pending_update:
		# There is a pending update already.. Nothing to do.
		return

	var net_ids: Array = []
	var need_re_sync := false
	for space_object in locally_selected_space_objects:
		var net_id = TMSceneSync.get_node_id(space_object)
		if net_id != 4294967295:
			net_ids.push_back(net_id)
		else:
			need_re_sync = true

	queue_interaction(self, &"_interaction_update_selected_nodes", net_ids)

	if need_re_sync:
		# Not yet ready for networking this array, as some
		# space_objects (abbreviated `so` in some places) don't have a NetId yet.
		# Try to network it again in 0.5secs
		has_pending_update = true
		await get_tree().create_timer(0.5).timeout
		has_pending_update = false
		_try_update_selected_nodes()


func _interaction_update_selected_nodes(selected_node_ids):
	var peer = get_multiplayer_authority()
	for so_net_id in currently_selected_space_object_ids:
		var so = TMSceneSync.get_node_from_id(so_net_id)
		if is_instance_valid(so):
			so.notify_peer_selection_end(peer)

	currently_selected_space_object_ids = selected_node_ids.duplicate(true)

	for so_net_id in currently_selected_space_object_ids:
		var so = TMSceneSync.get_node_from_id(so_net_id)
		if is_instance_valid(so):
			so.notify_peer_selection_start(peer)


func translation_offset_all_selected_nodes(translation: Vector3):
	var args: Array = [translation, currently_selected_space_object_ids]
	queue_interaction(self, &"_interaction_translation_offset_all_selected_nodes", args)


func _interaction_translation_offset_all_selected_nodes(args: Array):
	assert(args.size() == 2, "_interaction_translation_offset_all_selected_nodes should receive an array of size 2")

	var new_translation: Vector3 = args[0]
	var selected_space_objects: Array = args[1]

	var median_loc := Vector3.ZERO
	for so_net_id in selected_space_objects:
		var so: SpaceObject = TMSceneSync.get_node_from_id(so_net_id)
		if is_instance_valid(so):
			median_loc += so.global_transform.origin

	median_loc /= selected_space_objects.size()

	var offset = new_translation - median_loc
	for so_net_id in selected_space_objects:
		var so: SpaceObject = TMSceneSync.get_node_from_id(so_net_id)
		if is_instance_valid(so):
			so.global_transform.origin += offset


func _on_player_model_avatar_changed() -> void:
	if _queue_set_height_in_meters > 0.0:
		set_player_height_meters(_queue_set_height_in_meters)
		_queue_set_height_in_meters = -1.0

# # # # # # #
# # Emoji
@rpc("call_local", "any_peer", "reliable")
func create_emoji(emoji: String) -> void:
	social_ui.create_emoji(emoji)
	if not Zone.is_host() and is_local_player():
		GameUI.chat_ui.send_chat_message_server.rpc_id(Zone.SERVER_PEER_ID, emoji)
