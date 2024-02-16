## Contains both signal parameter inputs and inspector parameter inputs.
class_name ScriptEntryParameters
extends RefCounted


var inspector_parameters: Dictionary = {}
var signal_parameters: Dictionary = {}
var does_signal_pass_caller: bool = false


func create_inspector_parameter(param_array: Array) -> void:
	var param_name: String = param_array[0]
	for signal_param_name in signal_parameters:
		if signal_param_name == param_name:
			return # Not allowed, one must not overwrite signal parameter inputs.
	var param_data: Array = [param_array[1], param_array[2]]
	inspector_parameters[param_name] = param_data
	inspector_parameters.sort()


func delete_inspector_parameter(param_name: String) -> void:
	for signal_param_name in signal_parameters:
		if signal_param_name == param_name:
			return # Not allowed, one must not delete signal parameter inputs.
	inspector_parameters.erase(param_name)


func convert_to_port_data() -> Array[Array]:
	var ret: Array[Array] = []
	if does_signal_pass_caller:
		ret.append(["Caller", TYPE_OBJECT, null])
	for signal_param_name in signal_parameters:
		var type_and_value: Array = signal_parameters[signal_param_name]
		ret.append([signal_param_name, type_and_value[0], type_and_value[1]])
	for inspector_param_name in inspector_parameters:
		var type_and_value: Array = inspector_parameters[inspector_param_name]
		ret.append([inspector_param_name, type_and_value[0], type_and_value[1]])
	return ret


func convert_to_godot_user_signal_parameters() -> Array[Dictionary]:
	var ret: Array[Dictionary] = []
	for signal_param_name in signal_parameters:
		var type_and_value: Array = signal_parameters[signal_param_name]
		ret.append({
			"name": signal_param_name,
			"type": type_and_value[0]
		})
	return ret


func get_signal_parameter_count() -> int:
	var signal_param_count: int = signal_parameters.size()
	if does_signal_pass_caller:
		signal_param_count += 1
	return signal_param_count


func serialize_to_dictionary(dict: Dictionary) -> void:
	if not inspector_parameters.is_empty():
		dict["inspectorParameters"] = serialize_parameters_to_json(inspector_parameters)
	if not signal_parameters.is_empty():
		dict["signalParameters"] = serialize_parameters_to_json(signal_parameters)


static func serialize_parameters_to_json(parameters: Dictionary) -> Dictionary:
	for parameter_name in parameters:
		var parameter_data: Array = parameters[parameter_name]
		parameter_data[1] = Serialization.type_convert_from_json(parameter_data[1], parameter_data[0])
	return parameters


static func from_dictionary(dict: Dictionary) -> ScriptEntryParameters:
	var ret := ScriptEntryParameters.new()
	ret.does_signal_pass_caller = not ScriptSignalRegistration.is_mirror_registered_signal(dict.get("signal", ""))
	if dict.has("inspectorParameters"):
		ret.inspector_parameters = load_parameters_from_json(dict["inspectorParameters"])
	if dict.has("signalParameters"):
		ret.signal_parameters = load_parameters_from_json(dict["signalParameters"])
	return ret


static func load_parameters_from_json(json_parameters: Dictionary) -> Dictionary:
	var loaded_parameters: Dictionary
	for parameter_name in json_parameters:
		var parameter_data: Array = json_parameters[parameter_name]
		var parameter_type: int = parameter_data[0]
		var parameter_value: Variant = Serialization.type_convert_from_json(parameter_data[1], parameter_type)
		loaded_parameters[parameter_name] = [parameter_type, parameter_value]
	return loaded_parameters
