# Finds all the children of target_node_path with BaseButton type and ensures sound is played
# when those buttons are clicked
extends Node


@export var target_node_path: NodePath = NodePath("..")

@onready var _click_sound: AudioStreamPlayer = $ClickSound


func _ready() -> void:
	refresh()


func _on_base_button_pressed():
	_click_sound.play()


func refresh():
	var target_node = get_node(target_node_path)
	var buttons = TMNodeUtil.recursive_find_nodes_by_type(target_node, BaseButton)
	for button in buttons:
		var btn: BaseButton = button as BaseButton
		if not btn.pressed.is_connected(_on_base_button_pressed):
			btn.pressed.connect(_on_base_button_pressed)
