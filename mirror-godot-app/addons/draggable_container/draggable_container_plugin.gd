@tool
extends EditorPlugin


func _enter_tree():
	add_custom_type("DraggableContainer", "Container", preload("res://addons/draggable_container/draggable_container.gd"), preload("res://addons/draggable_container/draggable_container.svg"))


func _exit_tree():
	remove_custom_type("DraggableContainer")
