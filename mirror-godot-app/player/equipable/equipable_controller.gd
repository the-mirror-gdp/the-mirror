class_name EquipableController
extends Node


signal equipable_changed(equipable: Node3D)
signal current_equipable_interacted(equipable: Node3D)

const _SCRIPT_EQUIPABLE = preload("equipable.gd")
const _SCRIPT_GUN = preload("gun/gun.gd")
const _SCRIPT_FIREARM = preload("gun/firearm/firearm.gd")

var player: Player = null
var _current_asset_id: String = ""
var _current_equipable: Equipable = null


func setup(player_owner: Player) -> void:
	player = player_owner
	if not Zone.is_host() and player.is_local_player():
		player.get_equipable_view_model().setup(self)
		GameUI.instance.hotbar.hotbar_asset_selected.connect(set_selected_equipable_asset_id)
	player.get_equipable_world_model().setup(self)
	Zone.social_manager.player_connected.connect(_on_player_connected)


func _on_player_connected(_spawned_player: Player) -> void:
	if not Zone.is_host() and is_instance_valid(player) and player.is_local_player():
		_set_selected_equipable_asset_id_network.rpc_id(_spawned_player.get_peer_id(), _current_asset_id)


func _process(_delta: float) -> void:
	var is_in_free_cam_mode = (
		Zone.is_in_edit_mode() and
		not GameUI.instance.creator_ui.is_game_mode(GameMode.Mode.NORMAL)
	)

	# TODO MAYBE Simplify that huge if guard,
	# Maybe we could separate by common sections
	# Though this code might be changed anyway once we have scripting and NetSync
	if (
		Zone.is_host()
		or not is_instance_valid(player)
		or not player.is_local_player()
		or not is_instance_valid(_current_equipable)
		or is_in_free_cam_mode
		or player.is_dead()
		# Not in main_menu or other
		or GameUI.instance.is_mouse_needed_for_ui()
	):
		return
	if Input.is_action_pressed(&"primary_action"):
		_current_equipable.interact()
	_current_equipable.is_aiming = Input.is_action_pressed(&"secondary_action")


func get_raycast(bullet_spread: float = 0.0) -> Dictionary:
	var camera = player.camera_get_active_player_head_camera()
	if not camera:
		return {}
	var ray_start = player.get_global_eyes_position()
	var spread: Vector3 = (camera.global_transform.basis.y * randf_range(-1, 1) + camera.global_transform.basis.x * randf_range(-1, 1)) * deg_to_rad(bullet_spread)
	var ray_direction = camera.global_transform.basis.z
	var camera_parent = camera.get_parent()
	if camera_parent and "is_second_person" in camera_parent and camera_parent.is_second_person:
		ray_direction = -ray_direction
	var ray_end = ray_start - (ray_direction + spread) * 1000
	var ray_layers: Array = [
		&"STATIC",
		&"KINEMATIC",
		&"CHARACTER",
		&"DYNAMIC",
	]
	if is_instance_valid(_current_equipable) and _current_equipable.hit_triggers:
		ray_layers.append(&"TRIGGER")
	var ignore_objects: Array = [player]
	var initial_ray: Dictionary = Util.get_raycast(camera, camera.global_position, ray_end, ray_layers, ignore_objects)
	if initial_ray.has("position"):
		var initial_hit_position: Vector3 = initial_ray.get("position")
		ray_end = initial_hit_position - ray_direction
	return Util.get_raycast(camera, ray_start, ray_end, ray_layers, ignore_objects)


func get_current_asset_id() -> String:
	return _current_asset_id


func get_current_equipable() -> Equipable:
	if is_instance_valid(_current_equipable):
		return _current_equipable
	return null


func is_current_equipable_aiming() -> bool:
	if is_instance_valid(_current_equipable) and &"is_aiming" in _current_equipable:
		return _current_equipable.is_aiming
	return false


@rpc("call_local", "any_peer", "unreliable")
func play_sound(shoot_sound_path: String) -> void:
	if Zone.is_host() or shoot_sound_path.is_empty():
		return
	var _audio_player = AudioStreamPlayer3D.new()
	player.add_child(_audio_player)
	_audio_player.unit_size = 30
	_audio_player.stream = load(shoot_sound_path)
	if not _audio_player.stream:
		printerr("Failed to load sound: \"" + shoot_sound_path + "\"")
		return
	_audio_player.play()
	await get_tree().create_timer(_audio_player.stream.get_length()).timeout
	_audio_player.queue_free()


