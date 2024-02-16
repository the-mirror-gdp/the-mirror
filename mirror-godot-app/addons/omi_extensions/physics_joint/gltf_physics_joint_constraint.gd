@tool
class_name GLTFPhysicsJointConstraint
extends Resource


var linear_axes: Array = []
var angular_axes: Array = []
var lower_limit: float = 0.0
var upper_limit: float = 0.0
var stiffness: float = INF
var damping: float = 1.0


func to_dictionary() -> Dictionary:
	var ret: Dictionary = {}
	if not linear_axes.is_empty():
		ret["linearAxes"] = linear_axes
	if not angular_axes.is_empty():
		ret["angularAxes"] = angular_axes
	if lower_limit != 0.0:
		ret["lowerLimit"] = lower_limit
	if upper_limit != 0.0:
		ret["upperLimit"] = upper_limit
	if stiffness != INF:
		ret["stiffness"] = stiffness
	if damping != 1.0:
		ret["damping"] = damping
	return ret


static func from_dictionary(joint_dict: Dictionary) -> GLTFPhysicsJointConstraint:
	var ret = GLTFPhysicsJointConstraint.new()
	if joint_dict.has("linearAxes"):
		var dict_axes: Array = joint_dict["linearAxes"]
		for dict_axis in dict_axes:
			ret.linear_axes.append(int(dict_axis))
	if joint_dict.has("angularAxes"):
		var dict_axes: Array = joint_dict["angularAxes"]
		for dict_axis in dict_axes:
			ret.angular_axes.append(int(dict_axis))
	if joint_dict.has("lowerLimit"):
		ret.lower_limit = joint_dict["lowerLimit"]
	if joint_dict.has("upperLimit"):
		ret.upper_limit = joint_dict["upperLimit"]
	if joint_dict.has("stiffness"):
		ret.stiffness = joint_dict["stiffness"]
	if joint_dict.has("damping"):
		ret.damping = joint_dict["damping"]
	return ret


func is_fixed_at_zero() -> bool:
	return is_zero_approx(lower_limit) and is_zero_approx(upper_limit)


func is_equal_to(other: GLTFPhysicsJointConstraint) -> bool:
	return limits_equal_to(other) \
			and linear_axes.hash() == other.linear_axes.hash() \
			and angular_axes.hash() == other.angular_axes.hash()


func limits_equal_to(other: GLTFPhysicsJointConstraint) -> bool:
	return is_equal_approx(lower_limit, other.lower_limit) \
			and is_equal_approx(upper_limit, other.upper_limit) \
			and is_equal_approx(stiffness, other.stiffness) \
			and is_equal_approx(damping, other.damping)
