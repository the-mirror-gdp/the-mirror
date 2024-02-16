# Logs errors and other info for the player
class_name DebugUI
extends Control


@onready var anim_player = $AnimationPlayer
@onready var label = $VBoxContainer/Log/Label


func add_log(text: String) -> void:
	self.hide()
	label.text = text
	anim_player.play("add_log")
