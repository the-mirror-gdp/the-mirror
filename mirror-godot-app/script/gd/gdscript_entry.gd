class_name GDScriptEntry
extends Object


static var param_prefix_regex := RegEx.create_from_string("\n.*\\(")
static var param_suffix_regex := RegEx.create_from_string("\\).*\n")

var entry_id: String = "" # For a script to keep track of inspector parameters.
var entry_node: Node # The node that emits the signal this entry listens for.
var entry_path: String = "" # NodePath as String for interop reasons.
var entry_signal: String = ""
var entry_parameters: ScriptEntryParameters
var entry_func_regex := RegEx.new()
var entry_line_number: int = -1 # A cache only read by the code editor.
var function_name: String = ""


func apply_inspector_parameter_values(script_inspector_params: Dictionary) -> void:
	for param_name in script_inspector_params:
		var param_type_and_value: Array = script_inspector_params[param_name]
		var param_value = param_type_and_value[1]
		if entry_node is Timer and param_name == "duration":
			entry_node.wait_time = maxf(param_value, 0.1)
		if entry_node is JBody3D:
			var shape: JShape3D = entry_node.shape
			if shape is JSphereShape3D and param_name == "radius":
				shape.radius = param_value
			elif shape is JBoxShape3D and param_name == "size":
				shape.size = param_value


func cleanup_gdscript_entry_for_deletion() -> void:
	entry_parameters.free()


func create_gdscript_function_stub() -> String:
	return "\n" + create_gdscript_function_signature() + "\tpass\n"


func create_gdscript_function_signature() -> String:
	var function_string: String = "\nfunc " + function_name + "("
	var function_parameters := PackedStringArray()
	for signal_param_name in entry_parameters.signal_parameters:
		var param_type_and_value: Array = entry_parameters.signal_parameters[signal_param_name]
		var type_enum: int = param_type_and_value[0]
		var gdscript_type: String = Serialization.type_enum_to_friendly_string(type_enum)
		function_parameters.append(signal_param_name + ": " + gdscript_type)
	for inspec_param_name in entry_parameters.inspector_parameters:
		var param_type_and_value: Array = entry_parameters.inspector_parameters[inspec_param_name]
		var type_enum: int = param_type_and_value[0]
		var gdscript_type: String = Serialization.type_enum_to_friendly_string(type_enum)
		var gdscript_value: String = _value_to_gdscript_literal(param_type_and_value[1], type_enum)
		function_parameters.append(inspec_param_name + ": " + gdscript_type + " = " + gdscript_value)
	return function_string + ", ".join(function_parameters) + ") -> void:\n"


func populate_entry_node(target_node: Node) -> void:
	_populate_entry_node(target_node)
	_setup_signal()


func _populate_entry_node(target_node: Node) -> void:
	if entry_path == "self":
		entry_node = target_node
		return
	var node_path := NodePath(entry_path)
	if node_path.is_absolute():
		entry_node = Zone.get_node(node_path)
		return
	if target_node.has_node(node_path):
		entry_node = target_node.get_node(node_path)
		return
	if not entry_path.contains("/"):
		_create_entry_node(target_node)


func serialize_gdscript_entry_to_json() -> Dictionary:
	var dict: Dictionary = {
		"entry_id": entry_id,
		"function": function_name,
		"path": entry_path,
		"signal": entry_signal,
	}
	entry_parameters.serialize_to_dictionary(dict)
	dict.sort()
	return dict


func sync_entry_parameters_with_gdscript_code(script_code: String) -> bool:
	var regex_match: RegExMatch = entry_func_regex.search(script_code)
	if regex_match == null or regex_match.strings.is_empty():
		return true # Indicates that this entry needs deletion in the instance.
	var signature: String = regex_match.strings[0]
	var params_names_values: Dictionary = _split_entry_params_names_values(signature)
	for param_name in params_names_values:
		if entry_parameters.inspector_parameters.has(param_name):
			var param_type_and_value: Array = entry_parameters.inspector_parameters[param_name]
			var param_type: int = param_type_and_value[0]
			var param_value_str: String = params_names_values[param_name].trim_prefix('"').trim_suffix('"')
			param_type_and_value[1] = Serialization.type_convert_any(param_value_str, param_type)
	return false


