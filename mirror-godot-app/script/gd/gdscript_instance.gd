class_name GDScriptInstance
extends ScriptInstance


signal gdscript_compile_error(error_code: int, error_messages: Array)
signal gdscript_compile_success()

const _EMPTY_SCRIPT: String = """# Welcome to The Mirror-flavored GDScript!
# This is like normal GDScript, but you must not write class\u200B_name or ext\u200Bends.
# You can print to the notification area using `Notify.info(title, message)`.
# You may use functions and variables just like you would in normal GDScript.
# The Mirror provides support for multiple scripts per object, you can use
# members of SpaceObject the same way you use inherited members in Godot.
# For example, `Notify.info("pos", str(position))` will print a SpaceObject's position.
# Use `target_object` to refer to the object (SpaceObject or global) the script
# is attached to instead of `self`, as `self` refers to the script itself.


# Called when a SpaceObject and script finish loading.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass # Replace with function body.
"""

const _SCRIPT_PREPROCESS_PREFIX: String = """extends TMUserGDScriptBase


func get_object_variable(variable_name: String) -> Variant:
	return Mirror.get_object_variable(target_object, variable_name)


func has_object_variable(variable_name: String) -> bool:
	return Mirror.has_object_variable(target_object, variable_name)


func set_object_variable(variable_name: String, variable_value: Variant) -> void:
	if variable_name in self:
		set(variable_name, variable_value)
	Mirror.set_object_variable(target_object, variable_name, variable_value)


func tween_object_variable(variable_name: String, to_value: Variant, duration: float, trans: Tween.TransitionType = Tween.TRANS_LINEAR, easing: Tween.EaseType = Tween.EASE_IN_OUT) -> void:
	Mirror.tween_object_variable(target_object, variable_name, to_value, duration, trans, easing)


# The above is generated by The Mirror.\n
"""

static var _SCRIPT_PREPROCESS_LINE_COUNT: int = _SCRIPT_PREPROCESS_PREFIX.count("\n")

## A blacklist of disallowed tokens in the code. This is not comprehensive
## enough to be a security measure, but it should prevent footguns.
static var _SCRIPT_TEXT_DENYLIST: Array[RegEx] = [
	RegEx.create_from_string("\\bclass_name\\b"),
	RegEx.create_from_string("\\bextends\\b"),
	RegEx.create_from_string("\\bget_tree\\b"),
	RegEx.create_from_string("\\bload\\b"),
	RegEx.create_from_string("\\bpreload\\b"),
	RegEx.create_from_string("\\bEngine\\b"),
	RegEx.create_from_string("\\bOS\\b"),
	RegEx.create_from_string("\\bResourceLoader\\b"),
	RegEx.create_from_string("\\bFileAccess\\b"),
	RegEx.create_from_string("\\bDirAccess\\b")
]

static var _EXPOSE_VAR_REGEX: RegEx = RegEx.create_from_string("@export var ([_a-zA-Z][_a-zA-Z0-9]{0,30})\\b[^=\\n]*(= )?([^=\\n]*)")
static var _EXPRESSION = Expression.new()

var _entries: Array[GDScriptEntry] = []
var _exposed_var_names: PackedStringArray = []
var _exposed_var_default_values: Dictionary = {}
var _source_code: String
var gdscript_code: TMUserGDScript = TMUserGDScript.new()
var script_instance_object: Object


func apply_inspector_parameter_values() -> void:
	for entry in _entries:
		if entry_parameters.has(entry.entry_id):
			var params_for_entry: Dictionary = entry_parameters[entry.entry_id]
			entry.apply_inspector_parameter_values(params_for_entry)


func can_execute() -> bool:
	if not super():
		return false
	# For security reasons, only the server may execute custom GDScript code.
	return Zone.is_host()


func cleanup_script_instance() -> void:
	_cleanup_and_clear_entries()
	if script_instance_object:
		script_instance_object.free()
	super()


func _cleanup_and_clear_entries() -> void:
	for entry in _entries:
		entry.cleanup_gdscript_entry_for_deletion()
	_entries.clear()


func setup_script_instance_data(script_inst_dict: Dictionary) -> void:
	super(script_inst_dict) # The code in this class is simple, so run super after.


## Must be run only after setup_script_instance_data()
func setup_script_entity_data(script_entity_data: Dictionary) -> void:
	super(script_entity_data) # The code in this class is complex, so run super before.
	if script_entity_data.has("code"):
		_source_code = script_entity_data["code"]
	else:
		_source_code = _EMPTY_SCRIPT
	_cleanup_and_clear_entries()
	if script_entity_data.has("entries"):
		for entry_dict in script_entity_data["entries"]:
			var entry: GDScriptEntry = GDScriptEntry.from_dictionary(entry_dict)
			_entries.append(entry)
			entry.populate_entry_node(target_node)
	_preprocess_and_apply_code()


