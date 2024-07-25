class_name Server
extends Node


signal sent_data_to_client_requested(in_peer_id: int, in_data: Array)
signal space_data_received(space_data: Dictionary)
signal space_variables_received(space_variable_data: Dictionary, sync_back_to_database: bool)

const PLAYER_DATA_PROPERTY_USER_ID = "user_id"
const SERVER_PEER_ID = 1
const STATUS_UPDATE_COOLDOWN: float = 300.0 # seconds, 5 minutes

static var port: int = ProjectSettings.get_setting("mirror/zone_server_port")
var space_id: String

# TODO: make this actually remove you when you are disconnected
var players: Dictionary = {
	# peer_id: Player
}

var server_peer: ENetMultiplayerPeer = null
var _server_data_received = false
var _server_empty_time: float
var _last_status_update_time: float
var _ready_check_expire: float
var _ready_check_ids = []

@onready var _is_play_server: bool = Util.get_commandline_id_val("mode") == "PLAY"


func _ready() -> void:
	# class meant to be used internally by Zone object
	assert(get_parent() == Zone)


func _process(_delta: float) -> void:
	if not server_peer:
		return
	_check_server_status()


func _check_server_status() -> void:
	var now: float = Time.get_unix_time_from_system()
	if now >= _last_status_update_time + STATUS_UPDATE_COOLDOWN:
		_update_server_status()


func _space_object_created(new_space_obj: Dictionary, receipt: Dictionary) -> void:
	Zone.space_objects.append(new_space_obj)
	Zone.instance_manager.create_space_object(new_space_obj, receipt)
	for peer_id in players.keys():
		Zone.client_create_object(peer_id, new_space_obj, receipt)


## finds and updates a space object and sends the update to clients.
## if found, returns true. if it is not found, false is returned.
func _space_object_updated(modified_space_obj: Dictionary) -> bool:
	for i in range(Zone.space_objects.size()):
		if Zone.space_objects[i]["_id"] == modified_space_obj["_id"]:
			Zone.space_objects[i] = modified_space_obj
			_server_send_sync_space_object_to_all(modified_space_obj)
			return true
	return false


## the zone server requested the space object itself. it may be new or just updated.
func _space_object_received(space_obj: Dictionary) -> void:
	# find the existing object, set it in memory, and update it on all clients
	var did_find_and_update = _space_object_updated(space_obj)
	# otherwise it is a new object and must be created.
	if not did_find_and_update:
		_space_object_created(space_obj, {})


func _space_object_deleted(deleted_space_obj) -> void:
	for i in range(Zone.space_objects.size()):
		if Zone.space_objects[i]["_id"] == deleted_space_obj["_id"]:
			Zone.space_objects.remove_at(i)
			break
	deleted_space_obj["deleted"] = true
	Zone.instance_manager.remove_space_object_by_id(deleted_space_obj["_id"])
	_server_send_sync_space_object_to_all(deleted_space_obj)


func _server_send_sync_space_object_to_all(space_object) -> void:
	var packet = [Packet.TYPE.UPDATE_SPACE_OBJECT, space_object]
	Zone.send_data_to_all_peer(packet)


func _server_send_sync_space_objects_to_all(space_objects: Array) -> void:
	var packet = [Packet.TYPE.UPDATE_SPACE_OBJECTS, space_objects]
	Zone.send_data_to_all_peer(packet)


func _server_send_delete_space_objects_to_all(space_obj_ids: Array) -> void:
	var packet = [Packet.TYPE.DELETE_SPACE_OBJECTS, space_obj_ids]
	Zone.send_data_to_all_peer(packet)


