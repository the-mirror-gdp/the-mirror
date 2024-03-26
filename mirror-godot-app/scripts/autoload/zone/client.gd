class_name Client
extends Node


# socket signals
signal connected
signal disconnected
# joiner signals
signal join_server_start()
signal join_server_complete()
signal join_server_info_updated(space_data: Dictionary)
signal join_server_status_changed(status_text: String)

const _JOIN_RETRY_TIME: int = 5.0
const _LOCALHOST: String = "LOCALHOST"
const _SERVER_STATE_KEY: String = "state"
const _SERVER_STATE_READY: String = "READY"
const _SERVER_STATE_FAILED: String = "FAILED"
const _FIND_SPACE_ZONE_TIMEOUT_SECONDS: float = 90.0
const _FIND_SPACE_ZONE_RETRY_SECONDS: float = 4.0

var pid = null

var client_peer: ENetMultiplayerPeer = null
var retry_count = 0
var last_connection_address: String = ""
var last_connection_port: int = -1
var _find_zone_start_time: float
var _queued_zone_id: String = ""
var _queued_space_id: String = ""
var _queued_beta: bool = false
var _last_status: String
var current_zone: Dictionary = {}
var _next_retry_time: float = 0.0
var _is_joining_play_space: bool = false


enum JOINER_ERRORS {
	ACCESS_DENIED = 0,
	ACCOUNT_IN_USE,
	ACCOUNT_JOINED,
	VERSION_MISMATCH,
	SERVER_ERROR,
	UNKNOWN_ERROR,
	CLIENT_TIMEOUT,
}

# resolutions for errors in the enum above
var JOINER_RESOLUTIONS = {
	JOINER_ERRORS.ACCESS_DENIED : tr("You may need to request access to this space"),
	JOINER_ERRORS.ACCOUNT_IN_USE :  tr("Your account is currently in use, please log out of the other computer."),
	JOINER_ERRORS.ACCOUNT_JOINED :  tr("Someone with your account joined this server, please ensure nobody is using your account"),
	JOINER_ERRORS.VERSION_MISMATCH :  tr("You are running an older version of the game, please go to itch.io and check for updates. You can find more information here [url]https://docs.themirror.space/docs/get-started[/url]"),
	JOINER_ERRORS.SERVER_ERROR :  tr("The server reported an unforseen error, please report this issue on our discord at [url]https://discord.gg/pf96gDtpXD[/url]"),
	JOINER_ERRORS.UNKNOWN_ERROR :  tr("There was an unknown error, please report this issue on our discord at [url]https://discord.gg/pf96gDtpXD[/url]"),
	JOINER_ERRORS.CLIENT_TIMEOUT :  tr("You experienced a network issue with your internet or with the server, you can try rejoining or you can report an issue here [url]https://discord.gg/pf96gDtpXD[/url]")
}

func get_error_solution(error: JOINER_ERRORS):
	return JOINER_RESOLUTIONS[error]


func _ready() -> void:
	Deeplinking.join_zone_requested.connect(_on_deeplink_join_zone_requested)
	Deeplinking.join_space_requested.connect(_on_deeplink_join_space_requested)
	Deeplinking.join_as_guest.connect(_on_deeplink_join_space_requested)
	Deeplinking.join_beta_requested.connect(_on_deeplink_join_beta_requested)


func _process(_delta: float) -> void:
	_process_retry_join()



func _notification(what: int) -> void:
	match what:
		NOTIFICATION_EXIT_TREE:
			if is_instance_valid(client_peer):
				_disconnect_from_server()
		NOTIFICATION_READY:
			# Class meant to be used internally by Zone object
			assert(get_parent() == Zone)
		NOTIFICATION_WM_CLOSE_REQUEST:
			## Child processes are NOT closed with parent automatically.
			## So we need to manually close the local server on all the normal app exits.
			## We want to close the server when the client closes.
			quit()


func quit(quit_code:= 0):
	if pid:
		OS.kill(pid)
	get_tree().quit()


func connect_to_server_by_string(text: String) -> void:
	if text.is_empty():
		push_error("cant connect to IP without the correct format 127.0.0.1:27015")
		return
	var split = text.split(":")
	if split.size() != 2:
		push_error("cant connect to IP without the correct format 127.0.0.1:27015")
		return
	var ip_address = split[0]
	var port = int(split[1])
	connect_to_server(ip_address, port)


