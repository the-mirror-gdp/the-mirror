extends Control


signal script_editor_editing_script_instance(script_instance: ScriptInstance)
signal request_track_recently_used_space_script(script_instance: ScriptInstance)

var _creator_ui: CreatorUI
var _script_editor_holder: DraggableContainer
var _script_variable_editor: Control
var _script_instance: ScriptInstance
# Keep track of the last edited script's object and ID so we can
# reconnect when a network update destroys and re-creates the script.
var _last_edited_script_id: String
var _last_edited_attached_object: Object
var _recently_edited_scripts: Array[Dictionary] = []

@onready var _visual_script_editor = $VisualScriptEditor
@onready var _gd_script_editor = $GDScriptEditor
@onready var _script_entry_creation_dialog = $ScriptEntryCreationDialog
@onready var _script_entry_signal_tree_populator = $ScriptEntryCreationDialog/ScriptEntrySignalTreePopulator


func _ready() -> void:
	Net.script_client.request_clear_script_editor.connect(clear_script_editor)
	Net.script_client.request_edit_script_instance.connect(load_from_script_instance)
	_visual_script_editor.setup(_script_entry_signal_tree_populator)


func _process(_delta: float) -> void:
	_update_script_editor_position()


func setup(creator_ui: CreatorUI, script_editor_holder: DraggableContainer, script_variable_editor: Control) -> void:
	_creator_ui = creator_ui
	_script_editor_holder = script_editor_holder
	_script_variable_editor = script_variable_editor


func is_editing_script_id(script_id: String) -> bool:
	return _script_editor_holder.visible and _last_edited_script_id == script_id


func load_from_asset_data(asset_data: AssetData) -> void:
	if asset_data == null:
		close_script_editor()
		return
	var asset_promise: Promise = asset_data.get_asset_file_promise()
	var result = await asset_promise.wait_till_fulfilled()
	if not result is Dictionary:
		return
	var script_instance := ScriptInstance.create(result)
	script_instance.setup_script_entity_data(result)
	# Note: This ID code must be separate from the setup_script_instance_data()
	# script_id code, which is for Entities, not Assets.
	script_instance.script_id = result["id"]
	script_instance.is_script_asset = true
	_load_from_script_instance(script_instance)


func load_from_script_instance(script_instance: ScriptInstance, rezoom: bool = true) -> void:
	_load_from_script_instance(script_instance, rezoom)
	script_editor_editing_script_instance.emit(script_instance)


func _load_from_script_instance(script_instance: ScriptInstance, rezoom: bool = true) -> void:
	_script_instance = script_instance
	_track_recently_edited_script(script_instance)
	if script_instance is GDScriptInstance:
		_gd_script_editor.load_from_script_instance(script_instance)
		set_gd_script_editor_visibility(true)
	elif script_instance is VisualScriptInstance:
		_visual_script_editor.load_from_script_instance(script_instance, rezoom)
		set_visual_script_editor_visibility(true)
	_last_edited_script_id = script_instance.script_id
	_reconnect_scripts_changed_signal(script_instance.target_node)


func _track_recently_edited_script(script_instance: ScriptInstance) -> void:
	var script_id: String = script_instance.script_id
	var edited_script: Dictionary
	for recent_script in _recently_edited_scripts:
		if recent_script["script_id"] == script_id:
			recent_script["script_instance"] = script_instance
			recent_script["target_node"] = script_instance.target_node
			edited_script = recent_script
			break
	if edited_script.is_empty():
		edited_script = {
			"script_id": script_id,
			"script_instance": script_instance,
			"target_node": script_instance.target_node,
		}
		if _recently_edited_scripts.size() > 30:
			_recently_edited_scripts.remove_at(0)
	else:
		_recently_edited_scripts.erase(edited_script)
	_recently_edited_scripts.push_back(edited_script)


func request_close() -> void:
	if _script_entry_creation_dialog.visible:
		_script_entry_creation_dialog.hide()
		return
	if _script_variable_editor.visible:
		_script_variable_editor.toggle_variable_editor() # This does more than just .hide()
		return
	if _gd_script_editor.visible:
		_gd_script_editor.hide()
		_script_editor_holder.hide()
	elif _visual_script_editor.visible:
		if _visual_script_editor.request_close():
			_script_editor_holder.hide()
		else:
			return
	else:
		# If none of the dialogs are open, Esc closes the whole script editor.
		_script_editor_holder.hide()
	# If we haven't returned by now, we are closing some kind of entire editor.
	_script_instance = null
	_last_edited_attached_object = null
	_last_edited_script_id = ""


func clear_script_editor() -> void:
	_visual_script_editor.cleanup_and_clear_script_editor()
	_script_instance = null
	_last_edited_attached_object = null
	_last_edited_script_id = ""


func close_script_editor() -> void:
	clear_script_editor()
	_script_editor_holder.hide()