func start_server() -> bool:
	print("----------------------------------------")
	print("----------------------------------------")
	print("----------------------------------------")
	print("STARTING The Mirror Megaverse Server...")
	print("----------------------------------------")
	print("----------------------------------------")
	print("----------------------------------------")
	server_peer = ENetMultiplayerPeer.new()
	_server_data_received = false
	var error: Error = server_peer.create_server(port, 64)
	if error != OK:
		# TODO: Godot only allows defining command line arguments for all
		# instances, so all of them try to be the server. Ignore the can't
		# create error for now. In the future, define per-instance arguments
		# so that only one instance tries to be the server.
		if error != ERR_CANT_CREATE:
			printerr("FAILED to start server! Error code: " + str(error))
			push_error("FAILED to start server! Error code: " + str(error))
		server_peer = null
		return false
	Zone.server_host = true
	# note: GDScript cannot understand Zone definition unless passed via a variable in the stack.
	var zone_autoload = Zone
	TMSceneSync.start_sync(zone_autoload)

	space_id = _get_server_space_id()

	_last_status_update_time = Time.get_unix_time_from_system()
	multiplayer.set_multiplayer_peer(server_peer)
	multiplayer.peer_connected.connect(_server_on_client_connected)
	multiplayer.peer_disconnected.connect(_server_on_client_disconnected)

	if _is_play_server:
		_setup_play_server()
	else:
		_setup_edit_server()
	Net.zone_socket.init_ws_client()
	print("SUCCESS Starting Mirror Megaverse Server! Listening on port: " + str(port))
	return true


func _get_server_space_id() -> String:
	var config_file := ConfigFile.new()
	var error: Error = config_file.load("user://server.cfg")
	if error == OK:
		var cfg_space_id: String = config_file.get_value("space", "id", "")
		if not cfg_space_id.is_empty():
			return cfg_space_id
	var cmd_line_space_id: String = Util.get_commandline_id_val("space")
	assert(not cmd_line_space_id.is_empty(), "Failed to start server, the space ID was not set. Expected a config setting or a command line argument like: '--server --space 64345dc3866a5facf63a0084'")
	return cmd_line_space_id


func _setup_edit_server() -> void:
	Zone.current_mode = Zone.ZONE_MODE.EDIT
	Net.zone_socket.asset_received.connect(_on_zone_socket_asset_received)
	Net.zone_socket.space_update_received.connect(_on_space_partial_update_received)
	Net.zone_socket.space_object_created.connect(_space_object_created)
	Net.zone_socket.space_object_updated.connect(_space_object_updated)
	Net.zone_socket.space_objects_updated.connect(func(objs: Array): for x in objs: _space_object_updated(x))
	Net.zone_socket.space_object_received.connect(_space_object_received)
	Net.zone_socket.space_object_deleted.connect(_space_object_deleted)
	Net.zone_socket.space_objects_deleted.connect(func(objs: Array): for x in objs: _space_object_deleted({"_id": x}))
	Net.zone_socket.space_objects_page_received.connect(_on_zone_socket_space_object_page_received)
	Net.zone_socket.request_errored.connect(_handle_zone_socket_error)
	Net.zone_socket.ws_connected.connect(_on_edit_server_zone_socket_logged_in, CONNECT_ONE_SHOT)


func _setup_play_server() -> void:
	Zone.current_mode = Zone.ZONE_MODE.PLAY
	var promise = Net.zone_client.server_get_latest_published_space(space_id)
	var published_space = await promise.wait_till_fulfilled()
	if promise.is_error():
		print(promise.get_error_message())
		return
	print_verbose("Server got published space: ", published_space)
	var space: Dictionary = published_space.get("space", {})
	if published_space.has("spaceVariables") and published_space["spaceVariables"] is Dictionary:
		var space_variables: Dictionary = published_space["spaceVariables"]
		# Published spaces should not sync the space variables back to the database (false).
		space_variables_received.emit(space_variables, false)
	if published_space.has("scripts"):
		Net.script_client.load_script_entities_bulk(published_space["scripts"])
	if published_space.has("scriptInstances"):
		space["scriptInstances"] = published_space["scriptInstances"]
	space["play_server"] = true
	Zone.Scene.spawn_template(true, space)
	space_data_received.emit(space)
	var assets: Dictionary = {}
	for asset in published_space.get("assets", []):
		assets[asset["_id"]] = asset
	var space_objs: Array = []
	for space_obj in published_space.get("spaceObjects", []):
		if not assets.has(space_obj.get("asset")):
			continue
		space_obj["asset_data"] = assets[space_obj["asset"]]
		space_objs.append(space_obj)
	for space_obj in space_objs:
		#assert(not space_obj.has("receipt"), "May happen with old spaces, but should not happen with new spaces.")
		if space_obj.has("receipt"):
			space_obj["creator"] = space_obj["receipt"].get("created_by_user", "")
			space_obj.erase("receipt")
	Zone.space_objects = space_objs
	Zone.instance_manager.setup_space_objects()
	space["space_object_count"] = space_objs.size()
	_server_data_received = true