# signal called only on a client by the UI, when the space is done loading.
func _client_on_game_ui_space_loaded() -> void:
	assert(not Zone.is_host())
	var client_peer_id = get_multiplayer().get_unique_id()
	Zone.server.notification_client_load_completed.rpc_id(Zone.SERVER_PEER_ID, client_peer_id)


## connect_to_server
func connect_to_server(server_addr: Variant, port: Variant) -> bool:
	if server_addr.is_empty():
		return false
	client_peer = ENetMultiplayerPeer.new()
	Zone.instance_manager.space_objects_created.connect(_client_on_game_ui_space_loaded)
	var error_status := client_peer.create_client(server_addr, port)
	last_connection_address = server_addr
	last_connection_port = port
	print("Connection error status OK? " + str(error_status == OK))
	var multiplayer_state = get_tree().get_multiplayer()
	if not multiplayer_state.connected_to_server.is_connected(_client_on_connected_to_server):
		multiplayer_state.connected_to_server.connect(_client_on_connected_to_server)
	if not multiplayer_state.connection_failed.is_connected(_connection_failed):
		multiplayer_state.connection_failed.connect(_connection_failed)
	if not multiplayer_state.server_disconnected.is_connected(_client_on_server_disconnected):
		multiplayer_state.server_disconnected.connect(_client_on_server_disconnected)
	multiplayer_state.set_multiplayer_peer(client_peer)
	# A fix to ensure the client never disconnects from the server unless they hit a 10 second hard timeout
	# for a message
	var peer = client_peer.get_peer(Zone.SERVER_PEER_ID)
	peer.set_timeout(10000, 10000, 15000)
	return error_status == OK


func is_space_loaded() -> bool:
	if Zone.space.is_empty():
		return false
	if Zone.space.get("play_server", false):
		return Zone.space_ready
	return Zone.space_preload_done


func _connection_failed() -> void:
	print("Connection failed... retrying")
	if retry_count < 3 and not last_connection_address.is_empty():
		connect_to_server(last_connection_address, last_connection_port)
		retry_count += 1
	else:
		# we failed to connect properly
		_client_on_server_disconnected()
		push_error("Failed to connect to server - initiating slower retry")
		Analytics.track_event_client(AnalyticsEvent.TYPE.SPACE_JOIN_ATTEMPT_FAIL, {"spaceId": _queued_space_id})


func _client_on_connected_to_server() -> void:
	print("----------------------------------------")
	print("ClientPeer: Connected to a server... waiting for server to grant access")
	print("----------------------------------------")

	Analytics.track_event_client(AnalyticsEvent.TYPE.SPACE_JOIN_ATTEMPT_SUCCESS, {"spaceId": _queued_space_id})
	Zone.change_to_space_scene()
	Zone.instance_manager.reset_all_instances()
	# TODO: Instead of true, determine if the player has creator permissions for the space.
	GameUI.on_enter_space(true)

	var client = Node.new()
	client.set_name("Client " + str(multiplayer.get_unique_id()))
	Zone.add_child(client)

	var jwt = Firebase.Auth.get_jwt()
	var user_id = JWT.get_user_id_from_jwt(jwt, "test123")
	var client_version: String = str(Util.get_version_string())
	Zone.send_data_to_server([Packet.TYPE.CLIENT_INIT, jwt, client_version])
	PlayerData.acknowledge_local_user_id(user_id)

	# note: GDScript cannot understand Zone definition unless passed via a variable in the stack.
	var zone_autoload = Zone
	TMSceneSync.start_sync(zone_autoload)

	# wait for the space to be in a loaded enough condition to join.
	# play servers load all objects before finishing
	# wait for the first spawn to complete too
	while not is_space_loaded():
		await get_tree().create_timer(0.5).timeout
	join_server_complete.emit()


func is_client_connected_to_server() -> bool:
	if Zone.server_host:
		return false
	if not Zone.bootup_completed:
		return false
	if not client_peer or not is_instance_valid(client_peer):
		return false
	var multiplayer_peer = multiplayer.multiplayer_peer
	if not multiplayer.has_multiplayer_peer():
		return false
	# NOTE: OfflineMultiplayerPeer if set will break is_server().
	elif multiplayer_peer is OfflineMultiplayerPeer:
		return false
	# NOTE: is_server() will always return true if OfflineMultiplayerPeer is used.
	# In the engine it will always return true.
	elif multiplayer.is_server():
		return false
	return multiplayer_peer.get_connection_status() == MultiplayerPeer.ConnectionStatus.CONNECTION_CONNECTED


