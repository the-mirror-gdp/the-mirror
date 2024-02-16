## Constrains a target bone or node, by reading a source a bone or node.
@tool
@icon("icons/bone_node_constraint.svg")
class_name BoneNodeConstraint
extends Resource


enum ConstraintType {
	NONE = 0,
	AIM = 1,
	ROLL = 2,
	ROTATION = 3,
}

enum AimRollAxis {
	NONE = 0,
	POSITIVE_X = 1,
	POSITIVE_Y = 2,
	POSITIVE_Z = 3,
	NEGATIVE_X = 4,
	NEGATIVE_Y = 5,
	NEGATIVE_Z = 6,
}

@export_group("Parameters")
@export var constraint_type: ConstraintType
@export var aim_or_roll_axis: AimRollAxis
@export var weight: float = 1.0

@export_group("Source")
@export var source_node_path: NodePath
@export var source_bone_index: int = -1
@export var source_rest_transform: Transform3D

@export_group("Target")
@export var target_node_path: NodePath
@export var target_bone_index: int = -1
@export var target_rest_transform: Transform3D

# Used during import/export and runtime, but can't be saved, instead a NodePath is saved.
var source_node: Node3D
var target_node: Node3D
# Used during the import/export process, but not exposed or saved.
var source_node_index: int = -1


func set_node_references_from_paths(applier: Node) -> void:
	source_node = applier.get_node(source_node_path)
	target_node = applier.get_node(target_node_path)


func set_node_paths_from_references(applier: Node) -> void:
	source_node_path = applier.get_path_to(source_node)
	target_node_path = applier.get_path_to(target_node)


func evaluate() -> void:
	if constraint_type == ConstraintType.AIM:
		evaluate_aim()
	elif constraint_type == ConstraintType.ROLL:
		evaluate_roll()
	elif constraint_type == ConstraintType.ROTATION:
		evaluate_rotation()


func evaluate_aim() -> void:
	if source_node == null or target_node == null:
		return
	var source_global_transform: Transform3D = _get_source_global_transform()
	var target_global_transform: Transform3D = _get_target_global_transform()
	var target_rest_transform: Transform3D = _get_target_global_rest()
	var rest_dir: Vector3 = _aim_get_rest_direction(target_rest_transform.basis)
	var aim_dir: Vector3 = target_global_transform.origin.direction_to(source_global_transform.origin)
	if rest_dir.is_zero_approx() or aim_dir.is_zero_approx():
		return
	var arc := Quaternion(rest_dir, aim_dir)
	_set_weighted_global_target_rotation(arc)


func evaluate_roll() -> void:
	if source_node == null or target_node == null:
		return
	if aim_or_roll_axis < AimRollAxis.POSITIVE_X or aim_or_roll_axis > AimRollAxis.POSITIVE_Z:
		printerr("BoneNodeConstraint: Roll axis not set! Must be positive X, Y, or Z.")
		return
	# Gather axis-angle information from the source rotation.
	var source_transform: Transform3D = _get_posed_source_transform()
	var source_quat: Quaternion = source_transform.basis.get_rotation_quaternion()
	var source_axis: Vector3 = source_quat.get_axis()
	var source_angle: float = source_quat.get_angle()
	# Calculate what we need to apply to the target.
	var axis_index: int = aim_or_roll_axis - 1 # Vector3.Axis
	var axis_value: float = source_axis[axis_index]
	var rotation_quat := Quaternion.IDENTITY
	if not is_zero_approx(axis_value):
		var target_axis := Vector3.ZERO
		target_axis[axis_index] = 1.0
		rotation_quat = Quaternion(target_axis, source_angle * axis_value)
	_set_weighted_posed_target_rotation(rotation_quat)


func evaluate_rotation() -> void:
	if source_node == null or target_node == null:
		return
	var source_transform: Transform3D = _get_posed_source_transform()
	var source_quat: Quaternion = source_transform.basis.get_rotation_quaternion()
	_set_weighted_posed_target_rotation(source_quat)


