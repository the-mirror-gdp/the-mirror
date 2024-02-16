extends PanelContainer


const _OPEN_OFFSET := Vector2(12.0, 12.0)
const _SHIFT_OFFSET := Vector2(16.0, 16.0)

signal context_menu_closed()

@onready var _title_bar: PanelContainer = %TitleBar
@onready var _title: Label = %Title
@onready var _options_container: MarginContainer = %OptionsContainer
@onready var _asset_slot_options: VBoxContainer = %AssetSlotOptions
@onready var _recent_script_slot_options: VBoxContainer = %RecentScriptSlotOptions
@onready var _space_object_options: VBoxContainer = %SpaceObjectOptions
@onready var _model_node_options: VBoxContainer = %ModelNodeOptions
@onready var _extra_node_editor_options: VBoxContainer = %ExtraNodeEditorOptions
@onready var _map_build_node_options: VBoxContainer = %MapBuildNodeOptions
@onready var _player_options: VBoxContainer = %PlayerOptions
@onready var _click_sound: AudioStreamPlayer = %ClickSound
@onready var _rename_popup: PanelContainer = %RenamePopup

var _context_option_children: Array[Control] = []


func setup(creator_ui: CreatorUI) -> void:
	PlayerData.game_mode.game_mode_changed.connect(_on_game_mode_changed)
	creator_ui.scene_hierarchy.selection_changed.connect(_on_selection_changed)
	_asset_slot_options.setup(self, creator_ui)
	_recent_script_slot_options.setup(self, creator_ui)
	_space_object_options.setup(self, creator_ui, _rename_popup)
	_model_node_options.setup(self)
	_extra_node_editor_options.setup(self, creator_ui)
	_map_build_node_options.setup(self)
	_player_options.setup(self)
	_rename_popup.setup(creator_ui)
	context_menu_closed.connect(creator_ui.object_selection.refresh_inspector)
	for child in _options_container.get_children():
		if child is Control:
			_context_option_children.append(child)


func _input(event: InputEvent) -> void:
	if visible and event is InputEventMouseButton and event.pressed:
		var local = make_input_local(event)
		if not Rect2(Vector2.ZERO, get_rect().size).has_point(local.position):
			close()


func open_context_menu(target: Object, hit_position) -> void:
	if not is_instance_valid(target):
		return
	if target is Heightmap:
		_map_build_node_options.open(target)
	elif target is AssetSlot:
		_asset_slot_options.open(target)
	elif target is RecentScriptEntitySlot:
		_recent_script_slot_options.open(target)
	elif target is ModelSceneTree:
		_model_node_options.open(target)
	elif target is Player:
		_player_options.open(target)
		_show_title_bar(target.get_player_name())
	elif target is ExtraNodeVisualEditor:
		_extra_node_editor_options.open(target)
	elif target.get_parent() is ExtraNodeVisualEditor:
		_extra_node_editor_options.open(target.get_parent())
	else:
		var target_space_object = Util.get_space_object(target)
		if target_space_object:
			if hit_position == null:
				hit_position = target_space_object.global_position
			_space_object_options.open(target_space_object, hit_position)
			_show_title_bar(target_space_object.get_space_object_name())
		else:
			return
	# wait a frame to adjust for viewport_size changes
	await get_tree().process_frame
	set_visible(true)
	_click_sound.play()
	# Adjust the position. Ensure it does not go outside of the viewport.
	position = get_global_mouse_position() + _OPEN_OFFSET
	size = Vector2.ZERO
	var viewport_size: Vector2i = get_viewport_rect().size
	if position.x + size.x > viewport_size.x:
		position.x -= size.x + _SHIFT_OFFSET.x
	if position.y + size.y > viewport_size.y:
		position.y -= size.y + _SHIFT_OFFSET.y


func close() -> void:
	for child in _context_option_children:
		child.hide()
	_title_bar.hide()
	set_visible(false)
	context_menu_closed.emit()


func _show_title_bar(title: String) -> void:
	_title.text = title
	_title_bar.show()


func _on_teleport_local_player_near_point(teleport_position: Vector3 = Vector3.ZERO) -> void:
	var local_player = PlayerData.get_local_player()
	if not local_player:
		return
	local_player.teleport.rpc(teleport_position)


func _on_game_mode_changed(_new_mode: GameMode.Mode, _previous_mode: GameMode.Mode) -> void:
	close()


func _on_selection_changed(selected_nodes: Array[Node]) -> void:
	if not visible or not selected_nodes.is_empty():
		return
	close()