func _server_on_client_connected(in_peer_id: int) -> void:
	# A fix to ensure the client never disconnects from the server unless they hit a 10 second hard timeout
	# for a message
	var peer = server_peer.get_peer(in_peer_id)
	peer.set_timeout(10000, 10000, 15000)
	print("Client connected: ", in_peer_id)


func _server_on_client_disconnected(in_peer_id: int) -> void:
	print("Client disconnected, peer id: ", in_peer_id)
	var disconnected_player_id := ""
	for peer_id in players:
		if in_peer_id == peer_id:
			var player: Player = players[in_peer_id]
			disconnected_player_id = player.get_user_id()

	if disconnected_player_id.is_empty():
		return

	players.erase(in_peer_id)
	Zone.social_manager.remove_player(disconnected_player_id)

	for client_peer_id in players:
		Zone.social_manager.remove_player.rpc_id(client_peer_id, disconnected_player_id)

	_update_server_status()


func _on_edit_server_zone_socket_logged_in() -> void:
	if _is_play_server:
		return
	var promise = Net.zone_socket.get_space(space_id)
	await promise.wait_till_fulfilled()
	if promise.is_error():
		push_error("Critical: cannot start server: ", promise.get_error_message())
		return
	_on_zone_socket_space_received(promise.get_result())
	print("Started getting space objects: ", Time.get_datetime_string_from_system())
	Net.zone_socket.get_space_objects_page(space_id, 1)


## This function is only run for edited build spaces, not published play spaces.
func _on_zone_socket_space_received(space_payload: Dictionary) -> void:
	# Load the space variables data.
	if space_payload.has("spaceVariablesData"):
		var space_variables_data: Dictionary = space_payload["spaceVariablesData"]
		var space_variables: Dictionary = space_variables_data["data"]
		# Non-published spaces should sync the space variables back to the database (true).
		space_variables_received.emit(space_variables, true)
	# Load the space data.
	space_data_received.emit(space_payload)
	if space_payload.has("terrain"):
		Net.zone_socket.get_terrain(space_payload["terrain"])


func _handle_zone_socket_error(request: Dictionary) -> void:
	var event = request.get("event", "")
	var data_id = request.get("data", {}).get("id", "")
	if event == ZoneSocketClient.ZONE_GET_TERRAIN:
		if data_id == Zone.space.get("terrain"):
			push_error("Terrain could not be loaded for id %s. Using defaults." % Zone.space["terrain"])
			Net.zone_socket.terrain_received.emit({"id": Zone.space["terrain"]})
			return
	var error_msg = "Zone Server Socket ERROR, Event: %s, Id: %s" % [event, data_id]
	push_error(error_msg, " ", request)
	print(error_msg)

var _loaded_pages = 0
var _queued_assets = []
func _on_zone_socket_space_object_page_received(space_objects_page: Dictionary) -> void:
	var page = space_objects_page.get("page", 1)
	var total_pages = space_objects_page.get("totalPage", 1)
	var space_objects_arr = space_objects_page.get("result", [])
	_loaded_pages +=1
	print("Loaded page: ", page, " time: ", Time.get_datetime_string_from_system())
	print("Total pages loaded: ", _loaded_pages, " total pages ", total_pages)

	Zone.space_objects.append_array(space_objects_arr)
	# if we've reached the final page, we're done getting all the data
	if _loaded_pages >= total_pages:
		print("All Space Objects Received: ", Time.get_datetime_string_from_system())
		print("Downloading assets for space objects")
		for obj in Zone.space_objects:
			if obj.has("receipt"):
				obj["creator"] = obj["receipt"].get("created_by_user", "")
				obj.erase("receipt")
			# if we already have the asset in memory, no need to get it again
			if not Net.asset_client.get_asset_json(obj["asset"]).is_empty():
				continue
			var asset_id = obj["asset"]
			if not _queued_assets.has(asset_id):
				Net.zone_socket.queue_download_asset(asset_id)
				_queued_assets.push_back(asset_id)
		print("All assets have been queued: ", Time.get_datetime_string_from_system())

		Zone.instance_manager.setup_space_objects()
		_server_data_received = true
		return
	# Get all the next pages
	# Put all the requests in a block and get all the data back much sooner to facilitate this we increased the web socket buffer size.
	if page == 1:
		for page_id in range(2, total_pages+1):
			Net.zone_socket.get_space_objects_page(space_id, page_id)


