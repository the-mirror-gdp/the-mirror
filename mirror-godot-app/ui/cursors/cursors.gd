class_name Cursors

const _grab_cursor = preload("res://ui/cursors/grab_cursor.svg")
const _default_cursor = preload("res://ui/cursors/default_cursor.svg")
const _asset_move_cursor = preload("res://ui/cursors/asset_move_cursor.svg")
const _not_allowed_cursor = preload("res://ui/cursors/not_allowed_cursor.svg")
const _object_builder_cursor = preload("res://ui/cursors/object_builder_cursor.svg")

enum {
	DEFAULT,
	NOT_ALLOWED,
	GRAB,
	ASSET_MOVE,
	OBJECT_BUILDER,
}


static func setup() -> void:
	# set default cursor.
	Input.set_custom_mouse_cursor(_default_cursor, Input.CURSOR_ARROW)
	# busy, can drop, and forbidden cursors show up when dragging new object into game.
	Input.set_custom_mouse_cursor(_grab_cursor, Input.CURSOR_BUSY)
	Input.set_custom_mouse_cursor(_grab_cursor, Input.CURSOR_CAN_DROP)
	Input.set_custom_mouse_cursor(_grab_cursor, Input.CURSOR_FORBIDDEN)


static func set_cursor(cursor: int = DEFAULT) -> void:
	Input.set_custom_mouse_cursor(_get_cursor_svg(cursor), Input.CURSOR_ARROW)


static func hide_cursor() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


static func show_cursor() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


static func _get_cursor_svg(cursor: int):
	match cursor:
		GRAB:
			return _grab_cursor
		DEFAULT:
			return _default_cursor
		NOT_ALLOWED:
			return _not_allowed_cursor
		ASSET_MOVE:
			return _asset_move_cursor
		OBJECT_BUILDER:
			return _object_builder_cursor
		_:
			return _default_cursor