static func from_dictionary(dict: Dictionary) -> BoneNodeConstraint:
	var ret := BoneNodeConstraint.new()
	if not dict.has("constraint"):
		return ret
	var constraint_dict: Dictionary = dict["constraint"]
	if constraint_dict.is_empty():
		return ret
	# Set up the constraint type.
	var constraint_type_string: String = constraint_dict.keys()[0]
	if constraint_type_string == "aim":
		ret.constraint_type = ConstraintType.AIM
	elif constraint_type_string == "roll":
		ret.constraint_type = ConstraintType.ROLL
	elif constraint_type_string == "rotation":
		ret.constraint_type = ConstraintType.ROTATION
	else:
		printerr("BoneNodeConstraint: Unknown constraint type: " + constraint_type_string)
	# Set up weight and source node index.
	var constraint_parameters: Dictionary = constraint_dict[constraint_type_string]
	ret.weight = constraint_dict.get("weight", 1.0)
	ret.source_node_index = constraint_parameters["source"]
	assert(ret.source_node_index >= 0)
	# Set up the aim or roll axis.
	if ret.constraint_type == ConstraintType.AIM:
		var aim_axis: String = constraint_parameters.get("aimAxis", "")
		ret.aim_or_roll_axis = _from_dictionary_get_aim_axis_from_string(aim_axis)
	elif ret.constraint_type == ConstraintType.ROLL:
		var roll_axis: String = constraint_parameters.get("rollAxis", "")
		ret.aim_or_roll_axis = _from_dictionary_get_roll_axis_from_string(roll_axis)
	return ret


func to_dictionary() -> Dictionary:
	var type_key: String = ""
	if constraint_type == ConstraintType.AIM:
		type_key = "aim"
	elif constraint_type == ConstraintType.ROLL:
		type_key = "roll"
	elif constraint_type == ConstraintType.ROTATION:
		type_key = "rotation"
	var parameters: Dictionary = {
		"source": source_node_index
	}
	if constraint_type == ConstraintType.AIM:
		parameters["aimAxis"] = _to_dictionary_get_string_from_aim_axis()
	elif constraint_type == ConstraintType.ROLL:
		parameters["rollAxis"] = _to_dictionary_get_string_from_roll_axis()
	if weight != 1.0:
		parameters["weight"] = weight
	var constraint: Dictionary = {}
	constraint[type_key] = parameters
	return {
		"specVersion": "1.0",
		"constraint": constraint,
	}


func _get_posed_source_transform() -> Transform3D:
	if source_bone_index == -1:
		return source_rest_transform.affine_inverse() * source_node.transform
	var skeleton: Skeleton3D = source_node as Skeleton3D
	var rest_inverse: Transform3D = skeleton.get_bone_rest(source_bone_index).affine_inverse()
	return rest_inverse * skeleton.get_bone_pose(source_bone_index)


func _get_source_global_transform() -> Transform3D:
	if source_bone_index == -1:
		return source_node.global_transform
	var skeleton: Skeleton3D = source_node as Skeleton3D
	return skeleton.get_bone_global_pose(source_bone_index)


func _get_target_global_transform() -> Transform3D:
	if target_bone_index == -1:
		return target_node.global_transform
	var skeleton: Skeleton3D = target_node as Skeleton3D
	return skeleton.get_bone_global_pose(target_bone_index)


func _get_target_global_rest() -> Transform3D:
	if target_bone_index == -1:
		var parent_global: Transform3D = target_node.get_parent().global_transform
		return parent_global * target_rest_transform
	var skeleton: Skeleton3D = target_node as Skeleton3D
	return skeleton.get_bone_global_rest(source_bone_index)


func _set_weighted_posed_target_rotation(rotation_quat: Quaternion) -> void:
	if weight != 1.0:
		rotation_quat = Quaternion.IDENTITY.slerp(rotation_quat, weight)
	if target_bone_index == -1:
		var rest_quat: Quaternion = target_rest_transform.basis.get_rotation_quaternion()
		target_node.quaternion = rest_quat * rotation_quat
		return
	var skeleton: Skeleton3D = target_node as Skeleton3D
	var rest_quat: Quaternion = target_rest_transform.basis.get_rotation_quaternion()
	skeleton.set_bone_pose_rotation(target_bone_index, rest_quat * rotation_quat)


