extends Area3D


@onready var _collision_shape: CollisionShape3D = $CollisionShape
@onready var _mesh: MeshInstance3D = $Mesh
@onready var _material: StandardMaterial3D = _mesh.mesh.material


func _ready():
	GameUI.instance.creator_ui.terrain_tool.terrain_tool_settings_changed.connect(update_ghost_preview)
	update_ghost_preview()


func check_object_collision() -> bool:
	for obj in get_overlapping_bodies():
		if obj.is_in_group("prevent_voxel_placement"):
			return true
	return false


func set_enabled(is_enabled: bool) -> void:
	visible = is_enabled
	_collision_shape.disabled = not is_enabled


func update_ghost_preview() -> void:
	var terrain_tool = GameUI.instance.creator_ui.terrain_tool
	var tween = create_tween()
	tween.tween_property(self, "scale", (terrain_tool.brush_size + 0.1) * Vector3.ONE, 0.1)

	var ghost_color = Color.BLACK
	var ghost_transparency = 0.2 + terrain_tool.brush_strength / 5.0
	match terrain_tool.brush_mode:
		Enums.TERRAIN_MODE.Add:
			ghost_color = Color(0, 0, 1, ghost_transparency)
		Enums.TERRAIN_MODE.Subtract:
			ghost_color = Color(1, 0, 0, ghost_transparency)
		Enums.TERRAIN_MODE.Flatten:
			ghost_color = Color(0, 1, 0, ghost_transparency)
		Enums.TERRAIN_MODE.Paint:
			ghost_color = Color(0, 0, 0, ghost_transparency)

	if check_object_collision():
		ghost_color = Color(0, 0, 0, 0.5)
	tween.tween_property(_material, "albedo_color", ghost_color, 0.1)