@rpc("call_remote", "authority", "reliable")
func access_granted() -> void:
	connected.emit()
	print("ClientPeer: Access granted")


@rpc("call_remote", "authority", "reliable")
func access_denied(in_reason: int) -> void:
	assert(not Zone.is_host())
	if in_reason == Zone.DENIED_REASON.SERVER_WARMING_UP:
		initiate_retry()
		return
	if in_reason == Zone.DENIED_REASON.USER_ID_IN_USE and not current_zone.is_empty():
		printerr("User already connected to space. Trying to kick out user logged in other place")
		var current_zone_dup = current_zone.duplicate()
		Net.space_client.kick_me_from_spaces(current_zone.get("_id"))
		await initiate_retry()
		current_zone = current_zone_dup # override current_zone so next retry could happen
		return
	_disconnect_from_server()
	Zone.on_exit_space()
	GameUI.loading_ui.hide()
	quit_to_main_menu()
	if in_reason == Zone.DENIED_REASON.CLIENT_VERSION_MISMATCH:
		Game.critical_error(JOINER_ERRORS.ACCESS_DENIED, "Server/Client Version Mismatch. Update your game using the itch.io launcher, or reinstall the app from itch.io")
		quit_to_main_menu()
	if in_reason == Zone.DENIED_REASON.KICKED_OUT_OF_SPACE:
		Game.critical_error(JOINER_ERRORS.ACCOUNT_IN_USE, "An account with your user on different machine just joined the server")
		quit_to_main_menu()
	if in_reason == Zone.DENIED_REASON.USER_ID_IN_USE:
		Game.critical_error(JOINER_ERRORS.ACCOUNT_IN_USE, "An account with your user joined the server")
		quit_to_main_menu()


@rpc("call_remote", "authority", "reliable")
func client_create_object(new_space_object_data: Dictionary, receipt: Dictionary, additional_data: Dictionary) -> void:
	Zone.instance_manager.create_space_object(new_space_object_data, receipt)
	Zone.space_objects.append(new_space_object_data)

	if not additional_data.is_empty():
		var so_id = new_space_object_data["_id"]
		var so = Zone.get_space_instance_from_id(so_id)
		for key in additional_data:
			var value = additional_data[key]
			so.set_additional_property(key, value)
	var space_object_count = Zone.space.get("space_object_count", 0)
	if space_object_count == 0:
		return
	var current_count = Zone.space_objects.size()
	if space_object_count == 0:
		return
	if current_count == space_object_count:
		print("Received %d space_objects" % space_object_count)
		Zone.instance_manager.client_await_assets_loaded()


@rpc("call_remote", "any_peer", "reliable")
func client_receive_space_data(in_space_data: Dictionary, in_mode) -> void:
	# NOTE: This function is always executed on the client.
	# Now let's start sync on the client.
	var need_template_spawned: bool = Zone.space.is_empty() and Zone.Scene
	Zone.space = in_space_data
	if in_space_data.has("scriptIds"):
		Net.script_client.load_script_entities_for_ids(in_space_data["scriptIds"])
	if need_template_spawned:
		assert(Zone.is_client())
		Zone.Scene.spawn_template(false, Zone.space)
	Zone.change_mode(in_mode)
	var space_object_count = Zone.space.get("space_object_count", null)
	if space_object_count == 0:
		Zone.space_ready = true
		Zone.space_preload_done = true


## this is used to detect any client failures and automatically heal from those failures
func _client_on_server_disconnected() -> void:
	if last_connection_address.is_empty():
		return
	# initiate retry
	await get_tree().create_timer(1).timeout
	initiate_retry()
	print("initiate retry")


## call this when the user wants to disconnect
func quit_to_main_menu() -> void:
	last_connection_address = ""
	last_connection_port = -1
	GameUI.loading_ui.hide()
	GameUI.main_menu_ui.show()
	_quit_space()


## call this when you need to show the loading screen and are already connecting
func _quit_to_loading_screen() -> void:
	GameUI.loading_ui.show()
	if is_instance_valid(GameUI.main_menu_ui):
		GameUI.main_menu_ui.hide()
	_quit_space()


## quit space closes the socket and informs the game code it is time to reset.
func _quit_space() -> void:
	_disconnect_from_server()
	Zone.on_exit_space()
	current_zone = {}
	_last_status = ""
	_next_retry_time = 0.0
	_is_joining_play_space = false
	disconnected.emit()


