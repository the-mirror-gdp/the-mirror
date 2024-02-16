extends Control

var is_browser_expanded: bool = false
var _browser_expanded_size := Vector2.ZERO
var is_build_mode: bool = false
var _local_player: Player = null
var _selected_asset_id: String = ""

@onready var _asset_browser = $Sidebar/AssetBrowser
@onready var _tool_options = $Sidebar/ToolOptions
@onready var sidebar = $Sidebar


func setup(creator_ui: CreatorUI, script_editor: Control) -> void:
	_asset_browser.setup(self, script_editor)
	_tool_options.setup(creator_ui, self)


func _process(delta: float) -> void:
	var lerp_factor = clamp(delta * 10.0, 0.0, 1.0)
	var target_position = 0.0 if is_browser_expanded else -_asset_browser.size.x
	sidebar.offset_left = lerpf(sidebar.offset_left, target_position, lerp_factor)
	sidebar.offset_right = 0.0
	sidebar.offset_top = lerpf(sidebar.offset_top, _browser_expanded_size.y, lerp_factor)


func toggle_browser_expanded() -> void:
	set_expanded(not is_browser_expanded)


func set_expanded(value: bool) -> void:
	is_browser_expanded = value
	_asset_browser.set_expanded(value)


func set_game_mode(new_mode) -> void:
	match new_mode:
		GameMode.Mode.BUILD:
			is_build_mode = true
			set_expanded(true)
		GameMode.Mode.NORMAL:
			is_build_mode = false
			set_expanded(false)


func edit_mode_changed(mode: Enums.EDIT_MODE) -> void:
	if mode != Enums.EDIT_MODE.Asset:
		set_selected_asset_id("")


func get_selected_asset_id() -> String:
	return _selected_asset_id


func set_selected_asset_id(asset_id: String) -> void:
	_validate_local_player()
	var space_role = Util.get_role_for_user(Zone.space, Net.user_id)
	if space_role < Enums.ROLE.CONTRIBUTOR and not asset_id.is_empty():
		Notify.warning("Permissions Error", "You don't have permissions to add new objects")
		return
	_local_player.set_placement_preview_asset_id(asset_id)
	_asset_browser.set_selected_asset_id(asset_id)


func _validate_local_player() -> void:
	if not is_instance_valid(_local_player):
		assert(PlayerData.has_local_player(), "There's no reason to try and select an asset ID if there is no player.")
		_local_player = PlayerData.get_local_player()


func _on_build_toolbar_is_expanded_changed(is_expanded, current_size):
	if is_expanded:
		_browser_expanded_size = current_size
		return
	_browser_expanded_size = Vector2.ZERO