func serialize_script_entity_data() -> Dictionary:
	var entries_json: Array[Dictionary] = []
	for entry in _entries:
		entries_json.append(entry.serialize_gdscript_entry_to_json())
	return {
		"code": _source_code,
		"entries": entries_json,
		"id": script_id,
		"name": script_name,
		"type": "GDScript",
	}


## Serializes a Dictionary of only valid JSON types for saving to the database.
## For example, we represent `Vector3(1, 2, 3)` as a JSON array of size 3 `[1, 2, 3]`.
func serialize_script_instance_to_json() -> Dictionary:
	var ret: Dictionary = super()
	ret["type"] = "GDScript"
	# Keep the Dictionary keys sorted since they are sorted on the DB side,
	# and we want what we serialize here to be identical to what get saved.
	ret.sort()
	return ret


func get_source_code() -> String:
	return _source_code


func get_default_value_of_entry_inspector_parameter(entry_id: String, parameter_name: String) -> Variant:
	for entry in _entries:
		if entry.entry_id == entry_id:
			var param_data = entry.entry_parameters.inspector_parameters.get(parameter_name)
			return param_data[1] if param_data else null
	return null


func get_default_value_of_exposed_variable(variable_name: String) -> Variant:
	if _exposed_var_default_values.has(variable_name):
		return _exposed_var_default_values[variable_name]
	return null


func get_entry_line_numbers() -> PackedInt32Array:
	var ret := PackedInt32Array()
	for entry in _entries:
		ret.append(entry.entry_line_number)
	return ret


func get_friendly_name_of_entry_id(entry_id: String) -> String:
	for entry in _entries:
		if entry.entry_id == entry_id:
			return entry.function_name
	return entry_id


func reload_source_code() -> void:
	_preprocess_and_apply_code()


func set_source_code(source_code: String) -> void:
	_source_code = source_code
	_preprocess_and_apply_code()


func create_entry(entry_json: Dictionary) -> void:
	var new_function_name: String
	if entry_json.has("name"):
		new_function_name = entry_json["name"].to_snake_case()
	else:
		new_function_name = "on_" + entry_json["signal"]
	entry_json["function"] = new_function_name
	for entry in _entries:
		if entry.function_name == new_function_name:
			return # We already have an entry for this, no need to make a new entry.
	var new_entry: GDScriptEntry = GDScriptEntry.from_dictionary(entry_json)
	_entries.append(new_entry)
	new_entry.populate_entry_node(target_node)
	if not _source_code.contains("func " + new_function_name + "("):
		new_entry.entry_line_number = _source_code.count("\n") + 2
		_source_code += new_entry.create_gdscript_function_stub()
		# Else, we already have a function for this entry, no need to make a new function.
	_preprocess_and_apply_code()


func is_script_instance_setup() -> bool:
	return script_instance_object != null or not _source_code.is_empty()


func _sync_entry_params_with_gdscript_code() -> void:
	var any_deleted: bool = false
	for entry in _entries.duplicate(false):
		var delete: bool = entry.sync_entry_parameters_with_gdscript_code(_source_code)
		if delete:
			_entries.erase(entry)
			entry.cleanup_gdscript_entry_for_deletion()
			entry.free()
			any_deleted = true
	if any_deleted:
		script_entries_changed.emit()


func create_inspector_parameter_input(entry_id: String, parameter_port_array: Array) -> void:
	for gdscript_entry in _entries:
		if gdscript_entry.entry_id == entry_id:
			gdscript_entry.entry_parameters.create_inspector_parameter(parameter_port_array)
			_source_code = gdscript_entry.sync_gdscript_code_with_entry(_source_code)
			break
	sync_script_inst_params_with_script_data()


## Ensure the script instance entry inspector parameters match the
## signature of the script's data. Since a script may be used by
## multiple objects, parameters may get out of sync without this code.
func sync_script_inst_params_with_script_data() -> void:
	var old_entry_parameters: Dictionary = entry_parameters
	entry_parameters = {}
	for entry in _entries:
		var entry_id: String = entry.entry_id
		var new_params: Dictionary = entry.entry_parameters.inspector_parameters.duplicate(true)
		entry_parameters[entry_id] = new_params
		if entry_id in old_entry_parameters:
			var old_params: Dictionary = old_entry_parameters[entry_id]
			for param_key in old_params:
				if param_key in new_params:
					var old_param_array: Array = old_params[param_key]
					var new_param_array: Array = new_params[param_key]
					new_param_array[1] = old_param_array[1]
	entry_parameters.sort()
	apply_inspector_parameter_values()


func update_script_entity_data_from_network(script_entity_data: Dictionary) -> void:
	setup_script_entity_data(script_entity_data)
	script_entity_data_updated_from_network.emit()


