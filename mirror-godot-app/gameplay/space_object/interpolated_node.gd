extends Node3D


var initial_transform: Transform3D = Transform3D.IDENTITY
var target_transform: Transform3D = Transform3D.IDENTITY
var accumulated_delta: float = 0.0
var movement_delta: float = 0.0


func _ready():
	set_as_top_level(true)


func update_space_object_transform(in_movement_delta: float, trsf: Transform3D):
	initial_transform = global_transform
	target_transform = trsf
	accumulated_delta = 0.0
	movement_delta = in_movement_delta

	if movement_delta <= 0.0001:
		# This is a teleport
		global_transform = target_transform
		initial_transform = target_transform


func _process_interpolate(delta: float):
	if not get_parent().is_dynamic():
		set_as_top_level(false)
		transform = Transform3D.IDENTITY
		return
	else:
		set_as_top_level(true)

	if movement_delta <= 0.0001:
		# It was teleported, nothing to do.
		return

	accumulated_delta += delta
	var alpha: float = accumulated_delta / movement_delta
	if alpha >= 1.0:
		alpha = 1.0
		# Stop processing
		movement_delta = 0.0

	# Smoothly update the transform
	global_transform = initial_transform.interpolate_with(target_transform, alpha)
