class_name ScriptBlockAsync
extends ScriptBlockSequenced


var script_builder: VisualScriptBuilder


func save_execution_state(except: ScriptBlockAsync) -> Dictionary:
	return script_builder.save_executed_sequenced_outputs(except)


func load_execution_state(saved_state) -> void:
	script_builder.load_block_outputs(saved_state)
	evaluated = true
