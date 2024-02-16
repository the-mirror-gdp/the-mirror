extends BaseIntegrationTest

@onready var _TEST_SPACE_ID: String = ProjectSettings.get_setting("mirror/integration_test_ids").get("space_id", "")

var _jwt_backup_secret_token = null


func _init() -> void:
	_test_queue = [
		&"test_login_zone",
		# We are not using a Voxel module anymore 12.05.2023
		#&"test_update_space_voxels",
		#&"test_clear_space_voxels",
		#&"test_get_space_voxels",
		&"test_get_latest_published_space_version",
		&"test_cleanup_login_zone"
	]


func test_login_zone() -> void:
	_jwt_backup_secret_token = Firebase.Auth.auth['idtoken']
	#this ovewrites token from JWT to simulate godot-server
	Firebase.Auth.auth['idtoken'] = Util.get_server_token()
	test_passed("Zone Logged In")


func test_cleanup_login_zone() -> void:
	Firebase.Auth.auth['idtoken'] = _jwt_backup_secret_token
	test_passed("Zone Cleanup")


func test_update_space_voxels() -> void:
	var txt: String = "whatsup, its terrain ;)"
	var file_data: PackedByteArray = txt.to_ascii_buffer()
	var promise = Net.zone_client.update_space_voxels(_TEST_SPACE_ID, file_data)
	await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	test_passed("Voxels Updated")



func test_clear_space_voxels() -> void:
	var promise = Net.zone_client.clear_space_voxels(_TEST_SPACE_ID)
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	test_passed("Voxels Cleared")


func test_get_space_voxels() -> void:
	Net.zone_client.space_voxels_received.connect(_get_space_voxels_success, CONNECT_ONE_SHOT)
	Net.zone_client.get_space_voxels(_TEST_SPACE_ID)


func _get_space_voxels_success(file_data: PackedByteArray) -> void:
	test_passed("filesize: %s" % str(file_data.size()))


func test_get_latest_published_space_version() -> void:
	var promise = Net.zone_client.server_get_latest_published_space(_TEST_SPACE_ID)
	var version = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	test_passed("Version received: %s" % version.get("_id"))
