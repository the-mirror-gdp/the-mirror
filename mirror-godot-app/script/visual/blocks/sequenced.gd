## A sequenced/run script block is one where the execution order is determined
## manually. This can be because the block has a significant performance cost,
## alters the state, or has no outputs (but they still can have outputs).
## By comparison, unsequenced/data blocks MUST have outputs, they are for gathering
## information, performing math, etc, and are typically cheap to calculate.
class_name ScriptBlockSequenced
extends ScriptBlock


signal request_reset_unsequenced_blocks_evaluation_state()


class ScriptBlockFlowPort extends Object:
	var port_name: String = ""
	var connected_block: ScriptBlockSequenced

	func duplicate() -> ScriptBlockFlowPort:
		var ret = ScriptBlockFlowPort.new()
		ret.port_name = port_name
		ret.connected_block = connected_block
		return ret


var flows: Array[ScriptBlockFlowPort] = []


func setup(block_json: Dictionary) -> void:
	_create_basic_sequence_flow_output()
	_setup_base(block_json)


func _create_basic_sequence_flow_output() -> void:
	flows.append(ScriptBlockFlowPort.new())


func execute(stack_count: int = 0) -> Error:
	# When reading, I suggest ignoring all the var ret and stack size stuff.
	# This code looks so much cleaner if you just ignore the error-handling parts.
	if stack_count > 200:
		log_error.emit("Call stack too big, did you make an infinite loop?")
		return ERR_CYCLIC_LINK
	request_reset_unsequenced_blocks_evaluation_state.emit()
	evaluate_inputs()
	var ret: Error = await _execute_callback(stack_count + 1)
	if ret:
		return ret
	if flows.size() > 0 and flows[0].connected_block:
		ret = await flows[0].connected_block.execute(stack_count + 1)
	return ret


func _execute_callback(stack_count: int) -> Error:
	log_error.emit("Run block does not have an execution callback implemented. This is a bug in The Mirror, please report.")
	return ERR_METHOD_NOT_FOUND


func evaluate() -> void:
	# Most blocks allow just-in-time evaluation, but for sequenced/run blocks we
	# explicitly don't want this. It may seem strange to have a method on a base
	# class that can't be used here, but it's for the better, because we want
	# the base to both do the heavy lifting and not know of derived classes.
	log_error.emit("Tried to read data from a run block out of order. Ensure the run block is executed before using values from it.")


func serialize_to_dictionary() -> Dictionary:
	var ret: Dictionary = super()
	if flows.size() > 0:
		# The only data we'll store here are the connection indices,
		# and it's the job of VisualScriptBuilder to populate this array.
		ret["flows"] = []
	return ret


func cleanup_script_block_for_deletion() -> void:
	super()
	for flow in flows:
		flow.free()
