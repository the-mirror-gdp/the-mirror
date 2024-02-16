# Base class used for all entries, including the general ScriptBlockEntry,
# and the specific cases for global/object variable changed/tweened signals.
class_name ScriptBlockEntryBase
extends ScriptBlockSequenced


var script_instance: ScriptInstance
var entry_id: String = "" # For a script to keep track of inspector parameters.
var entry_node: Node # The node that emits the signal this entry listens for.
var entry_path: String = "" # NodePath as String for interop reasons.
var entry_signal: String = ""
var entry_connection_valid: bool = false
var parameters: ScriptEntryParameters


func setup(block_json: Dictionary) -> void:
	entry_id = block_json.get("entry_id", "")
	entry_path = block_json.get("path", "")
	entry_signal = block_json.get("signal", "")
	parameters = ScriptEntryParameters.from_dictionary(block_json)
	super(block_json)
	if not block_json.has("outputs"):
		_setup_outputs(parameters.convert_to_port_data())


func get_script_block_type() -> String:
	return "entry"


func serialize_to_dictionary() -> Dictionary:
	var ret: Dictionary = super()
	ret["entry_id"] = entry_id
	ret["path"] = entry_path
	ret["signal"] = entry_signal
	ret["type"] = "entry"
	parameters.serialize_to_dictionary(ret)
	ret.sort()
	return ret


func reset_entry_output_ports() -> void:
	for output in outputs:
		output.free()
	outputs.clear()
	_setup_outputs(parameters.convert_to_port_data())


func apply_inspector_parameter_values(script_inspector_params: Dictionary) -> void:
	for output in outputs:
		if output.port_name in script_inspector_params:
			var param_array: Array = script_inspector_params[output.port_name]
			output.value = param_array[1]
			_apply_inspector_parameter_to_node(output.port_name, output.value)


func _apply_inspector_parameter_to_node(param_name: String, param_value: Variant) -> void:
	if entry_node is Timer and param_name == "Duration":
		entry_node.wait_time = maxf(param_value, 0.1)
	if entry_node is JBody3D:
		var shape: JShape3D = entry_node.shape
		if shape is JSphereShape3D and param_name == "Radius":
			shape.radius = param_value
		elif shape is JBoxShape3D and param_name == "Size":
			shape.size = param_value


func setup_signal() -> void:
	if not entry_node:
		printerr("Script entry tried to set up a signal, but there was no entry node.")
		entry_connection_valid = false
		return
	var entry_signal_sname := StringName(entry_signal)
	if not entry_node.has_user_signal(entry_signal_sname):
		if entry_node.has_signal(entry_signal_sname):
			if ScriptSignalRegistration.is_builtin_signal_unregistered(entry_signal_sname):
				printerr("Tried to create an entry for builtin signal " + entry_signal + " but it is not registered. This is unsecure, skipping.")
				entry_connection_valid = false
				return
		else:
			if not ScriptSignalRegistration.is_signal_valid_on_node(entry_signal_sname, entry_node):
				entry_connection_valid = false
				return
			_add_user_signal(entry_signal_sname)
			var signal_signature: Dictionary = {
				"signal": entry_signal_sname,
				"signalParameters": parameters.signal_parameters,
			}
			ScriptSignalRegistration.register_user_signal_signature(signal_signature)
	var signal_callable: Callable = _get_callable_for_event_signal()
	entry_node.connect(entry_signal_sname, signal_callable)
	entry_connection_valid = true


func _add_user_signal(event_signal_sname: StringName) -> void:
	var user_signal_params: Array[Dictionary] = parameters.convert_to_godot_user_signal_parameters()
	entry_node.add_user_signal(event_signal_sname, user_signal_params)


func _get_callable_for_event_signal() -> Callable:
	assert(false, "This method must be overridden in derived classes.")
	# This is unreachable code, but GDScript isn't smart enough to detect it.
	return Callable()


# Execution methods.
func _execute_callback(_stack_count: int) -> Error:
	# Entries are the only sequenced/run blocks that have no execution callback content.
	evaluated = true
	return OK


func _execute() -> void:
	script_instance.reset_all_blocks_evaluation_state()
	script_instance.script_about_to_run_from_signal.emit()
	execute()
