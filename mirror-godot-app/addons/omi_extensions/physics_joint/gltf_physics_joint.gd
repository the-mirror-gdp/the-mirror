@tool
class_name GLTFPhysicsJoint
extends Resource


var node_a: PhysicsBody3D
var node_b: PhysicsBody3D

var linear_x: GLTFPhysicsJointConstraint = null
var linear_y: GLTFPhysicsJointConstraint = null
var linear_z: GLTFPhysicsJointConstraint = null
var angular_x: GLTFPhysicsJointConstraint = null
var angular_y: GLTFPhysicsJointConstraint = null
var angular_z: GLTFPhysicsJointConstraint = null


static func from_node(joint_node: Joint3D) -> GLTFPhysicsJoint:
	var ret := GLTFPhysicsJoint.new()
	if not joint_node.node_a.is_empty():
		ret.node_a = joint_node.get_node(joint_node.node_a)
	if not joint_node.node_b.is_empty():
		ret.node_b = joint_node.get_node(joint_node.node_b)
	# We need different code for each type of Godot joint we want to convert.
	if joint_node is Generic6DOFJoint3D:
		_convert_generic_joint_constraints(joint_node, ret)
	elif joint_node is HingeJoint3D:
		var linear_constraint := GLTFPhysicsJointConstraint.new()
		linear_constraint.linear_axes = [0, 1, 2]
		linear_constraint.stiffness = joint_node.get_param(HingeJoint3D.PARAM_BIAS)
		ret.linear_x = linear_constraint
		ret.linear_y = linear_constraint
		ret.linear_z = linear_constraint
		var fixed_angular_constraint := GLTFPhysicsJointConstraint.new()
		fixed_angular_constraint.angular_axes = [0, 1]
		fixed_angular_constraint.stiffness = joint_node.get_param(HingeJoint3D.PARAM_LIMIT_BIAS)
		fixed_angular_constraint.damping = 1.0 / joint_node.get_param(HingeJoint3D.PARAM_LIMIT_RELAXATION)
		ret.angular_x = fixed_angular_constraint
		ret.angular_y = fixed_angular_constraint
		# Godot's Hinge joint rotates around the local Z axis (in the XY plane).
		if joint_node.get_flag(HingeJoint3D.FLAG_USE_LIMIT):
			var loose_angular_constraint := GLTFPhysicsJointConstraint.new()
			loose_angular_constraint.angular_axes = [2]
			loose_angular_constraint.lower_limit = joint_node.get_param(HingeJoint3D.PARAM_LIMIT_LOWER)
			loose_angular_constraint.upper_limit = joint_node.get_param(HingeJoint3D.PARAM_LIMIT_UPPER)
			loose_angular_constraint.stiffness = joint_node.get_param(HingeJoint3D.PARAM_LIMIT_SOFTNESS)
			loose_angular_constraint.damping = 1.0 / joint_node.get_param(HingeJoint3D.PARAM_LIMIT_RELAXATION)
			ret.angular_z = loose_angular_constraint
	elif joint_node is PinJoint3D:
		var constraint := GLTFPhysicsJointConstraint.new()
		constraint.linear_axes = [0, 1, 2]
		constraint.stiffness = joint_node.get_param(PinJoint3D.PARAM_BIAS)
		constraint.damping = joint_node.get_param(PinJoint3D.PARAM_DAMPING)
		ret.linear_x = constraint
		ret.linear_y = constraint
		ret.linear_z = constraint
	elif joint_node is SliderJoint3D:
		# Godot's Slider joint slides on the local X axis.
		var loose_linear_constraint := GLTFPhysicsJointConstraint.new()
		loose_linear_constraint.linear_axes = [0]
		loose_linear_constraint.lower_limit = joint_node.get_param(SliderJoint3D.PARAM_LINEAR_LIMIT_LOWER)
		loose_linear_constraint.upper_limit = joint_node.get_param(SliderJoint3D.PARAM_LINEAR_LIMIT_UPPER)
		loose_linear_constraint.stiffness = joint_node.get_param(SliderJoint3D.PARAM_LINEAR_LIMIT_SOFTNESS)
		loose_linear_constraint.damping = joint_node.get_param(SliderJoint3D.PARAM_LINEAR_LIMIT_DAMPING)
		if loose_linear_constraint.lower_limit <= loose_linear_constraint.upper_limit:
			# In Godot's Slider joint, the lower limit being higher than the upper limit means unconstrained.
			ret.linear_x = loose_linear_constraint
		var fixed_linear_constraint := GLTFPhysicsJointConstraint.new()
		fixed_linear_constraint.linear_axes = [1, 2]
		fixed_linear_constraint.stiffness = joint_node.get_param(SliderJoint3D.PARAM_LINEAR_ORTHOGONAL_SOFTNESS)
		fixed_linear_constraint.damping = joint_node.get_param(SliderJoint3D.PARAM_LINEAR_ORTHOGONAL_DAMPING)
		ret.linear_y = fixed_linear_constraint
		ret.linear_z = fixed_linear_constraint
		# Godot's Slider joint rotates around the local X axis (in the YZ plane).
		var loose_angular_constraint := GLTFPhysicsJointConstraint.new()
		loose_angular_constraint.angular_axes = [0]
		loose_angular_constraint.lower_limit = joint_node.get_param(SliderJoint3D.PARAM_ANGULAR_LIMIT_LOWER)
		loose_angular_constraint.upper_limit = joint_node.get_param(SliderJoint3D.PARAM_ANGULAR_LIMIT_UPPER)
		loose_angular_constraint.stiffness = joint_node.get_param(SliderJoint3D.PARAM_ANGULAR_LIMIT_SOFTNESS)
		loose_angular_constraint.damping = joint_node.get_param(SliderJoint3D.PARAM_ANGULAR_LIMIT_DAMPING)
		if loose_angular_constraint.lower_limit <= loose_angular_constraint.upper_limit:
			# In Godot's Slider joint, the lower limit being higher than the upper limit means unconstrained.
			ret.angular_x = loose_angular_constraint
		var fixed_angular_constraint := GLTFPhysicsJointConstraint.new()
		fixed_angular_constraint.angular_axes = [1, 2]
		fixed_angular_constraint.stiffness = joint_node.get_param(SliderJoint3D.PARAM_ANGULAR_ORTHOGONAL_SOFTNESS)
		fixed_angular_constraint.damping = joint_node.get_param(SliderJoint3D.PARAM_ANGULAR_ORTHOGONAL_DAMPING)
		ret.angular_y = fixed_angular_constraint
		ret.angular_z = fixed_angular_constraint
	elif joint_node is ConeTwistJoint3D:
		# It doesn't seem possible to fully represent ConeTwistJoint3D, so use an approximation.
		push_warning("GLTF Physics Joint: Converting a ConeTwistJoint3D which cannot be properly represented as a GLTF joint, so it will only be approximated.")
		var linear_constraint := GLTFPhysicsJointConstraint.new()
		linear_constraint.linear_axes = [0, 1, 2]
		ret.linear_x = linear_constraint
		ret.linear_y = linear_constraint
		ret.linear_z = linear_constraint
		var angular_constraint := GLTFPhysicsJointConstraint.new()
		angular_constraint.angular_axes = [0, 1, 2]
		angular_constraint.lower_limit = -joint_node.get_param(ConeTwistJoint3D.PARAM_SWING_SPAN)
		angular_constraint.upper_limit = joint_node.get_param(ConeTwistJoint3D.PARAM_SWING_SPAN)
		angular_constraint.stiffness = joint_node.get_param(ConeTwistJoint3D.PARAM_SOFTNESS)
		angular_constraint.damping = 1.0 / joint_node.get_param(ConeTwistJoint3D.PARAM_RELAXATION)
		ret.angular_x = angular_constraint
		ret.angular_y = angular_constraint
		ret.angular_z = angular_constraint
	else:
		printerr("GLTF Physics Joint: Unable to convert '" + str(joint_node) + "'. Returning a default pin joint as fallback.")
		var constraint := GLTFPhysicsJointConstraint.new()
		constraint.linear_axes = [0, 1, 2]
		ret.linear_x = constraint
		ret.linear_y = constraint
		ret.linear_z = constraint
	return ret


