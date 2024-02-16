class_name TerrainClient
extends MirrorClient

enum {
	GET_TERRAIN,
	CREATE_TERRAIN,
	UPDATE_TERRAIN,
	DELETE_TERRAIN,
	GET_USER_TERRAIN,
	GET_PUBLIC_TERRAIN,
}

signal terrain_received(terrain: Dictionary)
signal terrain_created(terrain: Dictionary)
signal terrain_updated(terrain: Dictionary)
signal terrain_deleted(terrain: Dictionary)
signal user_terrain_received(terrains: Array)
signal public_terrain_received(terrains: Array)


func get_user_terrain() -> void:
	self.get_request(GET_USER_TERRAIN, "/terrain")


func get_public_terrain() -> void:
	self.get_request(GET_PUBLIC_TERRAIN, "/terrain/public")


func get_terrain(terrain_id: String) -> void:
	self.get_request(GET_TERRAIN, "/terrain/%s" % terrain_id)


func create_terrain(terrain: Dictionary) -> void:
	self.post_request(CREATE_TERRAIN, "/terrain", terrain)


func update_terrain(terrain: Dictionary) -> void:
	var terrain_id = terrain["_id"]
	self.patch_request(UPDATE_TERRAIN, "/terrain/%s" % terrain_id, terrain)


func delete_terrain(terrain_id: String) -> void:
	self.delete_request(DELETE_TERRAIN, "/terrain/%s" % terrain_id)


## Signal routes a successful request to the appropriate complete method.
func _handle_request_completed(request: Dictionary) -> void:
	var json_result: Variant = request["json_result"]
	if json_result == null:
		request_errored.emit(request)
		return
	match request["key"]:
		GET_TERRAIN:
			terrain_received.emit(json_result)
		GET_USER_TERRAIN:
			user_terrain_received.emit(json_result)
		GET_PUBLIC_TERRAIN:
			public_terrain_received.emit(json_result)
		CREATE_TERRAIN:
			terrain_created.emit(json_result)
		UPDATE_TERRAIN:
			terrain_updated.emit(json_result)
		DELETE_TERRAIN:
			terrain_deleted.emit(json_result)