## internally this is used to disconnect the socket nothing more
## we use this when we rejoin and it allows us to immediately retry without consequences like losing
## objects we have already spawned for example.
func _disconnect_from_server() -> void:
	if is_instance_valid(client_peer):
		client_peer.close()
		client_peer = null


func send_data_to_client(in_client_peer_id: int, in_data: Array) -> void:
	_receive_data.rpc_id(in_client_peer_id, in_data)


func send_data_to_all_clients(data_array) -> void:
	var peers = get_tree().get_multiplayer().get_peers()
	for peer_id in peers:
		if peer_id == Zone.SERVER_PEER_ID:
			continue
		_receive_data.rpc_id(peer_id, data_array)


@rpc("call_remote", "any_peer", "reliable")
func _receive_data(in_data_array) -> void:
	assert(not Zone.is_host())
	receive_client_update(in_data_array)


func receive_client_update(data_array: Array) -> void:
	var packet_type: int = data_array[0]
	var is_edit_request = not packet_type in [Packet.TYPE.CLIENT_INIT, Packet.TYPE.ZONE_MODE_CHANGE]
	if is_edit_request and Zone.is_in_play_mode():
		return
	match packet_type:
		Packet.TYPE.ZONE_MODE_CHANGE:
			Zone.change_mode(data_array[1])
		Packet.TYPE.UPDATE_SPACE_OBJECT:
			Zone.receive_sync_space_object(data_array[1])
		Packet.TYPE.UPDATE_SPACE_OBJECTS:
			Zone.receive_sync_space_objects(data_array[1])
		Packet.TYPE.DELETE_SPACE_OBJECTS:
			Zone.receive_delete_space_objects(data_array[1])
		Packet.TYPE.SPACE_DATA_CHANGE:
			Zone.receive_space_update(data_array[1].get("path", ""), data_array[1].get("value"))
		Packet.TYPE.TERRAIN_CHANGE:
			Zone.Scene.get_space_template().receive_terrain_change(data_array[1])
		Packet.TYPE.ENVIRONMENT_CHANGE:
			var space_template: SpaceTemplate = Zone.Scene.get_space_template()
			space_template.space_environment.apply_from_dictionary(data_array[1])
		Packet.TYPE.GLOBAL_SCRIPTS_CHANGE:
			var space_template: SpaceTemplate = Zone.Scene.get_space_template()
			space_template.space_global_scripts.load_global_script_instances(data_array[1])
		Packet.TYPE.PREVIEW_READY_CHECK_REJECT:
			Zone.ready_check_rejected.emit()
			Notify.error("Preview Canceled", "Ready check was rejected.")
		Packet.TYPE.PREVIEW_READY_CHECK:
			var seconds_left = data_array[1]
			var ready_ids = data_array[2]
			Zone.ready_check_started.emit(ready_ids, seconds_left)
		_:
			assert(false, "Client Peer: Unrecognized Packet Type.")


func client_send_create_space_object(properties: Dictionary, receipt: Dictionary) -> void:
	assert(properties.has_all(["position", "rotation", "scale"]), "properties dictionary is missing keys!")
	assert(not properties.has("receipt"), "The SpaceObject properties should not have the receipt in it.")
	Net.asset_client.populate_space_object_dict_with_name(properties)
	# Send the create space object packet to the server.
	var packet: Array = [Packet.TYPE.CREATE_SPACE_OBJECT, properties]
	if not receipt.is_empty():
		assert(Zone.receipt_validate(receipt), "client_peer: receipt has wrong structure!")
		packet.append(receipt)
	Zone.send_data_to_server(packet)


func cancel_join_request() -> void:
	if Zone.is_client():
		_disconnect_from_server()
	quit_to_main_menu()


func initiate_retry() -> void:
	if last_connection_address.is_empty():
		return
	print("Initiate join retry")
	await get_tree().create_timer(_JOIN_RETRY_TIME).timeout
	_quit_to_loading_screen()
	connect_to_server(last_connection_address, last_connection_port)


## check the space or zone for a version mismatch
func _check_for_version_mismatch(zone_or_space: Dictionary) -> bool:
	var zone_version = zone_or_space.get("gdServerVersion", "")
	var client_version = Util.get_version_string()
	if zone_version is String and not zone_version.is_empty() and client_version != zone_version:
		quit_to_main_menu()
		var mismatch_str = "Update your game client, You have " + client_version + ", server has " + zone_version + "."
		Game.critical_error(JOINER_ERRORS.VERSION_MISMATCH, mismatch_str)
		return false
	return true