func to_node() -> Joint3D:
	if linear_x != null and linear_x.is_fixed_at_zero() \
			and linear_y != null and linear_y.is_fixed_at_zero() \
			and linear_z != null and linear_z.is_fixed_at_zero():
		# Linearly fixed at zero, so it could be a pin or hinge.
		if angular_x == null and angular_y == null and angular_z == null:
			# No angular constraint, so this is a pin joint.
			var pin = PinJoint3D.new()
			# Calculate values that will not cause Godot's physics engine to explode.
			var bias = (linear_x.stiffness + linear_y.stiffness + linear_z.stiffness) / 6.0
			pin.set_param(PinJoint3D.PARAM_BIAS, clamp(bias, 0.01, 0.99))
			var damping: float = (linear_x.damping + linear_y.damping + linear_z.damping) / 3.0
			pin.set_param(PinJoint3D.PARAM_BIAS, clamp(damping, bias * 0.51, 2.0))
			return pin
		if angular_x != null and angular_x.is_fixed_at_zero() \
				and angular_y != null and angular_y.is_fixed_at_zero() \
				and angular_x.limits_equal_to(angular_y) \
				and (angular_z == null or not angular_z.is_fixed_at_zero()):
			# Angular X and Y are equally fixed at zero, Z is not, so this is a hinge joint.
			var hinge = HingeJoint3D.new()
			if angular_z != null:
				hinge.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
				hinge.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, angular_z.lower_limit)
				hinge.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, angular_z.upper_limit)
				hinge.set_param(HingeJoint3D.PARAM_LIMIT_SOFTNESS, angular_z.stiffness)
				hinge.set_param(HingeJoint3D.PARAM_LIMIT_RELAXATION, 1.0 / angular_z.damping)
			return hinge
	if linear_y != null and linear_y.is_fixed_at_zero() \
			and linear_z != null and linear_z.is_fixed_at_zero() \
			and linear_y.limits_equal_to(linear_z) \
			and angular_y != null and angular_y.is_fixed_at_zero() \
			and angular_z != null and angular_z.is_fixed_at_zero() \
			and angular_y.limits_equal_to(angular_z) \
			and (angular_x == null or not angular_x.is_fixed_at_zero() \
				or linear_x == null or not linear_x.is_fixed_at_zero()):
		# The only free axes are the linear and/or angular X, so this looks like a Slider.
		var slider = SliderJoint3D.new()
		if linear_x == null:
			# In Godot's Slider joint, the lower limit being higher than the upper limit means unconstrained.
			slider.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_LOWER, 1.0)
			slider.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_UPPER, -1.0)
		else:
			slider.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_LOWER, linear_x.lower_limit)
			slider.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_UPPER, linear_x.upper_limit)
			slider.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_SOFTNESS, linear_x.stiffness)
			slider.set_param(SliderJoint3D.PARAM_LINEAR_LIMIT_DAMPING, linear_x.damping)
		slider.set_param(SliderJoint3D.PARAM_LINEAR_ORTHOGONAL_SOFTNESS, linear_y.stiffness)
		slider.set_param(SliderJoint3D.PARAM_LINEAR_ORTHOGONAL_DAMPING, linear_y.damping)
		if angular_x == null:
			# In Godot's Slider joint, the lower limit being higher than the upper limit means unconstrained.
			slider.set_param(SliderJoint3D.PARAM_ANGULAR_LIMIT_LOWER, 1.0)
			slider.set_param(SliderJoint3D.PARAM_ANGULAR_LIMIT_UPPER, -1.0)
		else:
			slider.set_param(SliderJoint3D.PARAM_ANGULAR_LIMIT_LOWER, angular_x.lower_limit)
			slider.set_param(SliderJoint3D.PARAM_ANGULAR_LIMIT_UPPER, angular_x.upper_limit)
			slider.set_param(SliderJoint3D.PARAM_ANGULAR_LIMIT_SOFTNESS, angular_x.stiffness)
			slider.set_param(SliderJoint3D.PARAM_ANGULAR_LIMIT_DAMPING, angular_x.damping)
		slider.set_param(SliderJoint3D.PARAM_ANGULAR_ORTHOGONAL_SOFTNESS, angular_y.stiffness)
		slider.set_param(SliderJoint3D.PARAM_ANGULAR_ORTHOGONAL_DAMPING, angular_y.damping)
		return slider
	# If none of the special-purpose joints apply, use the generic one.
	return _create_generic_joint_with_constraints()


