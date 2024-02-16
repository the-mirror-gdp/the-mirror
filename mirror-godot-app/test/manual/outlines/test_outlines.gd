extends Node3D


@onready var _object_outlines = $ObjectOutlines


func _process(_delta: float) -> void:
	var t := Transform3D()
	_object_outlines.draw_wireframe_capsule(t, 1.0, Color.GREEN)
