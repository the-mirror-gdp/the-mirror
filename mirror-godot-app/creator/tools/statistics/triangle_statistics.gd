extends "res://creator/tools/statistics/statistics.gd"


@onready var _viewport: Viewport


func _ready() -> void:
	super()
	Zone.social_manager.player_connected.connect(_on_social_manager_player_connected, CONNECT_DEFERRED)


func _on_social_manager_player_connected(player: Player) -> void:
	if Zone.is_host():
		return
	if not player.is_local_player():
		return
	_viewport = player.camera_get_viewport()


func _process(_delta):
	if not is_instance_valid(_viewport):
		return

	set_progress(_viewport.get_render_info(
		Viewport.RENDER_INFO_TYPE_VISIBLE,
		Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME
	))
