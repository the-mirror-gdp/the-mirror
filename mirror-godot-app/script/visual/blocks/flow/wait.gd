extends ScriptBlockAsync


var scene_tree: SceneTree


func _execute_callback(_stack_count: int) -> Error:
	var saved_state = save_execution_state(self)
	await scene_tree.create_timer(inputs[0].value).timeout
	load_execution_state(saved_state)
	return OK


func get_script_block_type() -> String:
	return "wait"
