extends ScriptBlockAsync


func _execute_callback(_stack_count: int) -> Error:
	var saved_state = save_execution_state(self)

	var user_id: String = inputs[0].value
	var promise = Net.user_client.get_user_profile(user_id)
	await promise.wait_till_fulfilled()
	if promise.is_error():
		log_error.emit(promise.get_error_message())
		return FAILED
	var user_profile = promise.get_result()
	outputs[0].value = JSON.stringify(user_profile)
	load_execution_state(saved_state)
	return OK




func get_script_block_type() -> String:
	return "user_profile_request"