func _set_weighted_global_target_rotation(rotation_quat: Quaternion) -> void:
	if weight != 1.0:
		rotation_quat = Quaternion.IDENTITY.slerp(rotation_quat, weight)
	if target_bone_index == -1:
		var target_global_transform: Transform3D = target_node.global_transform
		var scale_basis: Basis = Basis.from_scale(target_global_transform.basis.get_scale())
		target_global_transform.basis = Basis(rotation_quat) * scale_basis
		target_node.global_transform = target_global_transform
		return
	var skeleton: Skeleton3D = target_node as Skeleton3D
	rotation_quat = Quaternion(_get_target_global_rest().basis).inverse() * rotation_quat
	skeleton.set_bone_pose_rotation(target_bone_index, rotation_quat)


func _aim_get_rest_direction(rest_basis: Basis) -> Vector3:
	match aim_or_roll_axis:
		AimRollAxis.POSITIVE_X:
			return rest_basis.x
		AimRollAxis.POSITIVE_Y:
			return rest_basis.y
		AimRollAxis.POSITIVE_Z:
			return rest_basis.z
		AimRollAxis.NEGATIVE_X:
			return -rest_basis.x
		AimRollAxis.NEGATIVE_Y:
			return -rest_basis.y
		AimRollAxis.NEGATIVE_Z:
			return -rest_basis.z
	printerr("BoneNodeConstraint: Aim axis not set! Must be a valid value.")
	return Vector3.ZERO


static func _from_dictionary_get_aim_axis_from_string(aim_axis: String) -> AimRollAxis:
	match aim_axis:
		"PositiveX":
			return AimRollAxis.POSITIVE_X
		"PositiveY":
			return AimRollAxis.POSITIVE_Y
		"PositiveZ":
			return AimRollAxis.POSITIVE_Z
		"NegativeX":
			return AimRollAxis.NEGATIVE_X
		"NegativeY":
			return AimRollAxis.NEGATIVE_Y
		"NegativeZ":
			return AimRollAxis.NEGATIVE_Z
	printerr("BoneNodeConstraint: Unknown aim axis: " + aim_axis)
	return AimRollAxis.NONE


static func _from_dictionary_get_roll_axis_from_string(roll_axis: String) -> AimRollAxis:
	match roll_axis:
		"X":
			return AimRollAxis.POSITIVE_X
		"Y":
			return AimRollAxis.POSITIVE_Y
		"Z":
			return AimRollAxis.POSITIVE_Z
	printerr("BoneNodeConstraint: Unknown roll axis: " + roll_axis)
	return AimRollAxis.NONE


func _to_dictionary_get_string_from_aim_axis() -> String:
	match aim_or_roll_axis:
		AimRollAxis.POSITIVE_X:
			return "PositiveX"
		AimRollAxis.POSITIVE_Y:
			return "PositiveY"
		AimRollAxis.POSITIVE_Z:
			return "PositiveZ"
		AimRollAxis.NEGATIVE_X:
			return "NegativeX"
		AimRollAxis.NEGATIVE_Y:
			return "NegativeY"
		AimRollAxis.NEGATIVE_Z:
			return "NegativeZ"
	printerr("BoneNodeConstraint: Invalid aim axis: " + str(aim_or_roll_axis))
	return ""


func _to_dictionary_get_string_from_roll_axis() -> String:
	match aim_or_roll_axis:
		AimRollAxis.POSITIVE_X:
			return "X"
		AimRollAxis.POSITIVE_Y:
			return "Y"
		AimRollAxis.POSITIVE_Z:
			return "Z"
	printerr("BoneNodeConstraint: Invalid roll axis: " + str(aim_or_roll_axis))
	return ""
