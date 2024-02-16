extends Button


func _ready():
	Zone.mode_changed.connect(_on_zone_mode_changed)
	Zone.client.connected.connect(_on_zone_connected)


func _on_zone_connected() -> void:
	visible = Zone.current_mode != Zone.ZONE_MODE.PLAY and Zone.space.get("play_server") != true


func _on_zone_mode_changed(new_zone_mode) -> void:
	visible = new_zone_mode != Zone.ZONE_MODE.PLAY and Zone.space.get("play_server") != true
