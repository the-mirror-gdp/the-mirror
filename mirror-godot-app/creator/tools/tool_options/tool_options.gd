extends Control


var _creator_ui: CreatorUI
var _object_creation: Control

@onready var _creator_title_tab = $CreatorTitleTab
@onready var _terrain_options = _creator_title_tab.get_node(^"TerrainOptions")
@onready var _model_tool_options = _creator_title_tab.get_node(^"ModelToolOptions")
@onready var _map_options = _creator_title_tab.get_node(^"MapOptions")


func setup(creator_ui: CreatorUI, object_creation: Control) -> void:
	_creator_ui = creator_ui
	_object_creation = object_creation
	_terrain_options.setup(creator_ui)
	_map_options.setup(creator_ui)
	_creator_title_tab.show_close_button = true
	PlayerData.game_mode_changed.connect(_game_mode_changed)
	set_game_mode(PlayerData.game_mode.get_current_mode())


func setup_model_tool_options(model_tool: Node) -> void:
	_model_tool_options.setup(model_tool)


func edit_mode_changed(new_mode: Enums.EDIT_MODE) -> void:
	match new_mode:
		Enums.EDIT_MODE.Terrain:
			_creator_title_tab.primary_name = "Terrain Tool"
			_creator_title_tab.refresh()
			_terrain_options.show()
			_model_tool_options.hide()
			_map_options.hide()
		Enums.EDIT_MODE.Model:
			_creator_title_tab.primary_name = "Primitive Builder"
			_creator_title_tab.refresh()
			_terrain_options.hide()
			_model_tool_options.show()
			_map_options.hide()
		Enums.EDIT_MODE.Map:
			_creator_title_tab.primary_name = "Map Creator"
			_creator_title_tab.refresh()
			_terrain_options.hide()
			_model_tool_options.hide()
			_map_options.show()
	if _map_options.visible and new_mode == Enums.EDIT_MODE.Asset and get_viewport().gui_is_dragging():
		# Do not hide map options, we can drag assets
		# set back to Map when asset is dragged!!
		_map_options.emit_map_mode_toggle()
		return
	if PlayerData.game_mode.get_current_mode() != GameMode.Mode.BUILD or new_mode == Enums.EDIT_MODE.Asset:
		hide()
		return
	show()


func _game_mode_changed(new_mode: GameMode.Mode, _previous_mode: GameMode.Mode) -> void:
	set_game_mode(new_mode)


func set_game_mode(new_mode: GameMode.Mode) -> void:
	if new_mode != GameMode.Mode.BUILD or _creator_ui.is_edit_mode(Enums.EDIT_MODE.Asset):
		hide()
		return
	show()


func _on_creator_title_tab_close_button_pressed():
	_object_creation.toggle_browser_expanded()
