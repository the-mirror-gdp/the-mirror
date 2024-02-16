extends BaseGizmoPart


var position_dragged_from := Vector3.ZERO
var snap_meters: float = 0.1


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
	# Set up the active plane.
	var active_vector := Vector3.ZERO
	if current_gizmo_piece == GizmoPiece.XYZ_CENTER:
		var viewport = PlayerData.get_local_player().camera_get_viewport()
		active_vector = viewport.get_camera_3d().global_transform.basis.z
	elif _gizmo.is_relative:
		active_vector = original_transform.basis[current_gizmo_piece % 3]
	else:
		active_vector[current_gizmo_piece % 3] = 1
	active_plane = Plane(active_vector, original_transform.origin)
	# Determine the starting value so that we can later be offset from this.
	if current_gizmo_piece <= GizmoPiece.Z_PLANE or current_gizmo_piece == GizmoPiece.XYZ_CENTER:
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
	# Find the position the user has their mouse over and calculate the new position.
	var position_dragged_to = Vector3.ZERO # : Vector3?
	if current_gizmo_piece <= GizmoPiece.Z_PLANE or current_gizmo_piece == GizmoPiece.XYZ_CENTER:
		position_dragged_to = plane_intersection_from_mouse()
	elif current_gizmo_piece <= GizmoPiece.Z_ARROW:
		position_dragged_to = line_intersection_from_mouse(original_transform.origin, active_plane.normal)
	if position_dragged_to == null:
		return
	# Calculate the new position (including snap) and move the object there.
	var offset_vec = position_dragged_to - position_dragged_from
	if _gizmo.is_snap_enabled():
		if _gizmo.is_relative:
			var local_ortho = original_transform.basis.orthonormalized()
			offset_vec = local_ortho * (offset_vec * local_ortho).snapped(snap_meters * Vector3.ONE)
		else:
			offset_vec = offset_vec.snapped(snap_meters * Vector3.ONE)
	target.process_active_translation(offset_vec)


func show_gizmo():
	for i in range(GizmoPiece.XYZ_CENTER + 1):
		get_child(i).show_gizmo()


func hide_gizmo():
	for i in range(GizmoPiece.XYZ_CENTER + 1):
		get_child(i).hide_gizmo()

