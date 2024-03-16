# This is the script instance inspector category, the bulk of the code
# can be found in the creator/selection/inspector/script/ folder.
extends InspectorCategoryBase


signal request_script_edit(script_instance: ScriptInstance)
signal request_delete_prompt()

const _ENTRY_PARAM_INSPECTOR: PackedScene = preload("res://creator/selection/inspector/script/inspector_script_entry_inputs.tscn")

var target_node: Node # SpaceObject or SpaceGlobalScripts
var target_script_instance: ScriptInstance
var _queue_update_script_entity_frames: int = -1

@onready var _property_list: Control = $Properties/MarginContainer/PropertyList
@onready var _entry_list_vbox: Control = _property_list.get_node(^"EntryList")

@onready var _name_title_hbox: Control = $CategoryTitle/ToggleButton/Name
@onready var _name_text_label: Label = _name_title_hbox.get_node(^"Text")
@onready var _name_line_edit: LineEdit = _name_title_hbox.get_node(^"ScriptName")
@onready var _trash_button = _name_title_hbox.get_node(^"TrashButton")

@onready var _script_options: Control = _property_list.get_node(^"ScriptOptions")
@onready var _run_enabled: CheckBox = _script_options.get_node(^"RunEnabled")
@onready var _run_in_edit: CheckBox = _script_options.get_node(^"RunInEditMode")

@onready var _advanced_options: Control = _property_list.get_node(^"AdvancedOptions")
@onready var _run_on_client: CheckBox = _advanced_options.get_node(^"RunOnClient")
@onready var _run_on_server: CheckBox = _advanced_options.get_node(^"RunOnServer")


func _process(_delta) -> void:
	_queue_update_script_entity_frames -= 1
	if _queue_update_script_entity_frames == 0:
		target_script_instance.script_data_contents_changed()


func setup(script_instance: ScriptInstance) -> void:
	target_script_instance = script_instance
	target_script_instance.script_contents_changed.connect(_on_script_contents_changed)
	target_script_instance.script_entity_data_updated_from_network.connect(_on_script_contents_changed)
	target_script_instance.script_entries_changed.connect(_on_script_entries_changed)
	_setup()


func _setup() -> void:
	_refresh_name_and_buttons()
	var can_edit: bool = Util.can_local_user_edit_scripts()
	_set_script_inspector_editable(can_edit)
	_setup_entry_parameter_inspectors(can_edit)


func _refresh_name_and_buttons() -> void:
	_name_text_label.text = target_script_instance.script_name
	if _name_line_edit.text != _name_text_label.text:
		_name_line_edit.text = _name_text_label.text
	_run_enabled.set_pressed_no_signal(target_script_instance.script_enabled)
	_run_in_edit.set_pressed_no_signal(target_script_instance.execute_in_edit)
	if target_script_instance is GDScriptInstance:
		_advanced_options.hide()
	elif target_script_instance is VisualScriptInstance:
		_setup_client_server_checkboxes(target_script_instance.execute_on_client, target_script_instance.execute_on_server)


func delete_script_instance_and_self() -> void:
	target_node.delete_script_instance(target_script_instance)
	cleanup_and_delete()
	target_node.queue_update_network_object()


func cleanup_and_delete() -> void:
	if is_instance_valid(target_script_instance):
		target_script_instance.script_contents_changed.disconnect(_on_script_contents_changed)
		target_script_instance.script_entity_data_updated_from_network.disconnect(_on_script_contents_changed)
	target_script_instance = null
	for property in _entry_list_vbox.get_children():
		if property.has_method(&"cleanup_and_delete"):
			property.cleanup_and_delete()
	super()


func _set_script_inspector_editable(is_editable: bool) -> void:
	_name_line_edit.editable = is_editable
	_trash_button.visible = is_editable
	var disabled: bool = not is_editable
	_run_enabled.disabled = disabled
	_run_in_edit.disabled = disabled
	_run_on_client.disabled = disabled
	_run_on_server.disabled = disabled


func _setup_client_server_checkboxes(on_client: bool, on_server: bool) -> void:
	_run_on_client.set_pressed_no_signal(on_client)
	_run_on_server.set_pressed_no_signal(on_server)
	if GameplaySettings.script_show_client_server_checkboxes:
		return
	if on_client or not on_server:
		return
	# Hide when the show setting isn't enabled, AND the checkboxes are in the default
	# configuration (if they're not, all users should see it to avoid surprises).
	_advanced_options.hide()


func _setup_entry_parameter_inspectors(is_editable: bool) -> void:
	if not target_script_instance.is_script_instance_setup():
		Notify.error("Unable To Inspect Script", "The script instance is not set up with its script entity data.")
		return
	for child in _entry_list_vbox.get_children():
		_entry_list_vbox.remove_child(child)
		child.queue_free()
	var entry_ids: Array = target_script_instance.entry_parameters.keys()
	for entry_id in entry_ids:
		var friendly_name: String = target_script_instance.get_friendly_name_of_entry_id(entry_id)
		var entry_param_insp: Node = _ENTRY_PARAM_INSPECTOR.instantiate()
		entry_param_insp.refresh_inspected_nodes.connect(_on_entry_parameter_inspector_refresh_inspected_nodes)
		entry_param_insp.setup(target_node, target_script_instance, entry_id, friendly_name, is_editable)
		_entry_list_vbox.add_child(entry_param_insp)
		if entry_ids.size() <= 2:
			entry_param_insp.set_visible_to_maximum_size()


func _on_entry_parameter_inspector_refresh_inspected_nodes() -> void:
	refresh_inspected_nodes.emit()
	if is_instance_valid(target_script_instance):
		request_script_edit.emit(target_script_instance)


func _on_enabled_toggled(button_pressed: bool) -> void:
	target_script_instance.script_enabled = button_pressed
	target_script_instance.script_instance_changed()


func _on_trash_button_pressed() -> void:
	request_delete_prompt.emit()


func _on_script_open_script_editor() -> void:
	request_script_edit.emit(target_script_instance)


func _on_run_in_edit_mode_toggled(button_pressed: bool) -> void:
	target_script_instance.execute_in_edit = button_pressed
	target_script_instance.script_instance_changed()


func _on_run_on_client_toggled(button_pressed: bool) -> void:
	target_script_instance.execute_on_client = button_pressed
	target_script_instance.script_instance_changed()


func _on_run_on_server_toggled(button_pressed: bool) -> void:
	target_script_instance.execute_on_server = button_pressed
	target_script_instance.script_instance_changed()


func _on_script_name_text_changed(new_text: String) -> void:
	# Note: The name is part of the script entity, not the instance.
	target_script_instance.script_name = new_text
	queue_update_script_entity()


func _on_script_contents_changed() -> void:
	_refresh_name_and_buttons()


func _on_script_entries_changed() -> void:
	var can_edit: bool = Util.can_local_user_edit_scripts()
	_setup_entry_parameter_inspectors(can_edit)


func queue_update_script_entity() -> void:
	target_script_instance.script_contents_changed.emit() # This updates it locally immediately.
	_queue_update_script_entity_frames = 50
