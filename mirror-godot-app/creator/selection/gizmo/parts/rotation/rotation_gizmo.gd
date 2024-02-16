extends BaseGizmoPart


var angle_dragged_from: float = 0.0
var snap_radians: float = deg_to_rad(15)


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
	current_gizmo_piece = gizmo_piece
	_gizmo.is_transforming = true
	get_child(current_gizmo_piece).start_highlight()
	# Set up the active plane and keep a copy of the original transform.
	var active_vector := Vector3()
	if _gizmo.is_relative:
		active_vector = original_transform.basis[current_gizmo_piece % 3].normalized()
	else:
		active_vector[current_gizmo_piece % 3] = 1
	active_plane = Plane(active_vector, original_transform.origin)
	# Determine the starting value so that we can later be offset from this.
	var intersection = plane_intersection_from_mouse()
	angle_dragged_from = _point_to_ring_angle(intersection)
	transformation_started.emit()


func process_active_transform() -> void:
	# Check that the gizmo's target object is valid.
	if not PlayerData.has_local_player():
		end_transform(self.name)
		return
	var target: Node3D = get_target()
	if not target:
		return
	# Find the position the user has their mouse over and calculate deltas.
	var position_dragged_to = plane_intersection_from_mouse()
	if position_dragged_to == null:
		return

	var viewport = PlayerData.get_local_player().camera_get_viewport()
	if viewport.get_camera_3d().is_position_behind(position_dragged_to):
		return
	var angle_dragged_to: float = _point_to_ring_angle(position_dragged_to)
	var rotation_delta: float = angle_dragged_to - angle_dragged_from
	# If snapping is enabled, snap.
	if _gizmo.is_snap_enabled():
		rotation_delta = snapped(rotation_delta, snap_radians)
	target.process_active_rotation(Basis(active_plane.normal, rotation_delta))


func _point_to_ring_angle(point) -> float:
	# The specific points don't matter as long as they're on the plane.
	var to: Vector3 = point - axis_center()
	var from: Vector3
	if _gizmo.is_relative:
		match current_gizmo_piece:
			GizmoPiece.X_PLANE:
				from = axis_y() - axis_center()
			GizmoPiece.Y_PLANE:
				from = axis_z() - axis_center()
			GizmoPiece.Z_PLANE:
				from = axis_y() - axis_center()
	else:
		from = Vector3(active_plane.normal.z, active_plane.normal.x, active_plane.normal.y)
	return from.signed_angle_to(to, active_plane.normal)


func show_gizmo():
	for i in range(GizmoPiece.Z_PLANE + 1):
		get_child(i).show_gizmo()


func hide_gizmo():
	for i in range(GizmoPiece.Z_PLANE + 1):
		get_child(i).hide_gizmo()
