extends Node


signal logged_in()
signal fully_logged_in()

# Restful API network Connected client classes
@onready var mirror_auth_client: MirrorAuth = MirrorAuth.new()
@onready var user_client: UserClient = UserClient.new()
@onready var asset_client: AssetClient = AssetClient.new()
@onready var file_client: FileClient = FileClient.new()
@onready var material_client: MaterialClient = MaterialClient.new()
@onready var script_client: ScriptClient = ScriptClient.new()
@onready var space_client: SpaceClient = SpaceClient.new()
@onready var environment_client: EnvironmentClient = EnvironmentClient.new()
@onready var terrain_client: TerrainClient = TerrainClient.new()
@onready var group_client: GroupClient = GroupClient.new()
@onready var zone_finder: ZoneFinder = ZoneFinder.new()
@onready var zone_client: ZoneClient = ZoneClient.new()
@onready var version_client: VersionClient = VersionClient.new()
@onready var zone_socket: ZoneSocketClient = ZoneSocketClient.new()
@onready var http_universal_client: MirrorHttpClient = MirrorHttpClient.new()


# The mongo_id of the user profile
var user_id: String


func _ready() -> void:
	add_child(user_client)
	add_child(asset_client)
	add_child(file_client)
	add_child(script_client)
	add_child(material_client)
	add_child(space_client)
	add_child(group_client)
	add_child(version_client)
	add_child(environment_client)
	add_child(terrain_client)
	add_child(zone_client)
	add_child(zone_socket)
	add_child(zone_finder)
	add_child(http_universal_client)
	add_child(mirror_auth_client)
	Firebase.Auth.token_refresh_succeeded.connect(_on_token_refreshed)


func get_current_user_name() -> String:
	return user_client.try_get_user_name(user_id)


func logout() -> void:
	Analytics.track_event_client(AnalyticsEvent.TYPE.LOGOUT_SUCCESS, {"distinct_id": user_id})
	user_id = ""
	user_client.logout_reset_current_user_profile()
	space_client.user_spaces.clear()
	group_client.user_groups.clear()
	Firebase.Auth.logout()
	print("Logged out.")


## Returns true if the session token is populated
# TODO: remove this method - METHOD dupe from Firebase.Auth.is_logged_in()
func is_logged_in() -> bool:
	return not Firebase.Auth.get_jwt().is_empty()


## Returns true if the session token is populated
func is_fully_logged_in() -> bool:
	return is_logged_in() and not user_client.get_current_user_profile().is_empty()


## Called when a login is successful. Populates the user id and token.
func login_success(mongo_id: String, _idtoken: String) -> void:
	user_id = mongo_id
	# print("JWT token check ", str(Firebase.Auth.get_jwt()))
	print("Firebase Logged In As %s" % str(user_id))
	logged_in.emit()
	Analytics.track_event_client(AnalyticsEvent.TYPE.LOGIN_USER_SUCCESS, {"distinct_id": user_id})
	# hardware analytics
	var properties = {}
	properties.cpu_info = OS.get_processor_name()
	properties.cpu_cores = OS.get_processor_count()
	properties.distinct_id = user_id

	# some client might be run headlessly
	if RenderingServer:
		properties.video_adapter_name = RenderingServer.get_video_adapter_name()
		properties.video_adapter_type = RenderingServer.get_video_adapter_type()
		properties.video_adapter_vendor = RenderingServer.get_video_adapter_vendor()

	Analytics.track_event_client(AnalyticsEvent.TYPE.CLIENT_STARTUP, properties)


func _on_token_refreshed(auth: Dictionary) -> void:
	if user_id != auth.get("localid"):
		return
	print("Session Refreshed new JWT: ", Firebase.Auth.get_jwt())


func fully_log_in_user_with_profile(profile: Dictionary, auth_result: Dictionary) -> void:
	#print("Activated Profile for user %s %s" % [str(profile.get("displayName", "")), str(profile.get("email", ""))])
	login_success(profile["_id"], auth_result["idtoken"])
	user_client.set_current_user_profile(profile)
	fully_logged_in.emit()


## Fetches the data that belongs to a user.
func wait_for_current_user_data() -> Promise:
	assert(not user_id.is_empty())
	return user_client.get_user_profile(user_id)


@rpc("call_remote", "any_peer", "reliable")
func _request_synchronization_of_asset(asset_id: String) -> void:
	asset_client.queue_download_asset(asset_id)


@rpc("call_remote", "any_peer", "reliable")
func request_synchronization_of_asset(asset_id: String) -> void:
	var host = "[server]" if Zone.is_host() else "[client]"
	print("%s Requesting update of asset" % host)
	if asset_id.is_empty():
		printerr("Synchronization requested but invalid asset id!")
		return
	if Zone.is_host():
		# The server should propagate the team to other clients.
		zone_socket.queue_download_asset(asset_id)
		_request_synchronization_of_asset.rpc(asset_id)
	else:
		request_synchronization_of_asset.rpc_id(Zone.SERVER_PEER_ID, asset_id)
