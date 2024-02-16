class_name ZoneClient
extends MirrorHttpClient

enum {
	ZONE_GET_SPACE_VOXELS,
	ZONE_UPDATE_SPACE_VOXELS,
	ZONE_GET_LATEST_PUBLISHED_SPACE_VERSION,
	ZONE_CREATE_PLAY_SERVER_BY_SPACE,
	ZONE_GET_PLAY_SERVERS_FOR_SPACE,
}

const _GCS_BASE_URL = "https://storage.googleapis.com"

signal space_voxels_received(file_data: PackedByteArray)


# Create a play server for a given space ID
func create_play_server_by_space_id(space_id: String, name: String) -> Promise:
	var url: String = "/zone/create-play-server/space/%s" % space_id
	var data: Dictionary = {
		"zoneName": name
	}
	return self.post_request(ZONE_CREATE_PLAY_SERVER_BY_SPACE, url, data)


# Grab the list of playservers for a given space ID
func get_play_servers_for_space_id(space_id: String) -> Promise:
	return self.get_request(ZONE_GET_PLAY_SERVERS_FOR_SPACE, "/zone/list-play-servers/space/%s?populateOwner=true" % space_id)


func update_space_voxels(space_id: String, file_bytes: PackedByteArray) -> Promise:
	var url: String = "/space/voxels/%s" % space_id
	var request_body: PackedByteArray = self.get_form_data(file_bytes, "application/octet-stream")
	return self.put_request(ZONE_UPDATE_SPACE_VOXELS, url, request_body)


## Saves an empty voxel data to GCS.
func clear_space_voxels(space_id: String) -> Promise:
	return update_space_voxels(space_id, PackedByteArray())


func get_space_voxels(space_id: String) -> Promise:
	return # disused
	const url_fmt: String = "%s/%s/space/%s/terrain/voxels.dat?%s"
	var time_str: String = str(Time.get_unix_time_from_system())
	var bucket = ProjectSettings.get_setting("mirror/asset_bucket")
	var url: String = url_fmt % [_GCS_BASE_URL, bucket, space_id, time_str]
	return self.get_request_ext(ZONE_GET_SPACE_VOXELS, url)


func server_get_latest_published_space(space_id: String) -> Promise:
	var url: String = "/space-godot-server/latest/%s" % space_id
	return self.get_request(ZONE_GET_LATEST_PUBLISHED_SPACE_VERSION, url)


func _promise_fulfill_successful(request: Dictionary, promise: Promise) -> void:
	if request["key"] == ZONE_GET_SPACE_VOXELS:
		var body: PackedByteArray = request.get("body")
		promise.set_result(body)
		space_voxels_received.emit(body)
		return
	if not request.get("json_parse_success", false):
		promise.set_error("ZoneClient request succeeded but parsed result is not a json. %s" % str(request))
		return
	var parsed_result = request.get("json_result")
	if parsed_result == null:
		push_error("ZoneClient request succeeded but parsed result is null. %s" % str(request))
		promise.set_error("ZoneClient request succeeded but parsed result is null. %s" % str(request))
		return
	promise.set_result(parsed_result)

