class_name ZoneClass
extends Node


signal completed_booting()
signal deeplinking_started()
signal notifications_started()
signal mode_changed(new_zone_mode: ZONE_MODE)
signal ready_check_rejected()
signal ready_check_started(ready_ids, seconds_left: float)
signal space_preloaded()
signal enable_asset_deselect()
signal disable_asset_deselect()

signal game_start()
signal physics_process_every_frame(delta_time: float)
signal process_every_frame(delta_time: float)

const MAX_LOG_SIZE = 50
const SERVER_PEER_ID = 1

enum ZONE_MODE {
	EDIT,
	PLAY,
}

enum DENIED_REASON {
	SERVER_WARMING_UP,
	CLIENT_VERSION_MISMATCH,
	USER_ID_IN_USE,
	KICKED_OUT_OF_SPACE,
}

@onready var social_manager: SocialManager = $SocialManager
@onready var instance_manager: InstanceManager = $InstanceManager
@onready var material_manager: MaterialManager = $MaterialManager
@onready var match_system: MatchRoundSystem = $MatchRoundSystem
@onready var client: Client = $Client
@onready var server: Server = $Server
@onready var shapes_generator = $CollisionShapeGenerator
@onready var script_network_sync: Timer = $ScriptNetworkSync
@onready var space_restore: SpaceRestore = $SpaceRestore
@onready var _ws_debug_prints = ProjectSettings.get_setting("debug_flags/show_web_socket_debug", false)
@onready var _space_scene: PackedScene = preload("res://scenes/space_scene.tscn")

var hash_requests: Dictionary = {}
var physics_hash_promises: Dictionary = {}

var current_mode = ZONE_MODE.EDIT
var space: Dictionary = {}
var space_objects: Array = []
var space_ready: bool = false
var server_host: bool = false
var notifications_ready: bool = false
var deeplink_ready: bool = true
var bootup_completed: bool = false
var space_preload_done: bool = false:
	set(value):
		space_preload_done = value
		if value:
			space_preloaded.emit()

var Scene: SpaceScene

func _ready() -> void:
	PriorityInput.register_actions([&"action_deselect"], enable_asset_deselect, disable_asset_deselect)


func change_to_space_scene() -> void:
	get_tree().change_scene_to_packed(_space_scene)
	# TODO ensure that asset deselection is disabled when the user does not
	# have edit permission (for example, when in play or preview mode).
	enable_asset_deselect.emit()


func change_to_empty_scene() -> void:
	var empty_scene = PackedScene.new()
	empty_scene.pack(Node.new())
	var error = get_tree().change_scene_to_packed(empty_scene)
	assert(error == OK)
	disable_asset_deselect.emit()


## wait until the game knows if it is the server or client
## we mark this as static so you can
func wait_till_booted():
	if bootup_completed:
		return
	await completed_booting


## Called after the app has started handling deeplinking
## but also that the first command has been processed
func wait_till_deeplink_ready():
	if deeplink_ready:
		return
	await deeplinking_started


## we can await for the notifications system to be ready to tell the user about important items
## used when booting the app if you want to notify in ready or bootup
func wait_till_notifications_ready():
	if notifications_ready:
		return
	await notifications_started


func _unhandled_input(input_event: InputEvent) -> void:
	if input_event.is_action_pressed(&"preview_mode_toggle"):
		client_toggle_mode()


func _physics_process(delta: float) -> void:
	physics_process_every_frame.emit(delta)


func _process(delta: float) -> void:
	process_every_frame.emit(delta)


func is_headless() -> bool:
	return DisplayServer.get_name() == "headless"


func is_client() -> bool:
	return not server_host


func is_host() -> bool:
	return server_host


func get_readable_latency(peer_id: int) -> String:
	var lat = TMSceneSync.get_peer_latency(peer_id)
	if lat == -1:
		return "--"
	else:
		return str(lat) + " ms"


func get_user_id(peer_id: int) -> String:
	assert(Zone.is_host()) # at the moment this works only on a server
	return server.get_user_id(peer_id)


# is this client or serverside? useful for prints
func get_instance_type() -> String:
	return "server" if Zone.is_host() else "client"