func focus_block_in_visual_script(script_instance: ScriptInstance, script_block: ScriptBlock, error_text: String) -> void:
	_visual_script_editor.focus_block_in_visual_script(script_instance, script_block, error_text)
	set_visual_script_editor_visibility(true)


func focus_line_in_text_script(script_instance: ScriptInstance, line_number: int, error_text: String) -> void:
	_gd_script_editor.focus_line_in_script(script_instance, line_number, error_text)
	set_gd_script_editor_visibility(true)


func delete_selection() -> void:
	if _visual_script_editor.visible:
		_visual_script_editor.delete_selection()


func duplicate_selection() -> void:
	if _visual_script_editor.visible:
		_visual_script_editor.duplicate_selection()


func copy_selection() -> void:
	if _visual_script_editor.visible:
		_visual_script_editor.copy_selection()


func paste_copied_data() -> void:
	if _visual_script_editor.visible:
		_visual_script_editor.paste_copied_data()


func set_gd_script_editor_visibility(is_editor_visible: bool) -> void:
	_script_editor_holder.visible = is_editor_visible
	_gd_script_editor.visible = is_editor_visible
	_visual_script_editor.visible = not is_editor_visible


func set_visual_script_editor_visibility(is_editor_visible: bool) -> void:
	_script_editor_holder.visible = is_editor_visible
	_gd_script_editor.visible = not is_editor_visible
	_visual_script_editor.visible = is_editor_visible


func show_error_in_gd_script_editor_if_open(script_instance: GDScriptInstance, line_number: int, error_text: String) -> bool:
	return _gd_script_editor.show_error_if_script_open(script_instance, line_number, error_text)


func _update_script_editor_position() -> void:
	var safe_area: Rect2 = _creator_ui.get_safe_area()
	_script_editor_holder.position = Vector2(roundf(safe_area.position.x), safe_area.position.y)
	_script_editor_holder.size = safe_area.size
	size.x = roundf(safe_area.size.x + 1.0)


func _reconnect_scripts_changed_signal(obj: Object) -> void:
	if (
			is_instance_valid(_last_edited_attached_object)
			and _last_edited_attached_object.has_signal(&"scripts_changed")
			and _last_edited_attached_object.scripts_changed.is_connected(_on_scripts_changed)
	):
		_last_edited_attached_object.scripts_changed.disconnect(_on_scripts_changed)
	_last_edited_attached_object = obj
	if obj and obj.has_signal(&"scripts_changed"):
		obj.scripts_changed.connect(_on_scripts_changed)


func _on_scripts_changed() -> void:
	# I was planning to check if _script_instance is a previously freed
	# object, but for some reason it goes straight to null on `.free()`?
	# Anyway, we'll just check if _last_edited_script_id is empty or not instead.
	if _last_edited_script_id.is_empty() or is_instance_valid(_script_instance):
		# If we weren't editing a script, or it's valid, we don't need to do anything.
		return
	if is_instance_valid(_last_edited_attached_object):
		# If the SpaceObject receives a network updates that deletes and
		# re-creates the script event, we need to re-load the script event.
		var script_instances: Array[ScriptInstance] = _last_edited_attached_object.get_script_instances()
		for script_instance in script_instances:
			if script_instance.script_id == _last_edited_script_id:
				load_from_script_instance(script_instance, false)
				return
	# Else, no instances on the object? Try just reloading from any instance.
	var script_instance: ScriptInstance = Net.script_client.get_any_script_instance_for_script_id(_last_edited_script_id)
	if script_instance:
		load_from_script_instance(script_instance, false)


func _on_request_toggle_variable_editor() -> void:
	_script_variable_editor.toggle_variable_editor()


func _on_request_show_entry_creation_dialog(target_node: Node) -> void:
	_script_entry_creation_dialog.populate_and_show(target_node)


func _on_request_show_custom_entry_creation_dialog(target_node: Node) -> void:
	_script_entry_creation_dialog.populate_and_show_for_custom(target_node)


func _on_script_entry_creation_dialog_create_entry_block(block_json: Dictionary) -> void:
	if _gd_script_editor.visible:
		if block_json["type"] == "entry":
			_gd_script_editor.create_entry_from_dialog(block_json)
		else:
			assert(false, "This should never be reached, GDScript does not have visual script blocks.")
	if _visual_script_editor.visible:
		if block_json["type"] == "entry":
			_visual_script_editor.create_entry_from_dialog(block_json)
		else:
			_visual_script_editor.create_new_script_block_from_json(block_json)


func _on_request_save_script_as_asset(script_instance: ScriptInstance) -> void:
	Net.script_client.save_script_as_asset(script_instance)


func _on_dialog_focus_entered() -> void:
	GameUI.grab_input_lock(self)


func _on_dialog_focus_exited() -> void:
	GameUI.release_input_lock(self)


func _on_request_track_recently_used_space_script(script_instance: ScriptInstance) -> void:
	request_track_recently_used_space_script.emit(script_instance)
