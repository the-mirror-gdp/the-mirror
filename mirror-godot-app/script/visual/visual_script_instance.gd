## ScriptInstance combines together multiple things:
## * A script with entry blocks that connect to signals to run.
## * A list of parameters that get passed to the entry blocks when run.
## * A node to be attached to (treated as the "self" object of the script)
class_name VisualScriptInstance
extends ScriptInstance


var script_builder: VisualScriptBuilder
var comments: Array[VisualScriptComment] = []

var execute_on_client: bool = false
var execute_on_server: bool = true


## Serializes a Dictionary of only valid JSON types for saving to the database.
## For example, we represent `Vector3(1, 2, 3)` as a JSON array of size 3 `[1, 2, 3]`.
func serialize_script_instance_to_json() -> Dictionary:
	var ret: Dictionary = super()
	ret["execute_on_client"] = execute_on_client
	ret["execute_on_server"] = execute_on_server
	ret["type"] = "MirrorVisualScript"
	# Keep the Dictionary keys sorted since they are sorted on the DB side,
	# and we want what we serialize here to be identical to what get saved.
	ret.sort()
	return ret


func cleanup_script_instance() -> void:
	if script_builder:
		script_builder.cleanup_for_deletion()
		script_builder.free()
		script_builder = null
	for comment in comments:
		comment.free()
	super()


func reset_all_blocks_evaluation_state() -> void:
	script_builder.reset_all_blocks_evaluation_state()


func apply_inspector_parameter_values() -> void:
	for entry_block in script_builder.entry_blocks:
		if entry_parameters.has(entry_block.entry_id):
			var params_for_entry: Dictionary = entry_parameters[entry_block.entry_id]
			entry_block.apply_inspector_parameter_values(params_for_entry)


func _populate_blocks(blocks_json: Array) -> void:
	if script_builder:
		script_builder.cleanup_for_deletion()
		script_builder.free()
	script_builder = VisualScriptBuilder.new(target_node)
	script_builder.create_blocks(blocks_json)
	if target_node:
		for entry_block in script_builder.entry_blocks:
			setup_entry_block_with_node(entry_block)
	sync_script_inst_params_with_script_data()
	script_builder.contents_changed.connect(script_data_contents_changed)
	script_builder.contents_deleted.connect(script_data_contents_deleted)
	script_builder.block_message.connect(_on_block_message)


func setup_entry_block_with_node(entry_block: ScriptBlockEntryBase) -> void:
	entry_block.script_instance = self
	_populate_event_node(entry_block)
	entry_block.setup_signal()


func is_script_instance_setup() -> bool:
	return script_builder != null


func setup_script_instance_data(script_inst_dict: Dictionary) -> void:
	if script_inst_dict.has("execute_on_client"):
		execute_on_client = script_inst_dict["execute_on_client"]
	if script_inst_dict.has("execute_on_server"):
		execute_on_server = script_inst_dict["execute_on_server"]
	super(script_inst_dict) # The code in this class is simple, so run super after.


## Must be run only after setup_script_instance_data()
func setup_script_entity_data(script_entity_data: Dictionary) -> void:
	super(script_entity_data) # The code in this class is complex, so run super before.
	if script_entity_data.has("blocks"):
		_populate_blocks(script_entity_data["blocks"])
	if script_entity_data.has("comments"):
		_load_comments_from_json(script_entity_data["comments"])


## This is called when receiving data from the network. Updates the data
## of the script associated with this instance (blocks and comments), but
## not other data in the instance (such as enabled or parameter overrides).
func update_script_entity_data_from_network(script_entity_data: Dictionary) -> void:
	var before_json: Dictionary = serialize_script_entity_data() if script_builder else {}
	script_name = script_entity_data["name"]
	if script_entity_data.has("blocks"):
		var blocks_json = script_entity_data["blocks"]
		if not is_instance_valid(script_builder) or \
				JSON.stringify(blocks_json) != JSON.stringify(script_builder.serialize_visual_script_builder_to_json()):
			_populate_blocks(blocks_json)
	if script_entity_data.has("comments"):
		var comments_json: Array = script_entity_data["comments"]
		if comments_json != _serialize_comments_to_json():
			_load_comments_from_json(comments_json)
	# Only emit script instance changed when the script changes affect the instance.
	# Do not use the contents_changed methods/signals because that would send a network update,
	# and this method update_script_entity_data_from_network() is ran when receiving a network update.
	if before_json.is_empty() or before_json != serialize_script_entity_data():
		script_entity_data_updated_from_network.emit()


