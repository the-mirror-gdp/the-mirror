class_name EnvironmentClient
extends MirrorClient

enum {
	CREATE_ENVIRONMENT,
	GET_ENVIRONMENT,
	UPDATE_ENVIRONMENT,
	DELETE_ENVIRONMENT,
}

signal environment_created(environment: Dictionary)
signal environment_received(environment: Dictionary)
signal environment_updated(environment: Dictionary)
signal environment_deleted(environment: Dictionary)


func create_environment(environment: Dictionary) -> void:
	self.post_request(CREATE_ENVIRONMENT, "/environment", environment)


func get_environment(environment_id: String) -> void:
	self.get_request(GET_ENVIRONMENT, "/environment/%s" % environment_id)


func update_environment(environment: Dictionary) -> void:
	var environment_id = environment["_id"]
	self.patch_request(UPDATE_ENVIRONMENT, "/environment/%s" % environment_id, environment)


func delete_environment(environment_id: String) -> void:
	self.delete_request(DELETE_ENVIRONMENT, "/environment/%s" % environment_id)


## Signal routes a successful request to the appropriate complete method.
func _handle_request_completed(request: Dictionary) -> void:
	var json_result: Variant = request["json_result"]
	if json_result == null:
		request_errored.emit(request)
		return
	match request["key"]:
		CREATE_ENVIRONMENT:
			environment_created.emit(json_result)
		GET_ENVIRONMENT:
			environment_received.emit(json_result)
		UPDATE_ENVIRONMENT:
			environment_updated.emit(json_result)
		DELETE_ENVIRONMENT:
			environment_deleted.emit(json_result)
