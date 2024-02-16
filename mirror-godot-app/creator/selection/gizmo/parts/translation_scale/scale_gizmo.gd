extends BaseGizmoPart


const MIN_SCALE = 0.1

var position_dragged_from := Vector3.ZERO
var snap_ratio: float = 0.1


func start_transform(gizmo_piece: BaseGizmoPart.GizmoPiece) -> void:
	# First, ensure everything is valid.
	if current_gizmo_piece != GizmoPiece.NONE:
		return
	if not PlayerData.has_local_player():
		return
	var target = get_target()
	if not is_instance_valid(target):
		return
	# Keep a copy of the original transform and enable the gizmo.
	original_transform = target.global_transform
	original_scale = target.basis.get_scale()
	current_gizmo_piece = gizmo_piece
	_gizmo.is_transforming = true
	get_child(current_gizmo_piece).start_highlight()
	# Uniform scale is a special case, we can skip the rest.
	if current_gizmo_piece == GizmoPiece.XYZ_CENTER:
		transformation_started.emit()
		return
	# Set up the active plane and keep a copy of the original transform.
	var active_vector := Vector3.ZERO
	if _gizmo.is_relative:
		active_vector = original_transform.basis[current_gizmo_piece % 3]
	else:
		active_vector[current_gizmo_piece % 3] = 1
	active_plane = Plane(active_vector, original_transform.origin)
	# Determine the starting value so that we can later be offset from this.
	if current_gizmo_piece <= GizmoPiece.Z_PLANE:
		position_dragged_from = plane_intersection_from_mouse()
	elif current_gizmo_piece <= GizmoPiece.Z_ARROW:
		position_dragged_from = line_intersection_from_mouse(original_transform.origin, active_plane.normal)
	transformation_started.emit()


func process_active_transform() -> void:
	# Check that the gizmo's target object is valid.
	if not PlayerData.has_local_player():
		end_transform(self.name)
		return
	var target: Node3D = get_target()
	if not is_instance_valid(target):
		return
	var scale_delta := Vector3.ONE
	# Uniform scale is a special case.
	if current_gizmo_piece == GizmoPiece.XYZ_CENTER:
		var vp = PlayerData.get_local_player().camera_get_viewport()
		var y_ratio = vp.get_mouse_position().y / vp.get_visible_rect().size.y
		scale_delta *= exp(-4 * (y_ratio - 0.5))
	else:
		# Find the position the user has their mouse over.
		var position_dragged_to = Vector3.ZERO # : Vector3?
		if current_gizmo_piece <= GizmoPiece.Z_PLANE:
			position_dragged_to = plane_intersection_from_mouse()
		elif current_gizmo_piece <= GizmoPiece.Z_ARROW:
			position_dragged_to = line_intersection_from_mouse(original_transform.origin, active_plane.normal)
		if position_dragged_to == null:
			return
		# We don't want to even try to use positions that are behind the camera.
		var viewport = PlayerData.get_local_player().camera_get_viewport()
		if viewport.get_camera_3d().is_position_behind(position_dragged_to):
			return
		if _gizmo.is_relative:
			position_dragged_to = position_dragged_to * original_transform
			scale_delta = position_dragged_to / (position_dragged_from * original_transform)
		else:
			position_dragged_to -= axis_center()
			scale_delta = position_dragged_to / (position_dragged_from - axis_center())
		for i in range(3):
			# This effectively stops scaling on that axis.
			if abs(position_dragged_to[i]) < MIN_SCALE:
				scale_delta[i] = 1
	# If snapping is enabled, snap.
	if _gizmo.is_snap_enabled():
		scale_delta = scale_delta.snapped(snap_ratio * Vector3.ONE)
		for i in range(3):
			# This prevents snapping to zero.
			if abs(scale_delta[i]) < snap_ratio:
				scale_delta[i] = snap_ratio
	target.process_active_scaling(scale_delta, _gizmo.is_relative)


func show_gizmo():
	for i in range(GizmoPiece.XYZ_CENTER + 1):
		get_child(i).show_gizmo()


func hide_gizmo():
	for i in range(GizmoPiece.XYZ_CENTER + 1):
		get_child(i).hide_gizmo()