func _on_zone_socket_asset_received(asset: Variant) -> void:
	var asset_id: String = asset.get("_id", "") if asset is Dictionary else ""
	if asset_id.is_empty() or not Net.asset_client.get_asset_json(asset_id).is_empty():
		return
	# Seems a bit not okay that we need to put some data in client related are like that...
	# We will probably need to refactor how this data is stored at some point
	Net.asset_client.set_asset_json(asset_id, asset)
	_refresh_space_objects_with_asset_id(asset_id, asset)


func _refresh_space_objects_with_asset_id(asset_id: String, asset_data: Dictionary) -> void:
	var related_instance_ids: Array = Zone.get_all_space_instances_ids_using_asset(asset_id)
	for instance_id in related_instance_ids:
		var space_obj = Zone.get_space_instance_from_id(instance_id)
		if space_obj:
			space_obj.on_asset_received(asset_data)


func _on_space_partial_update_received(update: Dictionary) -> void:
	for spath in update["partial_data"]:
		Zone.receive_space_update(spath, update["partial_data"][spath])
		send_data_to_all_clients([Packet.TYPE.SPACE_DATA_CHANGE, {"path": spath, "value": update["partial_data"][spath]}])


@rpc("call_remote", "any_peer", "reliable")
func notification_client_load_completed(in_peer_id) -> void:
	assert(get_multiplayer().get_remote_sender_id() != 0)


func server_create_space_object(properties: Dictionary, receipt: Dictionary = {}) -> void:
	assert(properties.has_all(["position", "rotation", "scale"]), "properties dictionary is missing keys!")
	var new_properties: Dictionary = properties.duplicate(true)
	Net.asset_client.populate_space_object_dict_with_name(new_properties)
	Net.zone_socket.create_space_object(new_properties, receipt)


func send_data_to_server(in_data_array: Array):
	_server_receive_data.rpc_id(SERVER_PEER_ID, in_data_array)


func server_send_data_to_peer(peer_id: int, data_array: Array) -> void:
	sent_data_to_client_requested.emit(peer_id, data_array) # TODO: might consider if Zone.function call is not better for reability


@rpc("call_remote", "any_peer", "reliable")
func _server_receive_data(in_data_array: Array, network_id: int = -1) -> void:
	assert(get_multiplayer().get_remote_sender_id() != 0) # TODO?
	assert(Zone.is_host())
	if network_id == -1:
		network_id = get_multiplayer().get_remote_sender_id()
	_receive_data_server(network_id, in_data_array)


func _receive_data_server(id: int, data_array: Array) -> void:
	var packet_type: int = data_array[0]
	var is_edit_request = not packet_type in [Packet.TYPE.CLIENT_INIT, Packet.TYPE.ZONE_MODE_CHANGE, Packet.TYPE.PREVIEW_READY_CHECK]
	if is_edit_request and Zone.is_in_play_mode():
		return
	match packet_type:
		Packet.TYPE.CLIENT_INIT:
			_init_player(id, data_array[1], data_array[2])
		Packet.TYPE.CREATE_SPACE_OBJECT:
			if data_array.size() == 2:
				_server_create_space_object(data_array[1], {})
			else:
				_server_create_space_object(data_array[1], data_array[2])
		Packet.TYPE.UPDATE_SPACE_OBJECT:
			_server_update_space_object(data_array[1])
		Packet.TYPE.DELETE_SPACE_OBJECT:
			_server_delete_space_object(data_array[1])
		Packet.TYPE.DELETE_SPACE_OBJECTS:
			server_delete_space_objects(data_array[1])
		Packet.TYPE.UPDATE_SPACE_OBJECTS:
			server_update_space_objects(data_array[1])
		Packet.TYPE.PREVIEW_READY_CHECK:
			_server_receive_ready_check(id)
		Packet.TYPE.PREVIEW_READY_CHECK_REJECT:
			_server_cancel_ready_check()
		Packet.TYPE.ZONE_MODE_CHANGE:
			if _is_play_server:
				return
			Zone.change_mode(data_array[1])
			send_data_to_all_clients(data_array, -1)
		Packet.TYPE.TERRAIN_CHANGE:
			_server_update_terrain(data_array[1])
		Packet.TYPE.ENVIRONMENT_CHANGE:
			server_update_environment(data_array[1])
		Packet.TYPE.GLOBAL_SCRIPTS_CHANGE:
			var space_template: SpaceTemplate = Zone.Scene.get_space_template()
			space_template.space_global_scripts.load_global_script_instances(data_array[1])
			server_update_global_scripts(data_array[1])
		_:
			assert(false, "Server Peer: Unrecognized Packet Type.")


