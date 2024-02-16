@tool
extends "inspector_deletable_base.gd"


@onready var _property_list = $PropertyList


func cleanup_and_delete() -> void:
	for property in _property_list.get_children():
		if property.has_method(&"cleanup_and_delete"):
			property.cleanup_and_delete()
	queue_free()
