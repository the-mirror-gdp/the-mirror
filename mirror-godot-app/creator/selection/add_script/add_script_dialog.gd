extends KeyboardGrabbingConfirmationDialog


signal request_refresh()
signal request_script_edit(script_instance: ScriptInstance)

var _target_node: Node # SpaceObject or SpaceGlobalScripts
var _awaiting_script_instance_creation: bool = false

@onready var _add_script_menu = $AddScriptMenu
@onready var _ok_button: Button = get_ok_button()
@onready var _audio_stream_player_script_attached = $AudioStreamPlayerScriptAttached


func _ready() -> void:
	Net.script_client.script_instance_created.connect(_on_net_script_instance_created)


func popup_dialog(target_node: Node) -> void:
	_target_node = target_node
	_add_script_menu.populate_menu()
	if not GameplaySettings.script_quick_attach_existing:
		title = "Create Script"
		_add_script_menu.hide_add_script_filter_menu()
	size = Vector2.ZERO
	popup_centered()
	GameUI.grab_input_lock(self)
	if GameplaySettings.script_quick_attach_existing:
		title = "Create or Attach Script"
		_add_script_menu.focus_add_script_filter_menu()


func _on_confirmed() -> void:
	var script_id: String = _add_script_menu.get_desired_script_id()
	if script_id.is_empty():
		_show_attach_existing_menu()
		return
	_attach_existing_script(script_id)


func _show_attach_existing_menu() -> void:
	title = "Attach Existing Script"
	show()
	_add_script_menu.hide_create_new_script_buttons()
	_add_script_menu.focus_add_script_filter_menu()
	popup_centered()


func _attach_existing_script(existing_script_id: String) -> void:
	_awaiting_script_instance_creation = true
	hide()
	Net.script_client.attach_script_id_to_node(_target_node, existing_script_id)
	_audio_stream_player_script_attached.play()


func _create_new_visual_script() -> void:
	_create_new_script_base("MirrorVisualScript")


func _create_new_gd_script() -> void:
	_create_new_script_base("GDScript")


func _create_new_script_base(script_type: String) -> void:
	_awaiting_script_instance_creation = true
	hide()
	Net.script_client.client_create_new_script_entity(_target_node, script_type)
	_audio_stream_player_script_attached.play()


func _on_net_script_instance_created(created_script_instance: ScriptInstance) -> void:
	if not _awaiting_script_instance_creation:
		return
	_awaiting_script_instance_creation = false
	request_refresh.emit()
	request_script_edit.emit(created_script_instance)


func _on_script_id_selected() -> void:
	# Before letting the user attach, check if it's already attached.
	var desired_script_id: String = _add_script_menu.get_desired_script_id()
	for existing_script_instance in _target_node.get_script_instances():
		if existing_script_instance.script_id == desired_script_id:
			_ok_button.disabled = true
			return
	_ok_button.disabled = false


func _on_visibility_changed() -> void:
	_ok_button.disabled = false