func sync_gdscript_code_with_entry(script_code: String) -> String:
	var regex_match: RegExMatch = entry_func_regex.search(script_code)
	if regex_match == null or regex_match.strings.is_empty():
		entry_line_number = script_code.count("\n") + 2
		return script_code + create_gdscript_function_stub()
	var signature: String = regex_match.strings[0]
	entry_line_number = script_code.left(regex_match.get_start()).count("\n") + 1
	return script_code.replace(signature, create_gdscript_function_signature())


func _setup_signal() -> void:
	if not entry_node:
		printerr("GDScriptEntry tried to set up a signal, but there was no entry node.")
		return
	var entry_signal_sname := StringName(entry_signal)
	if not entry_node.has_user_signal(entry_signal_sname):
		if entry_node.has_signal(entry_signal_sname):
			if ScriptSignalRegistration.is_builtin_signal_unregistered(entry_signal_sname):
				printerr("Tried to create an entry for builtin signal " + entry_signal + " but it is not registered. This is unsecure, skipping.")
				return
		else:
			if not ScriptSignalRegistration.is_signal_valid_on_node(entry_signal_sname, entry_node):
				return
			_add_user_signal(entry_signal_sname)
			var signal_signature: Dictionary = {
				"signal": entry_signal_sname,
				"signalParameters": entry_parameters.signal_parameters,
			}
			ScriptSignalRegistration.register_user_signal_signature(signal_signature)


func _add_user_signal(event_signal_sname: StringName) -> void:
	var user_signal_params: Array[Dictionary] = entry_parameters.convert_to_godot_user_signal_parameters()
	entry_node.add_user_signal(event_signal_sname, user_signal_params)


func _create_entry_node(target_node: Node) -> void:
	entry_path = TMNodeUtil.get_unique_child_name(target_node, entry_path)
	entry_node = create_node_for_entry_signal(entry_signal)
	if entry_node == null:
		Notify.error("GDScript Entry", "Unable to make a node for the entry: " + entry_id)
		return
	entry_node.name = entry_path
	target_node.add_child(entry_node)


func _split_entry_params_names_values(signature: String) -> Dictionary:
	var ret: Dictionary = {}
	var prefix_match: RegExMatch = param_prefix_regex.search(signature)
	var suffix_match: RegExMatch = param_suffix_regex.search(signature)
	if prefix_match == null or suffix_match == null or prefix_match.strings.is_empty() or suffix_match.strings.is_empty():
		return ret
	var params_str: String = signature.trim_prefix(prefix_match.strings[0]).trim_suffix(suffix_match.strings[0]).replace(" ", "")
	var params_arr: PackedStringArray = params_str.split(",", false)
	for param in params_arr:
		var param_sig_value: PackedStringArray = param.split("=", false)
		if param_sig_value.size() < 2:
			continue
		var param_split_sig: PackedStringArray = param_sig_value[0].split(":", false)
		var param_name: String = param_split_sig[0].to_lower()
		ret[param_name] = param_sig_value[1]
	return ret


func _value_to_gdscript_literal(value: Variant, type_enum: int) -> String:
	value = Serialization.type_convert_any(value, type_enum)
	if value is String:
		return '"' + value + '"'
	if value is float and value == int(value):
		return str(value) + ".0"
	return str(value)


static func create_node_for_entry_signal(entry_signal: String) -> Node:
	if entry_signal == "timeout":
		var timer: Timer = Timer.new()
		timer.autostart = true
		return timer
	if entry_signal in ["player_interact", "body_entered", "body_exited"]:
		# Note: This code is intentionally kept very simplified.
		# If users want to customize the position/shape further, they
		# should use the extra nodes system to add a trigger shape.
		var jbody := JBody3D.new()
		jbody.body_mode = JBody3D.BodyMode.SENSOR
		jbody.set_layer_name(&"TRIGGER")
		jbody.shape = JSphereShape3D.new()
		return jbody
	return null


static func from_dictionary(dict: Dictionary) -> GDScriptEntry:
	var entry := GDScriptEntry.new()
	entry.entry_id = dict["entry_id"]
	entry.entry_path = dict["path"]
	entry.entry_signal = dict["signal"]
	if dict.has("function"):
		entry.function_name = dict["function"]
	else:
		entry.function_name = String(dict["name"]).to_snake_case()
	entry.entry_func_regex.compile("\nfunc " + entry.function_name + "\\(.*\n")
	entry.entry_parameters = ScriptEntryParameters.from_dictionary(dict, true)
	return entry