func _server_cancel_ready_check() -> void:
	_ready_check_ids.clear()
	_ready_check_expire = 0
	send_data_to_all_clients([Packet.TYPE.PREVIEW_READY_CHECK_REJECT])


func _server_receive_ready_check(id: int) -> void:
	if _is_play_server:
		return
	var now = Time.get_unix_time_from_system()
	if now >= _ready_check_expire:
		_ready_check_ids.clear()
	if _ready_check_ids.size() == 0:
		_ready_check_expire = Time.get_unix_time_from_system() + 60
	var user_id = get_user_id(id)
	if not _ready_check_ids.has(user_id):
		_ready_check_ids.append(user_id)
	# all players are ready, start play
	if _ready_check_ids.size() == players.size():
		_ready_check_expire = 0
		_ready_check_ids.clear()
		Zone.change_mode(Zone.ZONE_MODE.PLAY)
		send_data_to_all_clients([Packet.TYPE.ZONE_MODE_CHANGE, Zone.ZONE_MODE.PLAY], -1)
	# otherwise inform there is a ready check
	else:
		var seconds_left = _ready_check_expire - now
		send_data_to_all_clients([Packet.TYPE.PREVIEW_READY_CHECK, seconds_left, _ready_check_ids])


func server_update_environment(environment: Dictionary) -> void:
	if Zone.space.has("environment"):
		Zone.space["environment"].merge(environment, true)
	else:
		Zone.space["environment"] = environment
	Net.zone_socket.update_environment(Zone.space["environment"])
	send_data_to_all_clients([Packet.TYPE.ENVIRONMENT_CHANGE, Zone.space["environment"]])


func server_update_global_scripts(global_scripts: Array) -> void:
	Zone.space["scriptInstances"] = global_scripts
	Net.zone_socket.update_space(Zone.space)
	send_data_to_all_clients([Packet.TYPE.GLOBAL_SCRIPTS_CHANGE, global_scripts])


func _server_update_terrain(terrain: Dictionary) -> void:
	if not Zone.space.has("terrain_data"):
		print("No terrain entity to update on space.")
		return
	Zone.space["terrain_data"].merge(terrain, true)
	Net.zone_socket.update_terrain(Zone.space["terrain_data"])
	Zone.Scene.get_space_template().receive_terrain_change(Zone.space["terrain_data"])
	send_data_to_all_clients([Packet.TYPE.TERRAIN_CHANGE, Zone.space["terrain_data"]])


func _server_update_space_object(space_obj: Dictionary):
	Zone.instance_manager.update_space_object(space_obj)
	Net.zone_socket.update_space_object(space_obj)


func server_update_space_objects(space_objs: Array) -> void:
	for space_obj in space_objs:
		Zone.instance_manager.update_space_object(space_obj)
	Net.zone_socket.update_space_objects(space_objs)
	var obj_dict: Dictionary = {}
	for obj in space_objs:
		obj_dict[obj["_id"]] = obj
	for i in range(Zone.space_objects.size()):
		var id = Zone.space_objects[i]["_id"]
		if obj_dict.has(id):
			Zone.space_objects[i] = obj_dict[id]
	_server_send_sync_space_objects_to_all(space_objs)


func server_delete_space_objects(space_obj_ids: Array) -> void:
	for space_obj_id in space_obj_ids:
		Zone.instance_manager.remove_space_object_by_id(space_obj_id)
	for i in range(Zone.space_objects.size()-1, -1, -1):
		var id = StringName(Zone.space_objects[i]["_id"])
		if space_obj_ids.has(id):
			Zone.space_objects.pop_at(i)

	# Tell RESTful server (zone_socket)
	Net.zone_socket.delete_space_objects(space_obj_ids)
	_server_send_delete_space_objects_to_all(space_obj_ids)


