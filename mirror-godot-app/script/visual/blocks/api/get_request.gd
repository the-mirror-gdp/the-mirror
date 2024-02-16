extends ScriptBlockAsync


func _execute_callback(_stack_count: int) -> Error:
	if Zone.is_host():
		log_error.emit("API calls are not supported on server.")
		return ERR_UNAUTHORIZED
	if not ProjectSettings.get_setting("feature_flags/user_api_requests", false):
		log_error.emit("API calls are currently disabled.")
		return ERR_UNAUTHORIZED
	var saved_state = save_execution_state(self)
	var resource_path: String = inputs[0].value
	var promise: Promise = Net.http_universal_client.get_request(0, resource_path)
	await promise.wait_till_fulfilled()
	if promise.is_error():
		log_error.emit(promise.get_error_message())
		return FAILED
	var api_result = promise.get_result()
	var json_result = api_result.get("json_result", "")
	outputs[0].value = JSON.stringify(json_result)
	outputs[1].value = int(api_result.get("code", 0))

	load_execution_state(saved_state)
	return OK


func get_script_block_type() -> String:
	return "api_get_request"
