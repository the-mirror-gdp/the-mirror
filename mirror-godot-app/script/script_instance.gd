## ScriptInstance combines together multiple things:
## * A script with entries that connect to signals to run.
## * A list of parameters that get passed to the entries when run.
## * A node to be attached to (treated as the "self" object of the script)
## TODO: Create derived classes VisualScriptInstance and GDScriptInstance.
class_name ScriptInstance
extends Object


## Emitted every time the script runs by receiving a signal.
signal script_about_to_run_from_signal()
## Emitted when changed locally OR changed by receiving a network update.
signal script_contents_changed()
## Emitted when all of its contents have been deleted.
signal script_contents_deleted()
## Emitted when the script contents are updated from the network.
## This should never be connected to anything that sends a network update.
signal script_entity_data_updated_from_network()
## Emitted when the instance changes locally, but not the script data,
## and only the instance needs to be synced over the network.
signal request_save_script_instance()

var target_node: Node
## Stores parameters for multiple entries. The format used is:
## Dictionary[String, Dictionary[String, Array]] where Array is [type, value]
var entry_parameters: Dictionary = {}

var script_enabled: bool = true
var execute_in_edit: bool = true
var script_id: String = ""
var script_name: String = ""
## If true, this script instance is an Asset (user specific).
## If false, this script instance is an Entity (inside of a space).
var is_script_asset: bool = false


func can_execute() -> bool:
	if not script_enabled:
		return false
	# Check if we allow executing in edit mode or if this is play mode.
	if not (execute_in_edit or Zone.is_in_play_mode()):
		return false
	return true


func cleanup_script_instance() -> void:
	target_node = null


## Serializes a Dictionary of only valid JSON types for saving to the database.
## For example, we represent `Vector3(1, 2, 3)` as a JSON array of size 3 `[1, 2, 3]`.
func serialize_to_json() -> Dictionary:
	var ret: Dictionary = {
		"enabled": script_enabled,
		"execute_in_edit": execute_in_edit,
		"script_id": script_id,
	}
	if not entry_parameters.is_empty():
		var serialized: Dictionary = _serialize_entry_parameters_to_json()
		if not serialized.is_empty():
			ret["entry_parameters"] = serialized
	# Keep the Dictionary keys sorted since they are sorted on the DB side,
	# and we want what we serialize here to be identical to what get saved.
	ret.sort()
	return ret


func is_script_instance_setup() -> bool:
	assert(false, "This method must be overridden in a derived class.")
	return false


func setup_script_instance_data(script_inst_dict: Dictionary) -> void:
	if script_inst_dict.has("enabled"):
		script_enabled = script_inst_dict["enabled"]
	if script_inst_dict.has("execute_in_edit"):
		execute_in_edit = script_inst_dict["execute_in_edit"]
	if script_inst_dict.has("entry_parameters"):
		_load_entry_parameters_from_json(script_inst_dict["entry_parameters"])
	if script_inst_dict.has("script_id"):
		script_id = script_inst_dict["script_id"]
		Net.script_client.set_script_instance_is_using_script_id(self)


## Must be run only after setup_script_instance_data()
func setup_script_data(script_entity_data: Dictionary) -> void:
	if script_entity_data.has("name"):
		script_name = script_entity_data["name"]


func script_instance_changed() -> void:
	script_contents_changed.emit()
	request_save_script_instance.emit()


func script_data_contents_changed() -> void:
	sync_script_inst_params_with_script_data()
	script_contents_changed.emit()
	var updated_script_data: Dictionary = serialize_script_entity_data()
	if is_script_asset:
		Net.script_client.update_script_asset_data(updated_script_data)
	else:
		Net.script_client.update_script_entity(updated_script_data)


func script_data_contents_deleted() -> void:
	script_contents_deleted.emit()


func sync_script_inst_params_with_script_data() -> void:
	assert(false, "This method must be overridden in a derived class.")


func serialize_script_entity_data() -> Dictionary:
	assert(false, "This method must be overridden in a derived class.")
	return {} # Unreachable.


## This is called when receiving data from the network. Updates the entity data
## of the script associated with this instance (blocks and comments), but
## not other data in the instance (such as enabled or parameter overrides).
func update_script_entity_data_from_network(script_entity_data: Dictionary) -> void:
	assert(false, "This method must be overridden in a derived class.")


# Parameter methods.
func _load_entry_parameters_from_json(entry_parameter_json: Dictionary) -> void:
	assert(entry_parameters.is_empty(), "This method expects to only be called once. If calling multiple times is needed, add support for that.")
	entry_parameters = entry_parameter_json.duplicate(true)
	for entry_id in entry_parameters:
		var params_for_entry: Dictionary = entry_parameters[entry_id]
		for param_name in params_for_entry:
			var param_array: Array = params_for_entry[param_name]
			param_array[1] = Serialization.type_convert_from_json(param_array[1], param_array[0])


func _serialize_entry_parameters_to_json() -> Dictionary:
	var serialized_params: Dictionary = {}
	for entry_id in entry_parameters:
		var params_for_entry: Dictionary = entry_parameters[entry_id]
		if params_for_entry.is_empty():
			continue
		params_for_entry = params_for_entry.duplicate(true)
		serialized_params[entry_id] = params_for_entry
		for param_name in params_for_entry:
			var param_array: Array = params_for_entry[param_name]
			param_array[1] = Serialization.type_convert_to_json(param_array[1])
	return serialized_params


static func create(script_inst_dict: Dictionary) -> ScriptInstance:
	var script_type: String = script_inst_dict.get("type", "MirrorVisualScript")
	var script_instance: ScriptInstance
	if script_type == "GDScript":
		script_instance = GDScriptInstance.new()
	else:
		script_instance = VisualScriptInstance.new()
	script_instance.setup_script_instance_data(script_inst_dict)
	return script_instance
