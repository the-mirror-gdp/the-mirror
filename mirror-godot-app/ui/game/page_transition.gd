extends Control


@onready var _animation_player = $AnimationPlayer


func _ready() -> void:
	play_fade_animation()


func play_fade_animation(_new_page_name = null) -> void:
	show()
	if _animation_player.is_playing():
		_animation_player.stop()
	_animation_player.play("FadeIn")


func _on_animation_player_animation_finished(_anim_name) -> void:
	hide()