func is_in_edit_mode() -> bool:
	return current_mode == ZONE_MODE.EDIT


func is_in_play_mode() -> bool:
	return current_mode == ZONE_MODE.PLAY


func get_all_space_instances_ids_using_asset(in_asset_id: String) -> Array:
	var instances_ids: Array = []
	for instance_data in space_objects:
		var instance_asset_id: String = instance_data.asset
		if instance_asset_id == in_asset_id:
			instances_ids.append(instance_data.id)
	return instances_ids


func get_space_instance_from_id(in_instance_id: String) -> SpaceObject:
	return instance_manager.get_instance(in_instance_id)


#########
## Teams
func get_global_teams() -> Array:
	var teams = script_network_sync.get_global_variable("teams")
	if teams is Array:
		return teams.duplicate(true)
	return Array()


func set_global_variable_teams(arr: Array) -> void:
	var global_teams = get_global_teams()
	if global_teams is Array and global_teams.hash() != arr.hash():
		# we use copy on write here to avoid potential hash matches with deep copy!
		script_network_sync.set_global_variable("teams", arr.duplicate(true))


#########
## Players
func has_player(in_user_id: StringName) -> bool: return social_manager.has_player(in_user_id)
func get_player(in_user_id: StringName) -> Player: return social_manager.get_player(in_user_id)
func find_player_by_peer(peer: int) -> Player: return social_manager.find_player_by_peer(peer)
func get_all_players() -> Array: return social_manager.get_all_players() #returns Array<Player.tscn>
func get_all_users_ids() -> Array[StringName]: return social_manager.get_all_users_ids()


#########
## Server
func start_server() -> bool:
	space.clear()
	space_objects.clear()
	var success: bool = server.start_server()
	server.sent_data_to_client_requested.connect(_on_server_sent_data_to_client_requested)
	return success


func _on_server_sent_data_to_client_requested(in_peer: int, in_data: Array) -> void:
	client.send_data_to_client(in_peer, in_data)


func server_create_space_object(properties: Dictionary, receipt: Dictionary = {}) -> void:
	server.server_create_space_object(properties, receipt)


func send_data_to_server(in_data_array: Array) -> void:
	assert(not is_host()) # we can support such case if we need
	var data = JSON.stringify(in_data_array, "", false, true)
	if _ws_debug_prints:
		print("Sending to server JSON: ", data)
	# Limit the maximum packet size to 1 MiB since large packets can stall the server.
	if data.length() * 4 > 1024 * 1024:
		push_error("You're sending too much data, you tried to send ", data.length() * 4, " bytes, and the limit is now ", 1024 * 1024, "bytes")
		return
	server.send_data_to_server(in_data_array)


# in fact it's sending data to all clients (need to reflect in the name)
func send_data_to_all_peer(data_array: Array) -> void:
	server.send_data_to_all_clients(data_array)


func client_send_data_to_all(data_array: Array) -> void:
	assert(not Zone.is_host())
	server.send_data_to_server(data_array)
	client.send_data_to_all_clients(data_array)


func client_send_create_space_object(properties: Dictionary, receipt: Dictionary = {}) -> void:
	client.client_send_create_space_object(properties, receipt)


func send_data_to_client(client_peer_id: int, in_data_2_receive: Array) -> void:
	client.send_data_to_client(client_peer_id, in_data_2_receive)


func client_access_denied(in_client_peer_id: int, in_reason: int) -> void:
	client.access_denied.rpc_id(in_client_peer_id, in_reason)


func client_access_granted(in_client_peer_id: int) -> void:
	client.access_granted.rpc_id(in_client_peer_id)


func client_create_object(in_client_peer: int, new_space_obj: Dictionary, receipt: Dictionary = {}, in_additional_obj_info: Dictionary = {}) -> void:
	client.client_create_object.rpc_id(in_client_peer, new_space_obj, receipt, in_additional_obj_info)


func send_space_data_to_client(in_client_peer: int, in_space_data: Dictionary, in_mode: ZONE_MODE):
	client.client_receive_space_data.rpc_id(in_client_peer, in_space_data, in_mode)


