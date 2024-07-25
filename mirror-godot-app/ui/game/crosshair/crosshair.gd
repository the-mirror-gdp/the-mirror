extends Control


@onready var _hit_marker: Control = %HitMarker
@onready var _hit_sound: AudioStreamPlayer = %HitSound
var _local_player: Player = null
var _hit_sounds: Array = [
	"res://ui/game/crosshair/sounds/bullet_hitmark_001.wav",
	"res://ui/game/crosshair/sounds/bullet_hitmark_002.wav",
]
var _minimum_size: float = 8.0
var _maximum_size: float = 1000.0
var _spread_multiplier: float = 0.7
var _lerp_speed: float = 32.0
var _hit_marker_tween: Tween = null
var _current_color: Color = Color.WHITE


func _process(delta: float) -> void:
	if Zone.is_host():
		return
	if not PlayerData.has_local_player():
		return
	_local_player = PlayerData.get_local_player()

	var equipable: Equipable = _local_player.equipable_controller.get_current_equipable()
	if equipable and equipable.has_method("get_bullet_spread"):
		var crosshair_size: float = rad_to_deg(equipable.get_bullet_spread()) * _spread_multiplier
		crosshair_size = clampf(crosshair_size, _minimum_size, _maximum_size)
		GameUI.instance.crosshair.custom_minimum_size = lerp(GameUI.instance.crosshair.custom_minimum_size, Vector2.ONE * crosshair_size, delta * _lerp_speed)

	_update_crosshair_colors()

	visible = equipable and not _local_player.is_dead() and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and \
	(Zone.is_in_play_mode() or PlayerData.game_mode.get_current_mode() == GameMode.Mode.NORMAL)


func show_hitmarker() -> void:
	_hit_marker.show()
	_hit_marker.modulate = Color.WHITE
	_hit_marker.scale = Vector2.ONE
	if _hit_marker_tween:
		_hit_marker_tween.kill()
	_hit_marker_tween = create_tween()
	_hit_marker_tween.tween_property(_hit_marker, "modulate", Color.TRANSPARENT, 0.4)
	_hit_marker_tween.parallel().tween_property(_hit_marker, "scale", Vector2.ONE * 1.6, 0.2)
	_hit_marker_tween.tween_callback(_hit_marker.hide)
	_hit_sound.stream = load(_hit_sounds.pick_random())
	_hit_sound.play()


func set_color(new_color: Color) -> void:
	_current_color = new_color


func _update_crosshair_colors() -> void:
	var raycast_dict: Dictionary = _local_player.equipable_controller.get_raycast()
	var hit_object = raycast_dict.get("collider")
	if hit_object and hit_object is Player and hit_object != _local_player:
		if hit_object.get_player_team() == _local_player.get_player_team():
			modulate = Color.GREEN
		else:
			modulate = Color.RED
		return
	modulate = _current_color
