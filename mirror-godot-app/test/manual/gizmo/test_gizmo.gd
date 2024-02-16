extends Node


@onready var _gizmo = $Gizmo
@onready var _selection_helper = $SelectionHelper


func _enter_tree():
	# TODO: Instead of just deleting this when running the test scene,
	# we should make GameUI only instanced when needed on clients.
	# TODO: Also, if this was free instead of queue_free, ToolManager
	# would currently break, we should make it a child of CreatorUI.
	GameUI.queue_free()


func _ready():
	_gizmo.set_gizmo_type(Enums.GIZMO_TYPE.MOVE)
	var new_nodes: Array[Node] = [$TestBox1]
	_selection_helper.select_nodes(new_nodes)


func _unhandled_input(input_event: InputEvent) -> void:
	if input_event.is_action_pressed(&"tool_2"):
		_gizmo.set_gizmo_type(Enums.GIZMO_TYPE.MOVE)
	elif input_event.is_action_pressed(&"tool_3"):
		_gizmo.set_gizmo_type(Enums.GIZMO_TYPE.ROTATE)
	elif input_event.is_action_pressed(&"tool_4"):
		_gizmo.set_gizmo_type(Enums.GIZMO_TYPE.SCALE)


func _on_box_1_pressed() -> void:
	var new_nodes: Array[Node] = [$TestBox1]
	_selection_helper.select_nodes(new_nodes)


func _on_box_2_pressed() -> void:
	var new_nodes: Array[Node] = [$TestBox2]
	_selection_helper.select_nodes(new_nodes)


func _on_box_both_pressed() -> void:
	var new_nodes: Array[Node] = [$TestBox1, $TestBox2]
	_selection_helper.select_nodes(new_nodes)


func _on_box_none_pressed() -> void:
	var new_nodes: Array[Node] = []
	_selection_helper.select_nodes(new_nodes)


func _on_relative_toggled(button_pressed: bool) -> void:
	_gizmo.is_relative = button_pressed


func _on_snap_toggled(button_pressed: bool) -> void:
	_gizmo.is_snap_checked = button_pressed
