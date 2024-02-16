extends Node


const _LABEL_SCENE: PackedScene = preload("res://ui/floating_text/flat_floating_text.tscn")


func draw_text_at_screen_position(text: String, position: Vector2) -> void:
	for node in get_children():
		if node.get_text() == text:
			node.target_position = position
			node.modulate.a = 2.0
			return
	# Else, create a new node.
	var label: Control = _LABEL_SCENE.instantiate()
	add_child(label)
	label.setup(text, position)