func _preprocess_and_apply_code() -> void:
	if is_instance_valid(script_instance_object):
		script_instance_object.free()
	var preprocess_error: Dictionary = _preprocess_check_blacklist()
	if not preprocess_error.is_empty():
		gdscript_compile_error.emit(ERR_INVALID_DATA, [preprocess_error])
		return
	# Sync up entries: code -> entry, then entry -> code, then entry -> instance.
	_sync_entry_params_with_gdscript_code()
	_sync_gdscript_code_with_entries()
	sync_script_inst_params_with_script_data()
	# Compile new code.
	var code_to_load: String = _SCRIPT_PREPROCESS_PREFIX + _source_code
	var error_code = gdscript_code.load_user_gdscript(code_to_load, target_node)
	if error_code != OK:
		var error_messages: Array = gdscript_code.get_error_messages()
		for error_message_dict in error_messages:
			error_message_dict["line"] -= _SCRIPT_PREPROCESS_LINE_COUNT
		gdscript_compile_error.emit(error_code, error_messages)
		return
	_update_exposed_variables()
	gdscript_compile_success.emit()
	if not can_execute():
		# Don't even init the script if it can't execute.
		# Someone could put malicious code inside func _init().
		return
	# Instantiate the successfully loaded script.
	script_instance_object = gdscript_code.new()
	_sync_exposed_variables_with_spaceobj_spacevars()
	# Connect the signals.
	script_instance_object.load_exposed_vars.connect(_on_load_exposed_vars)
	script_instance_object.save_exposed_vars.connect(_on_save_exposed_vars)
	script_instance_object.tmusergdscript_runtime_error.connect(_on_tmusergdscript_runtime_error)
	for entry in _entries:
		entry.connect_entry_signal(script_instance_object, entry_parameters)
	# Supplementary entry callbacks. Keep this in sync with GDScript CodeEdit load_entry_connection_decoration.
	if target_node is SpaceObject:
		if _source_code.contains("func _ready("):
			if target_node._is_setup:
				script_instance_object.call(&"_ready")
			else:
				target_node.setup_done.connect(Callable(script_instance_object, &"_ready"))
	if _source_code.contains("func _physics_process("):
		Zone.physics_process_every_frame.connect(Callable(script_instance_object, &"_physics_process"))
	if _source_code.contains("func _process("):
		Zone.process_every_frame.connect(Callable(script_instance_object, &"_process"))


func _preprocess_check_blacklist() -> Dictionary:
	for regex in _SCRIPT_TEXT_DENYLIST:
		var regex_match: RegExMatch = regex.search(_source_code)
		if regex_match:
			var start: int = regex_match.get_start()
			var prefix_text: String = _source_code.left(start)
			return {
				"column": start - prefix_text.rfind("\n"),
				"line": prefix_text.count("\n") + 1,
				"message": "The code contains a disallowed token: " + regex_match.strings[0],
			}
	return {}


func _sync_gdscript_code_with_entries() -> void:
	for entry in _entries:
		_source_code = entry.sync_gdscript_code_with_entry(_source_code)


func _sync_exposed_variables_with_spaceobj_spacevars() -> void:
	#_update_exposed_variables()
	for var_name in _exposed_var_names:
		if Mirror.has_object_variable(target_node, var_name):
			script_instance_object.set(var_name, Mirror.get_object_variable(target_node, var_name))
		else:
			Mirror.set_object_variable(target_node, var_name, script_instance_object.get(var_name))


func _on_load_exposed_vars() -> void:
	for var_name in _exposed_var_names:
		script_instance_object.set(var_name, Mirror.get_object_variable(target_node, var_name))


func _on_save_exposed_vars() -> void:
	for var_name in _exposed_var_names:
		Mirror.set_object_variable(target_node, var_name, script_instance_object.get(var_name))


func _update_exposed_variables() -> void:
	_exposed_var_names.clear()
	var matches: Array[RegExMatch] = _EXPOSE_VAR_REGEX.search_all(_source_code)
	for mat in matches:
		var var_name: String = mat.get_string(1)
		_exposed_var_names.append(var_name)
		if mat.get_group_count() >= 3:
			_EXPRESSION.parse(mat.get_string(3))
			_exposed_var_default_values[var_name] = _EXPRESSION.execute()


## This method handles runtime error messages similar to VisualScriptInstance's `_on_block_message` method.
func _on_tmusergdscript_runtime_error(error_str: String, frame_index: int, line_num: int, func_name: String) -> void:
	line_num -= _SCRIPT_PREPROCESS_LINE_COUNT
	# Format the error message.
	var error_message: String = "Error in " + script_name + " func " + func_name + " line " + str(line_num) + ": "
	error_str = '"' + error_str + '"'
	if frame_index == 0:
		# The error was directly in the script.
		error_message += error_str
	else:
		# The error was indirectly caused by the script.
		error_message += " This caused an internal error " + error_str + " " + str(frame_index) + " frame(s) deep."
	# Display the error message to the user.
	Zone.script_network_sync.handle_tmusergdscript_runtime_error(self, error_message, line_num)