func _populate_event_node(entry_block: ScriptBlockEntryBase) -> void:
	if entry_block.entry_path == "self":
		entry_block.entry_node = target_node
		return
	var node_path := NodePath(entry_block.entry_path)
	if node_path.is_absolute():
		entry_block.entry_node = Zone.get_node(node_path)
		return
	if target_node.has_node(node_path):
		entry_block.entry_node = target_node.get_node(node_path)
		return
	if not entry_block.entry_path.contains("/"):
		_create_event_node(entry_block)


func _create_event_node(entry_block: ScriptBlockEntryBase) -> void:
	entry_block.entry_path = TMNodeUtil.get_unique_child_name(target_node, entry_block.entry_path)
	var event_node: Node = GDScriptEntry.create_node_for_entry_signal(entry_block.entry_signal)
	if event_node == null:
		Notify.error("Script Event", "Unable to make a node for the entry: " + entry_block.entry_id, _load_self_in_script_editor)
		return
	event_node.name = entry_block.entry_path
	target_node.add_child(event_node)
	entry_block.entry_node = event_node


## Ensure the script instance entry inspector parameters match the
## signature of the script's data. Since a script may be used by
## multiple objects, parameters may get out of sync without this code.
func sync_script_inst_params_with_script_data() -> void:
	var old_entry_parameters: Dictionary = entry_parameters
	entry_parameters = {}
	for builder_entry in script_builder.entry_blocks:
		var entry_id: String = builder_entry.entry_id
		var new_params: Dictionary = builder_entry.parameters.inspector_parameters.duplicate(true)
		entry_parameters[entry_id] = new_params
		if entry_id in old_entry_parameters:
			var old_params: Dictionary = old_entry_parameters[entry_id]
			for old_key in old_params:
				if old_key in new_params:
					var old_param_array: Array = old_params[old_key]
					var new_param_array: Array = new_params[old_key]
					new_param_array[1] = old_param_array[1]
	entry_parameters.sort()
	apply_inspector_parameter_values()


func _on_block_message(script_block: ScriptBlock, title: String, message: String, status: Enums.NotifyStatus) -> void:
	if Zone.is_host():
		Zone.script_network_sync.server_script_print_notify(title, message, status)
		return
	var error_text: String = "" if status == Enums.NotifyStatus.INFO else message
	var click_callable: Callable = _load_self_in_script_editor.bind(script_block, error_text)
	if is_instance_valid(script_block.graph_node) and status != Enums.NotifyStatus.INFO:
		click_callable.call()
	Notify.status(title, message, status, click_callable)


func _load_self_in_script_editor(script_block: ScriptBlock = null, error_text: String = "") -> void:
	# It's unfortunate for ScriptEvent to depend on GameUI, but there isn't
	# really a better way. At least we will check if it exists first.
	if GameUI.creator_ui:
		GameUI.creator_ui.open_visual_script_editor(self, script_block, error_text)


func serialize_script_entity_data() -> Dictionary:
	# This is the inverse of setup_script_entity_data, it saves data for the Entity or Asset, not Instance.
	return {
		"blocks": script_builder.serialize_visual_script_builder_to_json(),
		"comments": _serialize_comments_to_json(),
		"id": script_id,
		"name": script_name,
		"type": "MirrorVisualScript",
	}


func _serialize_comments_to_json() -> Array:
	return serialize_some_comments_to_json(comments)


func serialize_some_comments_to_json(comments_to_serialize: Array[VisualScriptComment]) -> Array:
	var ret: Array[Dictionary] = []
	for script_comment in comments_to_serialize:
		ret.append(script_comment.serialize_visual_script_comment_to_json())
	return ret


func _load_comments_from_json(comment_json_array: Array) -> void:
	if comments.size() == comment_json_array.size():
		for i in range(comments.size()):
			comments[i].setup_from_json(comment_json_array[i])
		return
	if not comments.is_empty():
		for comment in comments:
			comment.free()
		comments.clear()
	for comment_json in comment_json_array:
		var script_comment = VisualScriptComment.new()
		script_comment.setup_from_json(comment_json)
		comments.append(script_comment)


func get_friendly_name_of_entry_id(entry_id: String) -> String:
	for entry_block in script_builder.entry_blocks:
		if entry_block.entry_id == entry_id:
			return entry_block.graph_name
	return entry_id


func get_default_value_of_entry_inspector_parameter(entry_id: String, parameter_name: String) -> Variant:
	for entry_block in script_builder.entry_blocks:
		if entry_block.entry_id == entry_id:
			var param_data = entry_block.parameters.inspector_parameters.get(parameter_name)
			return param_data[1] if param_data else null
	return null


func can_execute() -> bool:
	if MirrorScriptServer.is_execution_override_enabled:
		return true
	if not super():
		return false
	# Check if it's the client or server and if that's allowed for this event.
	if Zone.is_host():
		if not execute_on_server:
			return false
	else:
		if not execute_on_client:
			return false
	return true