func get_constraints() -> Array:
	var ret: Array = []
	if linear_x != null:
		ret.append(linear_x)
	if linear_y != null and not linear_y in ret:
		ret.append(linear_y)
	if linear_z != null and not linear_z in ret:
		ret.append(linear_z)
	if angular_x != null and not angular_x in ret:
		ret.append(angular_x)
	if angular_y != null and not angular_y in ret:
		ret.append(angular_y)
	if angular_z != null and not angular_z in ret:
		ret.append(angular_z)
	return ret


func apply_constraint(joint_constraint: GLTFPhysicsJointConstraint) -> void:
	for linear_axis in joint_constraint.linear_axes:
		match linear_axis:
			0:
				linear_x = joint_constraint
			1:
				linear_y = joint_constraint
			2:
				linear_z = joint_constraint
	for angular_axis in joint_constraint.angular_axes:
		match angular_axis:
			0:
				angular_x = joint_constraint
			1:
				angular_y = joint_constraint
			2:
				angular_z = joint_constraint


func _create_generic_joint_with_constraints() -> Generic6DOFJoint3D:
	var ret := Generic6DOFJoint3D.new()
	if linear_x == null:
		ret.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, false)
	else:
		ret.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, linear_x.lower_limit)
		ret.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, linear_x.upper_limit)
		# Calculate values that will not cause Godot's physics engine to explode.
		var stiffness: float = clampf(linear_x.stiffness, 0.01, 2.0)
		var minimum_damping: float = 0.01
		if stiffness > 0.5:
			minimum_damping = 0.25 * sqrt(stiffness - 0.498)
		ret.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_LIMIT_SOFTNESS, stiffness)
		ret.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_DAMPING, clampf(linear_x.damping, minimum_damping, 16.0))
	if linear_y == null:
		ret.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, false)
	else:
		ret.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, linear_y.lower_limit)
		ret.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, linear_y.upper_limit)
		var stiffness: float = clampf(linear_y.stiffness, 0.01, 2.0)
		var minimum_damping: float = 0.01
		if stiffness > 0.5:
			minimum_damping = 0.25 * sqrt(stiffness - 0.498)
		ret.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LIMIT_SOFTNESS, stiffness)
		ret.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_DAMPING, clampf(linear_y.damping, minimum_damping, 16.0))
	if linear_z == null:
		ret.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, false)
	else:
		ret.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT, linear_z.lower_limit)
		ret.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT, linear_z.upper_limit)
		var stiffness: float = clampf(linear_z.stiffness, 0.01, 2.0)
		var minimum_damping: float = 0.01
		if stiffness > 0.5:
			minimum_damping = 0.25 * sqrt(stiffness - 0.498)
		ret.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_LIMIT_SOFTNESS, stiffness)
		ret.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_DAMPING, clampf(linear_z.damping, minimum_damping, 16.0))
	if angular_x == null:
		ret.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, false)
	else:
		ret.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, angular_x.lower_limit)
		ret.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, angular_x.upper_limit)
		var stiffness: float = clampf(angular_x.stiffness, 0.01, 2.0)
		var minimum_damping: float = 0.01
		if stiffness > 0.5:
			minimum_damping = 0.25 * sqrt(stiffness - 0.498)
		ret.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_LIMIT_SOFTNESS, stiffness)
		ret.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_DAMPING, clampf(angular_x.damping, minimum_damping, 16.0))
	if angular_y == null:
		ret.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, false)
	else:
		ret.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, angular_y.lower_limit)
		ret.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, angular_y.upper_limit)
		var stiffness: float = clampf(angular_y.stiffness, 0.01, 2.0)
		var minimum_damping: float = 0.01
		if stiffness > 0.5:
			minimum_damping = 0.25 * sqrt(stiffness - 0.498)
		ret.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_LIMIT_SOFTNESS, stiffness)
		ret.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_DAMPING, clampf(angular_y.damping, minimum_damping, 16.0))
	if angular_z == null:
		ret.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, false)
	else:
		ret.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT, angular_z.lower_limit)
		ret.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT, angular_z.upper_limit)
		var stiffness: float = clampf(angular_z.stiffness, 0.01, 2.0)
		var minimum_damping: float = 0.01
		if stiffness > 0.5:
			minimum_damping = 0.25 * sqrt(stiffness - 0.498)
		ret.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_LIMIT_SOFTNESS, stiffness)
		ret.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_DAMPING, clampf(angular_z.damping, minimum_damping, 16.0))
	return ret


