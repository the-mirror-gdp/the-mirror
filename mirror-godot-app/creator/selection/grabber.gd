extends Node


signal grabbing_started
signal grabbing_ended

const MIN_DRAG_AMOUNT: float = 2.0

@export var selection_helper: Node3D

var is_enabled: bool = false
var is_grabbing_object: bool = false

var _can_drag: bool = false


func _process(_delta) -> void:
	if Zone.is_in_play_mode():
		return
	if not is_grabbing_object or not _can_drag:
		return
	var local_player: Player = PlayerData.get_local_player()
	if not is_instance_valid(local_player):
		is_grabbing_object = false
		return
	selection_helper.process_grabbing(local_player)



func _unhandled_input(input_event: InputEvent) -> void:
	if input_event is InputEventMouseMotion:
		if input_event.relative.length() >= MIN_DRAG_AMOUNT and is_grabbing_object:
			_can_drag = true
	if is_grabbing_object and input_event.is_action_released(&"primary_action"):
		finish_grabbing()
		get_viewport().set_input_as_handled()


func try_start_grabbing(object: Node3D) -> void:
	if not is_enabled or is_grabbing_object or not is_instance_valid(object):
		return
	## Do not allow grabbing maps even when they are selected
	if object is SpaceObject and object.asset_type == Enums.ASSET_TYPE.MAP:
		return
	if not Util.can_edit_object_in_space(object):
		return
	is_grabbing_object = true
	selection_helper.start_grabbing(object)
	grabbing_started.emit()


func finish_grabbing() -> void:
	if not is_grabbing_object:
		return
	_can_drag = false
	is_grabbing_object = false
	selection_helper.finish_grabbing()
	grabbing_ended.emit()


func cancel_grabbing() -> void:
	if not is_grabbing_object:
		return
	_can_drag = false
	is_grabbing_object = false
	selection_helper.cancel_grabbing()
	grabbing_ended.emit()