func on_exit_space() -> void:
	print("exit space called")
	space_preload_done = false
	space_ready = false
	space = {}
	Scene = null
	space_objects.clear()
	social_manager.clear_children()
	instance_manager.clear_children()
	change_to_empty_scene()
	GameUI.on_exit_space()
	print("exit space game ui ran")


######
## Play / Edit mode
func client_toggle_mode():
	assert(not is_host())
	if current_mode == ZONE_MODE.EDIT:
		client_send_mode_change(ZONE_MODE.PLAY)
		Analytics.track_event_client(AnalyticsEvent.TYPE.PREVIEW_MODE_ENTERED)
	elif current_mode == ZONE_MODE.PLAY:
		client_send_mode_change(ZONE_MODE.EDIT)
		Analytics.track_event_client(AnalyticsEvent.TYPE.PREVIEW_MODE_EXITED)


func client_ready_check() -> void:
	if current_mode != ZONE_MODE.EDIT:
		return
	assert(not is_host())
	server.send_data_to_server([Packet.TYPE.PREVIEW_READY_CHECK])


func client_reject_ready_check() -> void:
	if current_mode != ZONE_MODE.EDIT:
		return
	assert(not is_host())
	server.send_data_to_server([Packet.TYPE.PREVIEW_READY_CHECK_REJECT])


func client_send_mode_change(mode: int):
	server.send_data_to_server([Packet.TYPE.ZONE_MODE_CHANGE, mode])


# Can be called when receiving ZONE_MODE_CHANGE, or at the end of a ready check.
func change_mode(zone_mode: int) -> void:
	if Zone.is_host():
		match zone_mode:
			ZONE_MODE.EDIT:
				script_network_sync.server_exit_preview_mode()
				Zone.match_system.terminate_match()
			ZONE_MODE.PLAY:
				script_network_sync.server_enter_preview_mode()
	match zone_mode:
		ZONE_MODE.EDIT:
			_start_edit()
		ZONE_MODE.PLAY:
			_start_play()
	mode_changed.emit(zone_mode)


func _start_play() -> void:
	reset_zone_state()
	current_mode = ZONE_MODE.PLAY
	social_manager.prepare_players_for_play_mode()
	instance_manager.enable_play()
	game_start.emit()


func _start_edit() -> void:
	reset_zone_state()
	current_mode = ZONE_MODE.EDIT
	social_manager.prepare_players_for_build_mode()


# used by both server and client
func reset_zone_state() -> void:
	instance_manager.reset_all_instances()


func is_play_zone() -> bool:
	return Zone.client.current_zone.get("dedicated", false)


####
## Space sync
func receive_sync_space_object(space_object: Dictionary) -> void:
	for i in range(space_objects.size()):
		var obj = space_objects[i]
		if obj["_id"] != space_object["_id"]:
			continue
		if space_object.has("deleted"):
			space_objects.pop_at(i)
			instance_manager.remove_space_object_by_id(obj["_id"])
			return
		space_objects[i] = space_object
		instance_manager.update_space_object(space_object)
		return


func receive_sync_space_objects(updated_objects: Array) -> void:
	var obj_dict: Dictionary = {}
	for obj in updated_objects:
		obj_dict[obj["_id"]] = obj
	for i in range(space_objects.size()):
		var obj = space_objects[i]
		var obj_id = obj["_id"]
		if not obj_dict.has(obj_id):
			continue
		if obj_dict[obj_id].has("deleted"):
			space_objects.pop_at(i)
			instance_manager.remove_space_object_by_id(obj_id)
			continue
		space_objects[i] = obj_dict[obj_id]
		instance_manager.update_space_object(space_objects[i])


func receive_delete_space_objects(deleted_space_object_ids: Array) -> void:
	for i in range(space_objects.size() - 1, -1, -1):
		var obj = space_objects[i]
		var obj_id = StringName(obj["_id"])
		if deleted_space_object_ids.has(obj_id):
			space_objects.pop_at(i)
			instance_manager.remove_space_object_by_id(obj_id)


