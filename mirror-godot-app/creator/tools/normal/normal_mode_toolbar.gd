class_name NormalToolbar
extends Control


signal gizmo_button_pressed(gizmo_part: int)


@onready var _gizmo_options = $GizmoOptions
@onready var _terrain_options = $TerrainOptions


func setup(creator_ui: CreatorUI) -> void:
	_terrain_options.setup(creator_ui)
	PlayerData.game_mode_changed.connect(_game_mode_changed)
	set_game_mode(PlayerData.game_mode.get_current_mode())


func edit_mode_changed(new_mode: Enums.EDIT_MODE) -> void:
	match new_mode:
		Enums.EDIT_MODE.Asset:
			_gizmo_options.show()
			_terrain_options.hide()
		Enums.EDIT_MODE.Terrain:
			_gizmo_options.hide()
			_terrain_options.show()


func _game_mode_changed(new_mode: GameMode.Mode, _previous_mode: GameMode.Mode) -> void:
	set_game_mode(new_mode)


func set_game_mode(new_mode: GameMode.Mode) -> void:
	if new_mode == GameMode.Mode.NORMAL:
		show()
	else:
		hide()


func set_gizmo_type(new_type: int, snap_step: float) -> void:
	_gizmo_options.set_gizmo_type(new_type, snap_step)


func set_gizmo_relative(new_relative: bool) -> void:
	_gizmo_options.set_gizmo_relative(new_relative)


func set_gizmo_snap_checked(new_checked: bool) -> void:
	_gizmo_options.set_gizmo_snap_checked(new_checked)


func _on_gizmo_options_gizmo_button_pressed(gizmo_part):
	gizmo_button_pressed.emit(gizmo_part)
