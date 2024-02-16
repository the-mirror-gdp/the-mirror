extends ScriptBlockSequenced


var script_builder: VisualScriptBuilder


func _execute_callback(_stack_count: int) -> Error:
	script_builder.reset_unsequenced_blocks_evaluation_state()
	return OK


func get_script_block_type() -> String:
	return "reset_unsequenced"