func receive_space_update(spath: String, value) -> void:
	var old_space_role = Enums.ROLE.NO_ROLE
	if not is_host():
		old_space_role = Util.get_role_for_user(Zone.space, Net.user_id)

	if spath.begins_with("materialInstances."):
		return # Do not spam with error log for materials
	var sub_paths = spath.split(".", false)
	var segment = Zone.space
	for i in sub_paths.size() - 1:
		if segment is Array:
			# Not supported right now
			return
		elif not segment.keys().has(sub_paths[i]):
			printerr("[",get_instance_type(),"]: Incorrect data path for space partial update: ", spath)
			print(segment.keys(), sub_paths[i])
			return
		segment = segment[sub_paths[i]]
	if segment is Array:
		var index_string = sub_paths[-1]
		if not index_string.is_valid_int():
			printerr("[",get_instance_type(),"]: Incorrect data path [array] for space partial update: ", spath)
			return
		var index = int(index_string)
		if segment.size() <= index:
			segment.resize(index + 1)
		segment[index] = value
	else:
		segment[sub_paths[-1]] = value
	if spath == "role.defaultRole": # Special case, since we receive this data through http but not with PubSub
		match value:
			Enums.ROLE.MANAGER: Zone.space["publicBuildPermissions"] = "manager"
			Enums.ROLE.CONTRIBUTOR: Zone.space["publicBuildPermissions"] = "contributor"
			Enums.ROLE.OBSERVER: Zone.space["publicBuildPermissions"] = "observer"
			Enums.ROLE.NO_ROLE:   Zone.space["publicBuildPermissions"] = "private"
	print("[",get_instance_type(),"]: PubSub Space Partial Update Path: ", spath, "  Value: ", value)
	if not is_host():
		#Update user state based on new roles
		var new_role = Util.get_role_for_user(Zone.space, Net.user_id)
		if new_role <= Enums.ROLE.NO_ROLE:
			Zone.client.quit_to_main_menu()
			Notify.warning("Permission Denied!", "You have been removed from the server!")
			return
		if new_role != old_space_role:
			Notify.info("Permissions Changed!", "Your Space Permissions has been changed.\n Please re-join the server to refresh them.")
	elif spath.begins_with("kickRequests"):
		var players = []
		if value is Array:
			players = value
		elif value is String:
			players.append(value)
		else:
			push_error("Incorrect data type", "kick_requests value must a float or array")
			return
		if players.size() == 0:
			return # clear list, just ignore
		for player_id in players:
			_server_request_kick_player(player_id)
		Zone.space["kickRequests"] = []
		Net.zone_socket.update_space(Zone.space)


func _server_request_kick_player(player_id: String) -> void:
	assert(Zone.is_host())
	for peer_id in Zone.server.players:
		var player = Zone.server.players[peer_id]
		if player == null or not is_instance_valid(player):
			continue
		if player.get_user_id() != player_id:
			continue
		Zone.client_access_denied(peer_id, Zone.DENIED_REASON.KICKED_OUT_OF_SPACE)
		return
	push_error("Player peer is invalid, the player has already disconnected")


# Helpers
static func receipt_create(in_user_id: String, auto_select: bool, uuid: String = "") -> Dictionary:
		return {"created_by_user": in_user_id, "auto_select": auto_select, "uuid": uuid}

static func receipt_validate(in_receipt: Dictionary) -> bool:
	var schema = {"created_by_user": TYPE_STRING, "auto_select": TYPE_BOOL, "uuid": TYPE_STRING}
	return Util.compare_with_schema(in_receipt, schema)


# Space variable database syncing methods.
func _sync_variables_to_database(variable_property_data: Dictionary) -> void:
	if not space.has("_id") and variable_property_data.size() > 0: # maybe server not ready so let's keep this here
		return
	var space_with_only_vars: Dictionary = {
		"_id": space["_id"],
		"patchSpaceVariablesData": variable_property_data,
	}
	Net.zone_socket.update_space_variables(space_with_only_vars)


func _on_server_peer_space_data_received(space_data: Dictionary) -> void:
	space = space_data


func get_local_character() -> TMCharacter3D:
	if TMSceneSync.is_server():
		return null
	var nodes = TMSceneSync.local_controller_get_controlled_nodes()
	if nodes.size() != 1:
		return null
	return nodes[0]


func _on_instance_manager_space_objects_created() -> void:
	assert(Zone.is_host())
	if current_mode == ZONE_MODE.PLAY:
		game_start.emit()
