extends LoginIntegrationTest

var _version: String
var _manifest: Dictionary

## Initializes the VersionClient integration test queue.
func _init() -> void:
	_test_queue.append_array([
		&"login_firebase",
		&"test_get_version",
		&"test_get_version_manifest",
		#&"test_get_version_payload", # TODO: Test smaller payload
	])


func test_get_version() -> void:
	if str(Net.version_client._get_base_url()).contains("localhost"):
		test_passed("Bypassed version client test for LOCALHOST")
		return
	Net.version_client.version_received.connect(_test_get_version_received, CONNECT_ONE_SHOT)
	Net.version_client.request_errored.connect(test_failed)
	Net.version_client.get_client_version()


func _test_get_version_received(version: String) -> void:
	if version.is_empty():
		test_failed("Version string is empty.")
		return
	_version = version
	test_passed(version)


func test_get_version_manifest() -> void:
	if str(Net.version_client._get_base_url()).contains("localhost"):
		test_passed("Bypassed version client test for LOCALHOST")
		return
	Net.version_client.version_manifest_received.connect(_test_get_version_manifest_received, CONNECT_ONE_SHOT)
	Net.version_client.request_errored.connect(test_failed)
	Net.version_client.get_version_manifest()


func _test_get_version_manifest_received(manifest: Dictionary) -> void:
	if manifest.is_empty():
		test_failed("Manifest is empty.")
		return
	var filesize = int(manifest.get("file_download_size", 0))
	if filesize == 0:
		test_failed("Manifest filesize is empty: %s" % manifest)
		return
	if str(manifest.get("packed_md5_hash", "")).is_empty():
		test_failed("Manifest hash is empty: %s" % manifest)
		return
	if str(manifest.get("executable_name", "")).is_empty():
		test_failed("Manifest executable name is empty: %s" % manifest)
		return
	_manifest = manifest
	test_passed(_manifest)


func test_get_version_payload() -> void:
	Net.version_client.version_payload_received.connect(_test_get_version_payload_received, CONNECT_ONE_SHOT)
	Net.version_client.request_errored.connect(test_failed)
	Net.version_client.get_version_payload(_version, "abc")


func _test_get_version_payload_received(payload: PackedByteArray, hash: String) -> void:
	test_passed("payload received")