func _server_create_space_object(space_obj: Dictionary, receipt: Dictionary) -> void:
	space_obj["spaceId"] = space_id
	space_obj["name"] = _get_unique_name(space_obj.get("name", ""))
	if receipt.has("created_by_user"):
		space_obj["creator"] = receipt["created_by_user"]
	Net.zone_socket.create_space_object(space_obj, receipt)


func _get_unique_name(obj_name: String) -> String:
	var i: int = 0
	var space_object_names: Array = []
	for object in Zone.space_objects:
		if not object.has("name"):
			push_error("Found invalid space object name")
			continue
		space_object_names.append(object["name"])
	var new_name: String = obj_name
	while space_object_names.has(new_name):
		new_name = "%s (%s)" % [obj_name, str(i)]
		i += 1
	return new_name


func _server_delete_space_object(space_obj: Dictionary) -> void:
	Net.zone_socket.delete_space_object(space_obj["_id"])


func _server_is_ready(print_reason: bool = false) -> bool:
	var files_downloaded = _all_files_downloaded()
	var is_ready: bool = _server_data_received and files_downloaded
	if print_reason and not is_ready:
		push_error("server is ready? Server data received: ", str(_server_data_received),
			", files downloaded: ", str(files_downloaded),
			", zone preloaded files: ", str(Zone.space_preload_done) )
	return is_ready


func _all_files_downloaded() -> bool:
	return not Net.file_client.is_downloading()


func _init_player(peer_id, jwt, client_version) -> void:
	print("Received client init on server at " + Time.get_datetime_string_from_system())
	# TODO: This only decodes the JWT, but it needs to validated via Firebase SDK (probs via the NestJS server for ease)
	# TODO: Kick the player if JWT validating fails
	var user_id = JWT.get_user_id_from_jwt(jwt, "test123")
	if not _server_is_ready(true):
		push_error("Server not ready for players to join")
		Zone.client_access_denied(peer_id, Zone.DENIED_REASON.SERVER_WARMING_UP)
		return

	if _is_user_with_id_known(user_id):
		print("Zone.server_peer.create_player(): User with an id ", user_id, " already is on the server!")
		Zone.client_access_denied(peer_id, Zone.DENIED_REASON.USER_ID_IN_USE)
		return

	# compare the player's version to the server's version
	if _client_version_mismatch(client_version):
		var version: String = Util.get_version_string()
		print("Client version (%s) does not match server version. (Server: %s)" % [client_version, version])
		Zone.client_access_denied(peer_id, Zone.DENIED_REASON.CLIENT_VERSION_MISMATCH)
		return

	Net.script_client.server_send_script_entities_to_peer(peer_id)
	_create_player(peer_id, user_id)
	if _ready_check_expire != 0:
		_server_cancel_ready_check()


func _create_player(new_player_peer_id: int, new_user_id: String) -> void:
	# Notify client, connection successful.
	Zone.client_access_granted(new_player_peer_id)
	# Spawn new player on server.
	var new_player_data: Dictionary = {
		"user_id": new_user_id,
		"peer_id": new_player_peer_id,
	}
	var player = Zone.social_manager.spawn_player(new_player_data)
	# Spawn that new player for new user.
	Zone.social_manager.spawn_player.rpc_id(new_player_peer_id, new_player_data)
	# Spawn that new player for existing participants.
	for other_peer_id in players:
		Zone.social_manager.spawn_player.rpc_id(other_peer_id, new_player_data)
	# Spawn other participants on that new client.
	for other_peer_id in players:
		var other_player: Player = players[other_peer_id]
		var other_player_data: Dictionary = other_player.serialize_player_data_for_network()
		Zone.social_manager.spawn_player.rpc_id(new_player_peer_id, other_player_data)
	players[new_player_peer_id] = player
	_server_send_sync_space(new_player_peer_id)
	_update_server_status()


