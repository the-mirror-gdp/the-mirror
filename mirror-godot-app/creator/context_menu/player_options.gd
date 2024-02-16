extends VBoxContainer


signal teleport_local_player_near_point(teleport_position: Vector3)

const CAMERA_FOCUS_DISTANCE: float = 10.0

var _context_menu: PanelContainer = null
var _player: Player = null


func setup(context_menu: PanelContainer) -> void:
	_context_menu = context_menu
	_context_menu.context_menu_closed.connect(hide)


func open(player: Player) -> void:
	_player = player
	show()


func _on_focus_pressed() -> void:
	if not is_instance_valid(_player):
		return
	var local_player = PlayerData.get_local_player()
	if not local_player:
		return
	local_player.camera_change_focus_point(_player.global_transform.origin)
	local_player.camera_change_focus_point_zoom(CAMERA_FOCUS_DISTANCE)
	_context_menu.close()


func _on_teleport_pressed() -> void:
	if is_instance_valid(_player):
		teleport_local_player_near_point.emit(_player.global_position)
	_context_menu.close()


func _on_copy_user_id_pressed() -> void:
	if not is_instance_valid(_player):
		return
	var player_id: String = _player.name
	DisplayServer.clipboard_set(player_id)
	Notify.info("Player ID Copied", player_id)
	_context_menu.close()


func _on_copy_display_name_pressed() -> void:
	if not is_instance_valid(_player):
		return
	var player_name: String = _player.get_player_name()

	DisplayServer.clipboard_set(player_name)
	Notify.info("Player Name Copied", player_name)
	_context_menu.close()
