class_name GizmoHandle
extends JBody3D


signal received_mouse_raycast

@export var highlight_material: BaseMaterial3D = null
var _unhighlight_material: BaseMaterial3D = null

var _meshes: Array[MeshInstance3D] = []
var _siblings: Array[JBody3D] = []


func _ready() -> void:
	desired_body_id = TMSceneSync.fetch_free_unsync_body_id()
	body_mode = JBody3D.KINEMATIC
	set_layer_name(&"GIZMO")
	create_body()

	for child in get_children():
		if child is MeshInstance3D:
			_meshes.append(child)
	_unhighlight_material = _meshes[0].get_surface_override_material(0)
	for child in get_parent().get_children():
		if child != self and child is JBody3D:
			_siblings.append(child)


func start_highlight():
	for sibling in _siblings:
		sibling.stop_highlight()
	for m in _meshes:
		m.material_override = highlight_material
		if m.name == "Tip":
			m.scale = Vector3.ONE * 1.25


func stop_highlight():
	for m in _meshes:
		m.material_override = _unhighlight_material
		if m.name == "Tip":
			m.scale = Vector3.ONE


func click_raycast_event(event):
	if not event is InputEventMouseButton:
		return
	received_mouse_raycast.emit(event, get_index())


func show_gizmo():
	set_layer_name(&"GIZMO")
	show()


func hide_gizmo():
	set_layer_name(&"")
	hide()