func _client_create_objects(client_peer_id_to_sync: int, space_objects: Array) -> void:
	for space_object_data in space_objects:
		var so_id = space_object_data["_id"]
		var so_instance = Zone.get_space_instance_from_id(so_id)
		if not is_instance_valid(so_instance):
			continue
		var properties_to_send = {}
		for prop_name in so_instance.get_additional_properties_names():
			properties_to_send[prop_name] = so_instance.get_additional_property(prop_name)
		var receipt: Dictionary = {} # Empty receipt because these are not newly placed objects.
		# disabled because this breaks loading a space the second connection attempt
		if space_object_data.has("receipt"):
			space_object_data.erase("receipt")
			push_error("The SpaceObject itself should not have a receipt.")
		Zone.client_create_object(client_peer_id_to_sync, space_object_data, receipt, properties_to_send)


func _server_send_sync_space(client_peer_id_to_sync: int) -> void:
	var obj_sorted_by_dst: Array = _get_unique_space_objects_sorted_by_dst_to_spawn()
	Zone.space["space_object_count"] = obj_sorted_by_dst.size()
	Zone.send_space_data_to_client(client_peer_id_to_sync, Zone.space, Zone.current_mode)
	var obj_with_preload = obj_sorted_by_dst.filter(func(obj): return obj.get("preloadBeforeSpaceStarts", false))
	_client_create_objects(client_peer_id_to_sync, obj_with_preload)
	var obj_without_preload = obj_sorted_by_dst.filter(func(obj): return not obj.get("preloadBeforeSpaceStarts", false))
	_client_create_objects(client_peer_id_to_sync, obj_without_preload)
	Zone.script_network_sync.server_replace_all_data_on_peer(client_peer_id_to_sync)


func _get_unique_space_objects_sorted_by_dst_to_spawn() -> Array:
	var all_objs: Array = Zone.space_objects.duplicate()
	var no_duplicates = []
	for index in range(all_objs.size()):
		var dup_exists_after = false
		for sub_index in range(index + 1, all_objs.size()):
			if all_objs[index]["_id"] == all_objs[sub_index]["_id"]:
				# To prevent the client ingesting invalid objects that have been duplicated. It alleviates the issue for now and lets us release.
				# If they get to the client nothing works properly. I will fix this in a follow up PR properly.
				push_error("Duplicate ID found in the server list of objects, I have skipped it: ", all_objs[index]["_id"])
				dup_exists_after = true
				break
		if not dup_exists_after:
			no_duplicates.append(all_objs[index])
	no_duplicates.sort_custom(_sort_by_dst_to_origin)
	return no_duplicates


func _sort_by_dst_to_origin(in_a, in_b):
	var position_a = Serialization.array_to_vector3(in_a["position"])
	var position_b = Serialization.array_to_vector3(in_b["position"])
	var a_dst = position_a.length_squared()
	var b_dst = position_b.length_squared()
	return a_dst < b_dst


func _update_server_status() -> void:
	var player_count: int = players.size()
	var users_present: Array = []
	for user in players.values():
		if is_instance_valid(user):
			users_present.append(user.name)
	var secs_server_empty: float = 0
	var now: float = Time.get_unix_time_from_system()
	_last_status_update_time = now
	if player_count == 0:
		if _server_empty_time == 0:
			_server_empty_time = now
		secs_server_empty = now-_server_empty_time
	else:
		_server_empty_time = 0
	var status = {
		"players": player_count,
		"usersPresent": users_present,
		"secondsEmpty": roundf(secs_server_empty), # less data to transfer
		"mode": Zone.current_mode,
		"version": Util.get_version_string()
	}
	Net.zone_socket.update_status(status)


func _is_user_with_id_known(in_client_id: String) -> bool:
	for player_peer_id in players:
		var player: Player = players[player_peer_id]
		if player.get_user_id() == in_client_id:
			return true
	return false


func _client_version_mismatch(client_version: String) -> bool:
	var zone_server_version: String = Util.get_version_string()
	return zone_server_version != client_version


func get_user_id(network_id: int) -> StringName:
	if not players.has(network_id):
		return &""
	var player: Player = players[network_id]
	return player.get_user_id()


func send_data_to_all_clients(data_array: Array, exception_id := 0) -> void:
	for player_peer_id in players:
		if player_peer_id != exception_id:
			server_send_data_to_peer(player_peer_id, data_array)
