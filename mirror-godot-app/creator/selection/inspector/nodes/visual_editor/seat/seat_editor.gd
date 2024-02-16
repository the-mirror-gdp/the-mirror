extends ExtraNodeVisualEditor


var _target_seat_dict: Dictionary
var _last_back_position: Vector3
var _last_foot_position: Vector3
var _last_knee_position: Vector3

@onready var _back_control_point = $"Back Control Point"
@onready var _foot_control_point = $"Foot Control Point"
@onready var _knee_control_point = $"Knee Control Point"
@onready var _sitting_player_ghost = $_SittingPlayerGhost


func setup_visual_editor(target_space_object: SpaceObject, extra_node_dict: Dictionary) -> void:
	super(target_space_object, extra_node_dict)
	var extensions: Dictionary = extra_node_dict["extensions"]
	_target_seat_dict = extensions["OMI_seat"]
	# Set up the control points.
	_last_back_position = Serialization.array_to_vector3(_target_seat_dict["back"])
	_last_foot_position = Serialization.array_to_vector3(_target_seat_dict["foot"])
	_last_knee_position = Serialization.array_to_vector3(_target_seat_dict["knee"])
	_back_control_point.position = _last_back_position
	_foot_control_point.position = _last_foot_position
	_knee_control_point.position = _last_knee_position
	_update_sitting_ghost()


func process_editor_updates() -> bool:
	var changed: bool = super()
	if not _last_back_position.is_equal_approx(_back_control_point.position):
		_last_back_position = _back_control_point.position
		changed = true
	if not _last_foot_position.is_equal_approx(_foot_control_point.position):
		_last_foot_position = _foot_control_point.position
		changed = true
	if not _last_knee_position.is_equal_approx(_knee_control_point.position):
		_last_knee_position = _knee_control_point.position
		changed = true
	if changed:
		_update_sitting_ghost()
	_draw_lines()
	return changed


func _update_sitting_ghost() -> void:
	_sitting_player_ghost.fit_onto_seat_points({
		"back": _last_back_position,
		"foot": _last_foot_position,
		"knee": _last_knee_position,
	})


func _draw_lines() -> void:
	var lines: Array = [
		_last_back_position,
		_last_knee_position,
		_last_knee_position,
		_last_foot_position,
	]
	var mi: MeshInstance3D = GameUI.object_outlines.draw_lines(lines, Color.SADDLE_BROWN)
	mi.transform = global_transform


func _write_values_to_target() -> void:
	super()
	_target_seat_dict["back"] = Serialization.vector3_to_array(_last_back_position)
	_target_seat_dict["foot"] = Serialization.vector3_to_array(_last_foot_position)
	_target_seat_dict["knee"] = Serialization.vector3_to_array(_last_knee_position)
