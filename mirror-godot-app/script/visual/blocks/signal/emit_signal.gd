class_name ScriptBlockEmitSignal
extends ScriptBlockSequenced


# Input 0 is the signal name, input 1 is the target object.
const INPUT_START: int = 2

var attached_object: Object


func _execute_callback(_stack_count: int) -> Error:
	var target_object: Object
	if inputs[1].connected_block == null:
		target_object = attached_object
	else:
		target_object = type_convert(inputs[1].value, ScriptBlock.PortType.OBJECT)
	if not is_instance_valid(target_object):
		log_error.emit("The target object is invalid.")
		return ERR_INVALID_PARAMETER
	var signal_name_sname: StringName = inputs[0].value
	if not target_object.has_user_signal(signal_name_sname) \
			and target_object.has_signal(signal_name_sname):
		log_error.emit("The requested signal on the target object is a built-in signal. This is not allowed for security reasons.")
		return ERR_INVALID_PARAMETER
	var arguments: Array = []
	for i in range(2, inputs.size()):
		arguments.append(inputs[i].value)
	return call_signal_on_target(target_object, arguments)


func call_signal_on_target(target_object: Object, arguments: Array) -> int:
	var signal_name_sname: StringName = inputs[0].value
	if signal_name_sname.is_empty():
		log_error.emit("The signal was an empty string.")
		return ERR_INVALID_DECLARATION
	if not target_object.has_user_signal(signal_name_sname):
		log_error.emit("The target object does not have the '" + signal_name_sname + "' signal.")
		return ERR_METHOD_NOT_FOUND
	if not ScriptSignalRegistration.is_mirror_registered_signal(signal_name_sname):
		arguments.push_front(attached_object)
	var err: Error
	match arguments.size():
		0:
			err = target_object.emit_signal(signal_name_sname)
		1:
			err = target_object.emit_signal(signal_name_sname, arguments[0])
		2:
			err = target_object.emit_signal(signal_name_sname, arguments[0], arguments[1])
		3:
			err = target_object.emit_signal(signal_name_sname, arguments[0], arguments[1], arguments[2])
		4:
			err = target_object.emit_signal(signal_name_sname, arguments[0], arguments[1], arguments[2], arguments[3])
		5:
			err = target_object.emit_signal(signal_name_sname, arguments[0], arguments[1], arguments[2], arguments[3], arguments[4])
		6:
			err = target_object.emit_signal(signal_name_sname, arguments[0], arguments[1], arguments[2], arguments[3], arguments[4], arguments[5])
		7:
			err = target_object.emit_signal(signal_name_sname, arguments[0], arguments[1], arguments[2], arguments[3], arguments[4], arguments[5], arguments[6])
		8:
			err = target_object.emit_signal(signal_name_sname, arguments[0], arguments[1], arguments[2], arguments[3], arguments[4], arguments[5], arguments[6], arguments[7])
		_:
			@warning_ignore("assert_always_false")
			assert(false, "If you reach this assert, add support for more signal parameter inputs.")
	if err != OK:
		log_error.emit("Failed to emit the '" + signal_name_sname + "' signal. Do the signatures match?")
	return OK


func is_port_enumerated(input_port: ScriptBlock.ScriptBlockInputPort) -> bool:
	return input_port == inputs[0]


func get_enum_values(_input_port: ScriptBlock.ScriptBlockInputPort) -> Array:
	return ScriptSignalRegistration.get_user_signal_names()


## Ensure the arguments match what the target signal is expecting to receive.
func update_block_signature(edited_input_port: ScriptBlock.ScriptBlockInputPort) -> void:
	if edited_input_port != inputs[0]:
		return
	var requested_signal: String = edited_input_port.value
	var signal_signature: Dictionary = \
			ScriptSignalRegistration.get_signature_from_user_signal_name(requested_signal)
	if signal_signature.is_empty():
		Notify.warning("Autocomplete failed", "Unable to find a signature for signal '" + requested_signal + "'.")
		return # No signature found, so don't change the block's inputs.
	var signal_parameters: Dictionary = signal_signature.get("signalParameters", {})
	inputs.resize(signal_parameters.size() + INPUT_START)
	var i: int = INPUT_START
	for parameter_name in signal_parameters:
		var parameter_data: Array = signal_parameters[parameter_name]
		if inputs[i] == null:
			inputs[i] = ScriptBlock.ScriptBlockInputPort.new()
		var input: ScriptBlock.ScriptBlockInputPort = inputs[i]
		input.port_name = parameter_name
		input.port_type = parameter_data[0]
		input.value = parameter_data[1]
		i = i + 1


func get_script_block_type() -> String:
	return "emit_signal"
