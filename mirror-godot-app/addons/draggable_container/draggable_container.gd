@icon("draggable_container.svg")
class_name DraggableContainer
extends Container


@export var is_vertical: bool = true
@export var dragger_size: float = 10.0
@export var start_dragger_visible: bool = true
@export var start_dragger_ratio: float = 0.25
@export var end_dragger_visible: bool = true
@export var end_dragger_ratio: float = 0.75
@export var auto_dragger_visible: bool = false

var _h_dragger_icon: Texture
var _v_dragger_icon: Texture
var _mouse_position: Vector2
var _child_control: Control
var _start_grabber: Control
var _end_grabber: Control
var _active_grabber: Control


func _init() -> void:
	_h_dragger_icon = load("res://addons/draggable_container/GuiHsplitter.svg")
	_v_dragger_icon = load("res://addons/draggable_container/GuiVsplitter.svg")
	child_entered_tree.connect(_on_child_entered_tree)
	child_exiting_tree.connect(_on_child_exiting_tree)


func _enter_tree() -> void:
	_start_grabber = _setup_new_grabber()
	_start_grabber.name = &"DraggableContainerInternalStartGrabber"
	_end_grabber = _setup_new_grabber()
	_end_grabber.name = &"DraggableContainerInternalEndGrabber"
	add_child(_start_grabber, false, Node.INTERNAL_MODE_FRONT)
	add_child(_end_grabber, false, Node.INTERNAL_MODE_BACK)


func _process(_delta: float) -> void:
	if _active_grabber != null:
		_process_active_grabbing()
	if auto_dragger_visible:
		start_dragger_visible = start_dragger_ratio > 0.0001 or end_dragger_ratio > 0.9999
		end_dragger_visible = start_dragger_ratio < 0.0001 or end_dragger_ratio < 0.9999
	var desired_child_rect: Rect2 = _calculate_desired_rect()
	fit_child_in_rect(_child_control, desired_child_rect)
	_update_dragger_nodes(desired_child_rect)


func _process_active_grabbing() -> void:
	var available_size: float
	var min_size_ratio: float
	var target_pos: float
	if is_vertical:
		available_size = _calculate_available_size(size.y)
		min_size_ratio = _child_control.custom_minimum_size.y / available_size
	else:
		available_size = _calculate_available_size(size.x)
		min_size_ratio = _child_control.custom_minimum_size.x / available_size
	if _active_grabber == _start_grabber:
		if is_vertical:
			target_pos = _mouse_position.y
		else:
			target_pos = _mouse_position.x
		start_dragger_ratio = target_pos / available_size
		start_dragger_ratio = clampf(start_dragger_ratio, 0.0, end_dragger_ratio - min_size_ratio)
	else: # _active_grabber == _end_grabber:
		if is_vertical:
			target_pos = _mouse_position.y - dragger_size
		else:
			target_pos = _mouse_position.x - dragger_size
		end_dragger_ratio = target_pos / available_size
		end_dragger_ratio = clampf(end_dragger_ratio, start_dragger_ratio + min_size_ratio, 1.0)


func _on_grabber_gui_input(input_event: InputEvent, grabber_node: Control) -> void:
	if input_event is InputEventMouseMotion:
		_mouse_position = input_event.position + grabber_node.position - grabber_node.size * 0.5
		get_viewport().set_input_as_handled()
	elif input_event is InputEventMouseButton:
		if input_event.button_index == MOUSE_BUTTON_LEFT:
			if input_event.pressed:
				_active_grabber = grabber_node
			else:
				_active_grabber = null
			get_viewport().set_input_as_handled()


func _update_dragger_nodes(desired_child_rect: Rect2) -> void:
	var dragger_sized_rect: Rect2 = desired_child_rect
	if is_vertical:
		dragger_sized_rect.size.y = dragger_size
	else:
		dragger_sized_rect.size.x = dragger_size
	if start_dragger_visible:
		var start_rect: Rect2 = dragger_sized_rect
		if is_vertical:
			start_rect.position.y -= dragger_size
		else:
			start_rect.position.x -= dragger_size
		fit_child_in_rect(_start_grabber, start_rect)
	if end_dragger_visible:
		var end_rect: Rect2 = dragger_sized_rect
		if is_vertical:
			end_rect.position.y += desired_child_rect.size.y
		else:
			end_rect.position.x += desired_child_rect.size.x
		fit_child_in_rect(_end_grabber, end_rect)
	_start_grabber.visible = start_dragger_visible
	_end_grabber.visible = end_dragger_visible


func get_unused_space_rect() -> Rect2:
	var rect := Rect2(Vector2.ZERO, size)
	var is_end_dominant: bool = 1.0 - end_dragger_ratio > start_dragger_ratio
	if is_vertical:
		var available_size_y: float = _calculate_available_size(size.y)
		if is_end_dominant:
			rect.position.y = end_dragger_ratio * available_size_y + dragger_size
			rect.size.y = (1.0 - end_dragger_ratio) * available_size_y
		else:
			rect.size.y = start_dragger_ratio * available_size_y
	else:
		var available_size_x: float = _calculate_available_size(size.x)
		if is_end_dominant:
			rect.position.x = end_dragger_ratio * available_size_x + dragger_size
			rect.size.x = (1.0 - end_dragger_ratio) * available_size_x
		else:
			rect.size.x = start_dragger_ratio * available_size_x
	return rect


func _calculate_desired_rect() -> Rect2:
	var rect := Rect2()
	if is_vertical:
		var available_size_y: float = _calculate_available_size(size.y)
		rect.position.y = start_dragger_ratio * available_size_y
		if start_dragger_visible:
			rect.position.y += dragger_size
		rect.size.y = (end_dragger_ratio - start_dragger_ratio) * available_size_y
		rect.size.x = size.x
	else:
		var available_size_x: float = _calculate_available_size(size.x)
		rect.position.x = start_dragger_ratio * available_size_x
		if start_dragger_visible:
			rect.position.x += dragger_size
		rect.size.x = (end_dragger_ratio - start_dragger_ratio) * available_size_x
		rect.size.y = size.y
	return rect


func _calculate_available_size(dir_size: float) -> float:
	if start_dragger_visible:
		dir_size -= dragger_size
	if end_dragger_visible:
		dir_size -= dragger_size
	return dir_size


func _setup_new_grabber() -> TextureRect:
	var grabber = TextureRect.new()
	grabber.gui_input.connect(_on_grabber_gui_input.bind(grabber))
	grabber.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	grabber.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if is_vertical:
		grabber.mouse_default_cursor_shape = Control.CURSOR_VSPLIT
		grabber.texture = _v_dragger_icon
	else:
		grabber.mouse_default_cursor_shape = Control.CURSOR_HSPLIT
		grabber.texture = _h_dragger_icon
	return grabber


func _on_child_entered_tree(node: Node) -> void:
	if node == _start_grabber or node == _end_grabber:
		return
	if node is Control:
		if is_instance_valid(_child_control):
			printerr("DraggableContainer only supports one child Control node. Ignoring '" + str(node.name) + "'.")
			return
		_child_control = node


func _on_child_exiting_tree(node: Node) -> void:
	if node == _child_control:
		_child_control = null