func start_join_zone_by_zone_id(zone_id) -> void:
	join_server_status_changed.emit("Finding Server...")
	if zone_id == _LOCALHOST:
		_join_localhost()
		return
	_disconnect_from_server_peer()
	_find_zone_start_time = Time.get_unix_time_from_system()
	_find_zone_by_zone_id(zone_id)


func start_join_localhost() -> void:
	start_join_zone_by_space_id(_LOCALHOST)


func start_join_zone_by_space_id(space_id: String) -> void:
	_is_joining_play_space = false
	join_server_start.emit()
	if space_id == _LOCALHOST:
		_join_localhost()
		return
	_disconnect_from_server_peer()
	_find_zone_start_time = Time.get_unix_time_from_system()
	_find_zone_by_space(space_id)


func start_join_play_space_by_space_id(space_id: String) -> void:
	join_server_start.emit()
	_disconnect_from_server_peer()
	_is_joining_play_space = true # after disconnect so flag is not cleared
	_find_zone_start_time = Time.get_unix_time_from_system()
	_find_play_space(space_id)


func start_join_play_space_by_zone_id(zone_id: String) -> void:
	join_server_start.emit()
	_disconnect_from_server_peer()
	_is_joining_play_space = true # after disconnect so flag is not cleared
	_find_zone_start_time = Time.get_unix_time_from_system()
	_find_play_space_by_zoneid(zone_id)


func _process_retry_join() -> void:
	if _next_retry_time <= 0.0:
		return
	if current_zone.is_empty():
		print("current zone is empty cannot retry!")
		_next_retry_time = 0.0
		return
	if Time.get_unix_time_from_system() >= _next_retry_time and current_zone.has("space"):
		_next_retry_time = 0.0
		if _is_joining_play_space:
			_find_play_space_by_zoneid(current_zone["_id"])
		else:
			_find_zone_by_space(current_zone["space"])


func _on_deeplink_join_beta_requested() -> void:
	# if not logged in, queue the hardcoded join beta signal
	if not Net.is_fully_logged_in():
		_queued_beta = true
		@warning_ignore("return_value_discarded")
		Net.fully_logged_in.connect(_on_logged_in_join_beta, CONNECT_ONE_SHOT)
		return
	_join_hardcoded_server()


func _join_hardcoded_server() -> void:
	var use_hardcoded = ProjectSettings.get_setting("feature_flags/hardcoded_servers", false)
	if not use_hardcoded:
		return
	# find the first hard coded server and join it
	var server_list = Util.get_project_settings_zones_array()
	for server in server_list:
		if server.has("ipAddress") and server.has("port"):
			connect_to_server(server["ipAddress"], server["port"])
			return


func _on_deeplink_join_space_requested(space_id: String) -> void:
	if current_zone.get("space") == space_id and not _is_joining_play_space:
		return
	start_join_zone_by_space_id(space_id)


func _on_deeplink_join_zone_requested(zone_id: String) -> void:
	if current_zone.get("space") == zone_id and _is_joining_play_space:
		return
	start_join_zone_by_zone_id(zone_id)


func _on_logged_in_join_space() -> void:
	if _queued_space_id.is_empty():
		return
	start_join_zone_by_space_id(_queued_space_id)
	_queued_space_id = ""


func _on_logged_in_join_zone() -> void:
	if _queued_zone_id.is_empty():
		return
	start_join_zone_by_zone_id(_queued_zone_id)
	_queued_zone_id = ""


func _on_logged_in_join_beta() -> void:
	if not _queued_beta:
		return
	_join_hardcoded_server()
	_queued_beta = false


func _join_new_server_locally(space_id: String) -> bool:
	# When we can ask mirror-web-server for an already existing server to connect to, first
	# Then we will replace that flag, with that request being done and responded.
	var should_create_a_new_server_locally = ProjectSettings.get_setting("feature_flags/always_spin_up_local_server", false)
	if should_create_a_new_server_locally:
		if pid != null:
			OS.kill(pid)
		var firebase_auth = str(Firebase.Auth.auth.refreshtoken)
		print(firebase_auth)
		# For debugging this allows you to grab breakpoints from the server "--remote-debug", "tcp://127.0.0.1:6008"]
		# If enabled it could cause join time to be much longer when booting server
		var arguments = ["--server", "--space", space_id, "--mode", "edit", "--uuid", "localhost", "--server_login", firebase_auth, "--headless"]
		print("SERVER ARGS: ", arguments)
		pid = OS.create_process(OS.get_executable_path(), arguments, true)
		start_join_localhost()
		return true
	return false