static func _convert_generic_joint_constraints(joint_node: Generic6DOFJoint3D, gltf_joint: GLTFPhysicsJoint) -> void:
	if joint_node.get_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT):
		var constraint := GLTFPhysicsJointConstraint.new()
		constraint.lower_limit = joint_node.get_param_x(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT)
		constraint.upper_limit = joint_node.get_param_x(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT)
		constraint.stiffness = joint_node.get_param_x(Generic6DOFJoint3D.PARAM_LINEAR_LIMIT_SOFTNESS)
		constraint.damping = joint_node.get_param_x(Generic6DOFJoint3D.PARAM_LINEAR_DAMPING)
		constraint.linear_axes = [0]
		gltf_joint.linear_x = constraint
	if joint_node.get_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT):
		var constraint := GLTFPhysicsJointConstraint.new()
		constraint.lower_limit = joint_node.get_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT)
		constraint.upper_limit = joint_node.get_param_y(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT)
		constraint.stiffness = joint_node.get_param_y(Generic6DOFJoint3D.PARAM_LINEAR_LIMIT_SOFTNESS)
		constraint.damping = joint_node.get_param_y(Generic6DOFJoint3D.PARAM_LINEAR_DAMPING)
		if gltf_joint.linear_x != null and constraint.limits_equal_to(gltf_joint.linear_x):
			gltf_joint.linear_x.linear_axes.append(1)
			gltf_joint.linear_y = gltf_joint.linear_x
		else:
			constraint.linear_axes = [1]
			gltf_joint.linear_y = constraint
	if joint_node.get_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT):
		var constraint := GLTFPhysicsJointConstraint.new()
		constraint.lower_limit = joint_node.get_param_z(Generic6DOFJoint3D.PARAM_LINEAR_LOWER_LIMIT)
		constraint.upper_limit = joint_node.get_param_z(Generic6DOFJoint3D.PARAM_LINEAR_UPPER_LIMIT)
		constraint.stiffness = joint_node.get_param_z(Generic6DOFJoint3D.PARAM_LINEAR_LIMIT_SOFTNESS)
		constraint.damping = joint_node.get_param_z(Generic6DOFJoint3D.PARAM_LINEAR_DAMPING)
		if gltf_joint.linear_x != null and constraint.limits_equal_to(gltf_joint.linear_x):
			gltf_joint.linear_x.linear_axes.append(2)
			gltf_joint.linear_z = gltf_joint.linear_x
		elif gltf_joint.linear_y != null and constraint.limits_equal_to(gltf_joint.linear_y):
			gltf_joint.linear_y.linear_axes.append(2)
			gltf_joint.linear_z = gltf_joint.linear_y
		else:
			constraint.linear_axes = [2]
			gltf_joint.linear_z = constraint
	if joint_node.get_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT):
		var constraint := GLTFPhysicsJointConstraint.new()
		constraint.lower_limit = joint_node.get_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT)
		constraint.upper_limit = joint_node.get_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT)
		constraint.stiffness = joint_node.get_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_LIMIT_SOFTNESS)
		constraint.damping = joint_node.get_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_DAMPING)
		constraint.angular_axes = [0]
		gltf_joint.angular_x = constraint
	if joint_node.get_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT):
		var constraint := GLTFPhysicsJointConstraint.new()
		constraint.lower_limit = joint_node.get_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT)
		constraint.upper_limit = joint_node.get_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT)
		constraint.stiffness = joint_node.get_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_LIMIT_SOFTNESS)
		constraint.damping = joint_node.get_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_DAMPING)
		if gltf_joint.angular_x != null and constraint.limits_equal_to(gltf_joint.angular_x):
			gltf_joint.angular_x.angular_axes.append(1)
			gltf_joint.angular_y = gltf_joint.angular_x
		else:
			constraint.angular_axes = [1]
			gltf_joint.angular_y = constraint
	if joint_node.get_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT):
		var constraint := GLTFPhysicsJointConstraint.new()
		constraint.lower_limit = joint_node.get_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_LOWER_LIMIT)
		constraint.upper_limit = joint_node.get_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_UPPER_LIMIT)
		constraint.stiffness = joint_node.get_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_LIMIT_SOFTNESS)
		constraint.damping = joint_node.get_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_DAMPING)
		if gltf_joint.angular_x != null and constraint.limits_equal_to(gltf_joint.angular_x):
			gltf_joint.angular_x.angular_axes.append(2)
			gltf_joint.angular_z = gltf_joint.angular_x
		elif gltf_joint.angular_y != null and constraint.limits_equal_to(gltf_joint.angular_y):
			gltf_joint.angular_y.angular_axes.append(2)
			gltf_joint.angular_z = gltf_joint.angular_y
		else:
			constraint.angular_axes = [2]
			gltf_joint.angular_z = constraint
