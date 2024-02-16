@tool
@icon("style_box_multi.svg")
## Style box that can draw multiple style boxes.
## It can be used to combine multiple style boxes into one.
class_name StyleBoxMulti
extends StyleBox


@export var style_boxes: Array[StyleBox] = []


func _draw(canvas_item: RID, rect: Rect2) -> void:
	for style_box in style_boxes:
		style_box.draw(canvas_item, rect)
