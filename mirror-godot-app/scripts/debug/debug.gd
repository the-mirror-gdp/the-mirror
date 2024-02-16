extends Node3D


const DebugLines3D = preload("res://scripts/debug/draw_line3d.gd")

@onready var lines = DebugLines3D.new()

var debug_sphere_scene = preload("res://prefabs/debug/debug_sphere.tscn")
var debug_spheres: Dictionary = {}


func move_singleton_sphere(
	key, global_pos: Vector3, color: Color = Color.WHITE, parent = get_tree().current_scene
):
	if not debug_spheres.has(key):
		debug_spheres[key] = debug_sphere_scene.instantiate()
	if debug_spheres[key].get_parent() != parent:
		parent.add_child(debug_spheres[key])
	debug_spheres[key].global_transform.origin = global_pos
	debug_spheres[key].get_surface_material(0).albedo_color = color


func remove_singleton_sphere(key):
	if debug_spheres.has(key):
		debug_spheres[key].queue_free()
	return debug_spheres.erase(key)
