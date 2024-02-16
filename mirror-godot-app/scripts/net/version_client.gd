class_name VersionClient
extends MirrorClient

const _URI_FORMAT: String = "%s/versions/%s/%s"
const _GET_CLIENT_VERSION_URL: String = "/storage/client/version"
const _PAYLOAD_BUCKET_ADDRESS_SETTING: String = "mirror/auto_updater_bucket_uri"

enum {
	GET_VERSION,
	GET_VERSION_PAYLOAD,
	GET_VERSION_MANIFEST,
}

var _latest_version: String
var _version_manifest: Dictionary

signal version_received(version: String)
signal version_manifest_received(manifest: Dictionary)
signal version_payload_received(body: PackedByteArray, hash: String)



func get_platform_uri(version: String=_latest_version) -> String:
	return _URI_FORMAT % [_get_payload_bucket_address(), version, Util.get_current_platform_name()]


func _get_payload_bucket_address() -> String:
	return str(ProjectSettings.get_setting(_PAYLOAD_BUCKET_ADDRESS_SETTING, ""))


func get_client_version() -> void:
	self.get_request(GET_VERSION, _GET_CLIENT_VERSION_URL)


func get_version_manifest(version: String=_latest_version) -> void:
	if version.is_empty():
		push_error("Server version must be provided before getting the version manifest.")
		return
	var version_manifest_uri: String = "%s.json" % get_platform_uri(version)
	print("Remote version manifest: ", version_manifest_uri)
	self.get_request_ext(GET_VERSION_MANIFEST, version_manifest_uri, {"version": version})


func get_version_payload(version: String, payload_hash: String, download_path:String="") -> HTTPRequest:
	if version.is_empty():
		push_error("Server version must be provided before getting the version payload.")
		return
	var remote_file_uri: String = "%s.tar.gz" % get_platform_uri(version)
	print("Remote version payload: ", remote_file_uri)
	var aux = {
		"version": version,
		"hash": payload_hash,
		"download_path": download_path,
	}
	return self.get_request_ext_with_http(GET_VERSION_PAYLOAD, remote_file_uri, aux)


## Signal routes a successful request to the appropriate complete method.
func _handle_request_completed(request: Dictionary) -> void:
	var json_parse_success = bool(request.get("json_parse_success", false))
	match request["key"]:
		GET_VERSION:
			if not json_parse_success:
				request_errored.emit(request)
				return
			_latest_version = request.get("json_result", {}).get("version", "")
			version_received.emit(_latest_version)
		GET_VERSION_MANIFEST:
			if not json_parse_success:
				request_errored.emit(request)
				return
			var manifest: Dictionary = request.get("json_result", {})
			manifest["version"] = request.get("version", "")
			_version_manifest = manifest
			version_manifest_received.emit(manifest)
		GET_VERSION_PAYLOAD:
			var body: PackedByteArray = request["body"]
			version_payload_received.emit(body, request.get("hash", ""))
