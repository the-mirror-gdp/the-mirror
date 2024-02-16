class_name BaseGizmoPart
extends Node3D


signal transformation_ended
signal transformation_started

enum GizmoPiece {
	NONE = -1,
	X_PLANE = 0,
	Y_PLANE = 1,
	Z_PLANE = 2,
	X_ARROW = 3,
	Y_ARROW = 4,
	Z_ARROW = 5,
	XYZ_CENTER = 6,
}

var original_transform := Transform3D()
var original_scale = Vector3(1, 1, 1)
var active_plane := Plane()
var current_gizmo_piece := GizmoPiece.NONE

@onready var _gizmo: Gizmo = get_parent()


func _ready():
	transformation_ended.connect(_gizmo.on_transformation_ended)
	transformation_started.connect(_gizmo.on_transformation_started)
	for child in self.get_children():
		# Runtime type checking
		assert(child is GizmoHandle)
		child.received_mouse_raycast.connect(process_input_signal)


func _process(_delta: float) -> void:
	if current_gizmo_piece == GizmoPiece.NONE:
		return
	process_active_transform()


func _input(input_event: InputEvent) -> void:
	if current_gizmo_piece == GizmoPiece.NONE:
		return
	if input_event.is_action_released(&"primary_action"):
		end_transform(self.name)
		get_viewport().set_input_as_handled()


func process_input_signal(input_event: InputEvent, gizmo_piece) -> void:
	if Input.is_action_pressed(&"secondary_action"):
		return
	if input_event.is_action_pressed(&"primary_action"):
		start_transform(gizmo_piece)


func start_transform(_gizmo_piece: GizmoPiece) -> void:
	printerr("This method must be overridden in derived classes.")


func process_active_transform() -> void:
	printerr("This method must be overridden in derived classes.")


func end_transform(node_name) -> void:
	if current_gizmo_piece >= get_child_count():
		return
	var target = get_target()
	if target:
		if target.has_method(&"queue_update_network_object"):
			target.queue_update_network_object()
		# We match on both "scale" and "scaling"
		if node_name.to_lower().contains("scal"):
			if target.has_method(&"record_property_changed"):
				target.record_property_changed(&"scale", original_scale, target.scale)
		else:
			if target.has_method(&"record_property_changed"):
				target.record_property_changed(&"transform", original_transform, target.transform)
	get_child(current_gizmo_piece).stop_highlight()
	current_gizmo_piece = GizmoPiece.NONE
	transformation_ended.emit()


func get_target() -> Node3D:
	return _gizmo.target if is_instance_valid(_gizmo.target) else null


func stop_highlight():
	for child in get_children():
		child.stop_highlight()


func plane_intersection_from_mouse(): # -> Vector3?:
	var local_player: Player = PlayerData.get_local_player()
	var ray: Dictionary = Util.create_ray_from_mouse_click(local_player.camera_get_viewport())
	return active_plane.intersects_ray(ray.origin, ray.normal)


func line_intersection_from_mouse(line_position, line_normal) -> Vector3:
	var local_player = PlayerData.get_local_player()
	var ray: Dictionary = Util.create_ray_from_mouse_click(local_player.camera_get_viewport())
	# https://math.stackexchange.com/questions/1993953/closest-points-between-two-lines
	var pos_diff = line_position - ray.origin
	var cross_normal = line_normal.cross(ray.normal).normalized()
	var rejection = pos_diff - pos_diff.project(ray.normal) - pos_diff.project(cross_normal)
	var distance_to_line_pos = rejection.length() / line_normal.dot(rejection.normalized())
	var closest_approach = line_position - line_normal * distance_to_line_pos
	return closest_approach


func _on_visibility_changed():
	for child in get_children():
		for grand_child in child.get_children():
			if grand_child is CollisionShape3D:
				grand_child.disabled = not self.visible


func axis_x() -> Vector3: return original_transform.origin + original_transform.basis.x.normalized()
func axis_y() -> Vector3: return original_transform.origin + original_transform.basis.y.normalized()
func axis_z() -> Vector3: return original_transform.origin + original_transform.basis.z.normalized()
func axis_center() -> Vector3: return original_transform.origin

func plane_xy() -> Plane: return Plane(axis_x(), axis_center(), axis_y())
func plane_xz() -> Plane: return Plane(axis_z(), axis_center(), axis_x())
func plane_yz() -> Plane: return Plane(axis_y(), axis_center(), axis_z())
