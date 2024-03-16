class_name MaterialSelector
extends Control


signal space_object_material_selected(data: SpaceObjectSelectedMaterial)

const _INDEX_MATEIRAL = preload("res://prefabs/autoload/gameplay_tools/material_selection_index.material")
const _HOVER_MATERIAL = preload("res://prefabs/autoload/gameplay_tools/material_hover.material")
@export var viewport_scaling: float = 4.0
@export var surface_id_mul: int = 1 # This is only used for visual debugging purposes, should be 1 otherwise
@export var enabled: bool = false:
	set(value):
		enabled = value
		set_process(value)
		if value == false:
			_deselect_hover()
	get:
		return is_processing()

@onready var _sub_viewport: SubViewport = %SubViewport
@onready var _isolated_camera_3d: Camera3D = %SubViewport/IsolatedCamera3D
@onready var _isolated_container: Node3D = %SubViewport/IsolatedContainer
@onready var _debug_label = $DebugLabel


var _last_hovered_surface: SpaceObjectSelectedMaterial = null
var _last_hovered_surface_material: Material = null

func _get_current_viewport() -> Viewport:
	if PlayerData.has_local_player():
		var local_player = PlayerData.get_local_player()
		return local_player.camera_get_viewport()
	else:
		return get_viewport()


func _get_camera(vp: Viewport) -> Camera3D:
	return vp.get_camera_3d()


func _get_body(camera: Camera3D) -> JBody3D:
	if not camera or not camera.has_method(&"get_mouse_raycast"):
		return null
	var gizmo_raycast_dict = camera.get_mouse_raycast([
		"STATIC",
		"DYNAMIC",
		"NO_COLLIDE"
	])
	if not gizmo_raycast_dict.has("collider"):
		return null
	return Util.get_space_object(gizmo_raycast_dict.collider)


func _get_meshinstances(collided_body: Node3D) -> Array:
	return Util.recursive_find_nodes_of_type(collided_body, MeshInstance3D)


func _track_external_camera(camera: Camera3D):
	_isolated_camera_3d.global_transform = camera.global_transform
	_isolated_camera_3d.projection = camera.projection
	_isolated_camera_3d.fov = camera.fov
	_isolated_camera_3d.near = camera.near
	_isolated_camera_3d.far = camera.far
	_isolated_camera_3d.h_offset = camera.h_offset
	_isolated_camera_3d.v_offset = camera.v_offset


func get_raycasted_surface_data() -> SpaceObjectSelectedMaterial:
	for child in _isolated_container.get_children():
		child.queue_free()
	await get_tree().process_frame # wait here because of above freeing
	var current_vp = _get_current_viewport()
	var new_coords = current_vp.get_mouse_position()/ viewport_scaling
	var camera: Camera3D = _get_camera(current_vp)
	var clicked_node: Node3D = _get_body(camera)
	if clicked_node == null:
		#print("No node clicked")
		return null
	if not clicked_node is SpaceObject:
		#print("Node is not a space Object")
		return null
	var duplicated = clicked_node.scaled_model.duplicate()
	duplicated.set_script(null)
	_isolated_container.add_child(duplicated)
	duplicated.global_transform = clicked_node.scaled_model.global_transform
	var isolated_meshinstances: = _get_meshinstances(duplicated)
	if isolated_meshinstances.size() == 0:
		#print("No child meshinstances found")
		return null
	_track_external_camera(camera)
	_sub_viewport.size = current_vp.size / viewport_scaling

	var mesh_index = 0
	for mesh in isolated_meshinstances:
		var surface_index = 0
		var surface_cnt = mesh.get_surface_override_material_count()
		for surface in mesh.get_surface_override_material_count():
			var instance_mat = _INDEX_MATEIRAL.duplicate()
			instance_mat.albedo_color = Color8(0, mesh_index, surface_index*surface_id_mul)
			mesh.set_surface_override_material(surface, instance_mat)
			surface_index += 1
		mesh_index += 1

	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var read_image = _sub_viewport.get_texture().get_image()
	var pixel = read_image.get_pixel(new_coords.x, new_coords.y)
	_debug_label.text = "Mesh %d, surface %d" % [pixel.g8, pixel.b8/surface_id_mul]
	# Find original mesh, need to iterate through original SpaceObject
	var meshinstances: = _get_meshinstances(clicked_node)
	mesh_index = 0
	for mesh in meshinstances:
		if mesh_index == pixel.g8:
			var result = SpaceObjectSelectedMaterial.new()
			result.space_object = clicked_node
			result.mesh = mesh
			result.surface_id =  pixel.b8/surface_id_mul
			return result
		mesh_index += 1
	return null


func _ready() -> void:
	set_process(false)


func _deselect_hover() -> void:
	if _last_hovered_surface != null and is_instance_valid(_last_hovered_surface.mesh):
			_last_hovered_surface.mesh.set_surface_override_material(_last_hovered_surface.surface_id, _last_hovered_surface_material)
			_last_hovered_surface = null
			_last_hovered_surface_material = null


func _process(delta) -> void:
	if not enabled or Zone.is_host():
		return
	if Input.is_action_just_pressed(&"primary_action"):
		var data = await get_raycasted_surface_data()
		space_object_material_selected.emit(data)
	else:
		if Engine.get_physics_frames() % 5 == 0:
			var data = await get_raycasted_surface_data()
			_deselect_hover()
			if data == null or not enabled: # needs to check enabled after await
				return
			_last_hovered_surface = data
			var hovered_material = data.mesh.get_surface_override_material(_last_hovered_surface.surface_id)
			if hovered_material != _HOVER_MATERIAL:
				_last_hovered_surface_material = data.mesh.get_surface_override_material(_last_hovered_surface.surface_id)
			_last_hovered_surface.mesh.set_surface_override_material(_last_hovered_surface.surface_id, _HOVER_MATERIAL)


class SpaceObjectSelectedMaterial:
	var space_object: SpaceObject
	var mesh: MeshInstance3D
	var surface_id: int

	func _to_string() -> String:
		return "SpaceObject: %s, mesh: %s, surf_id: %s" % [space_object, mesh, surface_id]