func set_selected_equipable_asset_id(asset_id: String) -> void:
	assert(Zone.is_client(), "This function only expects to be called on the client.")
	if asset_id == _current_asset_id:
		return
	_current_asset_id = asset_id
	await _load_equipable_by_asset_id(asset_id)
	# If another call changed the asset ID during loading, don't bother
	# sending the outdated update over the network.
	if asset_id == _current_asset_id:
		_set_selected_equipable_asset_id_network.rpc(asset_id)


@rpc("call_remote", "any_peer", "reliable")
func _set_selected_equipable_asset_id_network(asset_id: String) -> void:
	if asset_id == _current_asset_id:
		return
	_current_asset_id = asset_id
	if Zone.is_client():
		_load_equipable_by_asset_id(asset_id)


func _load_equipable_by_asset_id(asset_id: String) -> void:
	if is_instance_valid(_current_equipable):
		_current_equipable.queue_free()
	if asset_id.is_empty():
		equipable_changed.emit(null)
		return
	var asset_dict = Net.asset_client.get_asset_json(asset_id)
	if asset_dict.is_empty():
		var asset_promise = Net.asset_client.queue_download_asset(asset_id, Enums.DownloadPriority.SPACE_OBJECT_HIGH)
		asset_dict = await asset_promise.wait_till_fulfilled()
		if asset_promise.is_error():
			printerr("Failed to get asset: %s" % asset_promise.get_error_message())
			return
	var asset_data = AssetData.new()
	asset_data.populate(asset_dict)
	asset_data.try_download_file(Enums.DownloadPriority.SPACE_OBJECT_HIGH)
	var file_promise = asset_data.get_asset_file_promise()
	await file_promise.wait_till_fulfilled()
	if asset_id != _current_asset_id:
		# It is possible that another call to this method changed the current equipable.
		return
	var file_result = file_promise.get_result()
	if file_result is Node3D and file_result.has_meta(&"MIRROR_equipable"):
		_setup_equipped_item(file_result)
		equipable_changed.emit(file_result)
	else:
		equipable_changed.emit(null)


func _setup_equipped_item(new_equipable: Node3D) -> void:
	var equipable = new_equipable.get_meta(&"MIRROR_equipable")
	if not equipable is Dictionary:
		printerr("Failed to set equipped item, expected a Dictionary, but was " + str(equipable))
		return
	if equipable.has("gun"):
		var gun_dict = equipable["gun"]
		if not gun_dict is Dictionary:
			printerr("Failed to set equipped gun, expected a Dictionary, but was " + str(equipable))
			return
		if gun_dict.has("bullet"):
			var bullet_dict = gun_dict["bullet"]
			if not bullet_dict is Dictionary:
				printerr("Failed to set equipped firearm, expected a Dictionary, but was " + str(equipable))
				return
			_current_equipable = _SCRIPT_FIREARM.new()
			_current_equipable.bullet_populate(bullet_dict)
		else:
			_current_equipable = _SCRIPT_GUN.new()
		_current_equipable.gun_populate(gun_dict)
	else:
		_current_equipable = _SCRIPT_EQUIPABLE.new()
	_current_equipable.equipable_populate(equipable)
	_current_equipable.setup(self)
	_current_equipable.interacted.connect(_on_current_equipable_interacted)
	_current_equipable.set_name(&"CurrentEquipable")
	add_child(_current_equipable)


@rpc("call_local", "any_peer", "unreliable")
func instantiate_object(scene_path: String, transform: Transform3D, parent_path: NodePath = "") -> void:
	if Zone.is_host():
		return
	var packed_scene: PackedScene = load(scene_path)
	if not packed_scene:
		printerr("Failed to load scene - %s" % scene_path)
		return
	var instance: Node3D = packed_scene.instantiate()
	if not parent_path.is_empty():
		var parent_object: Node3D = get_node_or_null(parent_path)
		if is_instance_valid(parent_object):
			parent_object.add_child(instance)
	instance.global_transform = transform


func _on_current_equipable_interacted() -> void:
	if player and player.is_local_player():
		_rpc_on_current_equipable_interacted.rpc()
		player._camera_manager.add_camera_punch(_current_equipable.camera_punch)
	current_equipable_interacted.emit(_current_equipable)


@rpc("call_remote", "any_peer", "unreliable")
func _rpc_on_current_equipable_interacted() -> void:
	if Zone.is_host() or not player or player.is_local_player():
		return
	_on_current_equipable_interacted()
