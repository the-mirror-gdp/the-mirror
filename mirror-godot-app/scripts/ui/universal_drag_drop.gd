class_name UniversalDragDrop
extends Control


# return the get drag data callable
var get_drag_data: Callable

# returns the drag data that godot use internally
func _get_drag_data(position: Vector2) -> Variant:
	return get_drag_data.call(get_meta("external_id"), self, position)


# How do I take this data?
# This checks if you can drop the data
# func _can_drop_data(position, data):
#	return typeof(data) == TYPE_DICTIONARY and data.has("color")
# This does the actual data drop
# func _drop_data(position, data):
#	var color = data["color"]
