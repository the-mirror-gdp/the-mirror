extends Node3D


@onready var animator = get_node("AnimationPlayer")
@onready var model = get_node("Model")

var test_value: int = -1:
	get:
		return test_value


func _notification(what):
	if what == NOTIFICATION_SCENE_INSTANTIATED:
		test_value = 0
	if what == NOTIFICATION_READY:
		animator.play("idle")


func increase_test_value(by: int):
	test_value += by