func _find_zone_by_space(space_id: String) -> void:
	if _join_new_server_locally(space_id):
		return
	# Normal join process with dedicated servers
	var promise = Net.zone_finder.join_build_server(space_id)
	var build_server = await promise.wait_till_fulfilled()
	if promise.is_error():
		Game.critical_error(JOINER_ERRORS.UNKNOWN_ERROR, "Something went wrong" + promise.get_error_message())
		return

	_on_find_space_zone_received(build_server)


func _find_play_space(space_id: String) -> void:
	if _join_new_server_locally(space_id):
		return
	var promise = Net.zone_finder.join_play_server(space_id)
	var play_space = await promise.wait_till_fulfilled()
	if promise.is_error():
		Game.critical_error(JOINER_ERRORS.ACCESS_DENIED, "Please report this error " + promise.get_error_message())
		return
	_on_find_space_zone_received(play_space)

func _find_play_space_by_zoneid(zone_id: String) -> void:
	var promise = Net.zone_finder.join_play_server_by_zone_id(zone_id)
	var play_space = await promise.wait_till_fulfilled()
	if promise.is_error():
		Game.critical_error(JOINER_ERRORS.ACCESS_DENIED, "failed to access space" + promise.get_error_message())
		return
	_on_find_space_zone_received(play_space)


func _on_find_space_zone_received(space_or_zone: Dictionary) -> void:
	if not _check_for_version_mismatch(space_or_zone):
		return
	_next_retry_time = 0.0
	var zone_server_state = space_or_zone[_SERVER_STATE_KEY]
	join_server_info_updated.emit(space_or_zone)
	if zone_server_state == _SERVER_STATE_READY:
		# space_or_zone is ready, connect to it!
		join_server_status_changed.emit("Connecting...")
		current_zone = space_or_zone
		print("current space_or_zone: ", current_zone)
		connect_to_server(space_or_zone["ipAddress"], space_or_zone["port"])
		return
	if zone_server_state == _SERVER_STATE_FAILED:
		Game.critical_error(JOINER_ERRORS.SERVER_ERROR, "Server failed to launch")
		quit_to_main_menu()
		return
	current_zone = space_or_zone
	print("current zone", current_zone)
	var now: float = Time.get_unix_time_from_system()
	if _last_status != zone_server_state:
		_find_zone_start_time = now

	join_server_status_changed.emit(zone_server_state)
	_last_status = zone_server_state
	# wait and request space again when the status is good
	_poll_server_status()

## polls the backend to check if the valid IP has been put in place, see _process for how this is handled.
func _poll_server_status():
	_next_retry_time = Time.get_unix_time_from_system() + _FIND_SPACE_ZONE_RETRY_SECONDS

func _find_zone_by_zone_id(zone_id: String) -> void:
	var promise = Net.zone_finder.get_zone(zone_id)
	var zone = await promise.wait_till_fulfilled()
	if promise.is_error():
		Game.critical_error(JOINER_ERRORS.UNKNOWN_ERROR, "Failed to find server by zone id: " + promise.get_error_message())
		return
	_on_get_zone_received(zone)


func _on_get_zone_received(zone: Dictionary) -> void:
	var zone_server_state = zone[_SERVER_STATE_KEY]
	if zone_server_state == _SERVER_STATE_READY:
		# zone is ready, connect to it!
		connect_to_server(zone["ipAddress"], zone["port"])
		return
	Game.critical_error(JOINER_ERRORS.CLIENT_TIMEOUT, "Server status: %" % zone_server_state)


func _disconnect_from_server_peer() -> void:
	print("code requested disconnect from server")
	current_zone = {}
	_is_joining_play_space = false
	_disconnect_from_server()


func _join_localhost() -> void:
	var cmd_line_space_id: String = Util.get_commandline_id_val("space")
	if not cmd_line_space_id.is_empty():
		# This will make kicking out mechanism work on localhost when launched from editor.
		current_zone = {"_id": cmd_line_space_id}
	connect_to_server(_LOCALHOST, ProjectSettings.get_setting("mirror/zone_server_port"))
