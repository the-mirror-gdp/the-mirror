extends Node3D


# The amount of grid cells per meter.
const GRID_SIZE = 4.0
const COLLISION_LAYER_RAYCAST = 1 << 10
const ERROR_SCENE: PackedScene = preload("error/error_recreation.gltf")

var _error: Node

@onready var _fade_animator: AnimationPlayer = $FadeAnimator
@onready var _emission_animator: AnimationPlayer = $EmissionAnimator
@onready var _placeholder_mesh: MeshInstance3D = $_PlaceholderMesh


func _ready() -> void:
	# a bit of variations to the animations to make it look more interesting in case when many
	# placeholders are pointing to the same asset
	_emission_animator.set_speed_scale(randf_range(0.8, 1.1))


func setup(aabb: AABB):
	if _placeholder_mesh == null:
		swap_grid_for_error()
		return
	position = aabb.get_center()
	var size = (aabb.size * GRID_SIZE).ceil()
	scale = size / GRID_SIZE
	var mat: ShaderMaterial = _placeholder_mesh.get_surface_override_material(0)
	mat.set_shader_parameter("uv1_scale", size)
	var aabb_mean_center_dist = (aabb.size.x + aabb.size.y + aabb.size.z) / 6.0
	mat.set_shader_parameter("aabb_mean_center_distance", aabb_mean_center_dist)
	for i in range(3):
		if int(size[i]) & 1 == 1:
			mat.set_shader_parameter("uv1_offset", 0.5)
	fade_in()


func swap_grid_for_error() -> void:
	if _placeholder_mesh:
		_placeholder_mesh.queue_free()
		_placeholder_mesh = null
		_error = ERROR_SCENE.instantiate()
		add_child(_error)


func grab() -> void:
	# TODO: We will be able to simplify this in the future after we get
	# upstream engine changes that allow the _error node to be the area.
	var area: Area3D = _error if _error is Area3D else _error.get_child(0)
	area.collision_layer = 0


func release() -> void:
	var area: Area3D = _error if _error is Area3D else _error.get_child(0)
	area.collision_layer = COLLISION_LAYER_RAYCAST


func fade_in():
	_emission_animator.play(&"idle")
	_fade_animator.play(&"fadein")


func fade_out():
	_fade_animator.play(&"fadeout")


func _on_fade_animator_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"fadeout":
		_emission_animator.stop()
		var parent = get_parent()
		parent.remove_child(self)
		parent.on_node_structure_changed()
		queue_free()
