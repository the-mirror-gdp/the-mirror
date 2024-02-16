extends PanelContainer


signal on_surface_material_updated(target_mesh_instance: MeshInstance3D, traget_surface: int, new_material: MirrorMaterial)

const _TMP_NORMALMAP_FILENAME = "tmp_gen_normalmap.webp"

@onready var _side_bar: Container = %SideBar
@onready var _mesh_box = $HSplitContainer/MarginContainer/SubViewportContainer/SubViewport/Box
@onready var _mesh_sphere = $HSplitContainer/MarginContainer/SubViewportContainer/SubViewport/Sphere
@onready var _sub_viewport: SubViewport = $HSplitContainer/MarginContainer/SubViewportContainer/SubViewport
@onready var _directional_light_3d = $HSplitContainer/MarginContainer/SubViewportContainer/SubViewport/DirectionalLight3D
@onready var _material_inspector = %MaterialInspector

var _edited_mesh_instance: MeshInstance3D = null
var _edited_surface: int = -1


func setup_mesh_target(space_object: SpaceObject, mesh: MeshInstance3D, surface_id: int) -> void:
	_edited_mesh_instance = mesh
	_edited_surface = surface_id
	_material_inspector.setup_mesh_target(space_object, mesh, surface_id)
	_mesh_box.set_surface_override_material(0, _material_inspector.target_material)
	_mesh_sphere.set_surface_override_material(0, _material_inspector.target_material)


func _on_box_toggled(button_pressed) -> void:
	_mesh_box.visible = true
	_mesh_sphere.visible = false


func _on_sphere_toggled(button_pressed) -> void:
	_mesh_box.visible = false
	_mesh_sphere.visible = true


func _on_custom_world_toggled(button_pressed) -> void:
	_sub_viewport.own_world_3d = not button_pressed
	_directional_light_3d.visible = not button_pressed


func _on_material_template_list_on_template_selected(template) -> void:
	_mesh_box.set_surface_override_material(0, _material_inspector.target_material)
	_mesh_sphere.set_surface_override_material(0, _material_inspector.target_material)
	on_surface_material_updated.emit(_edited_mesh_instance, _edited_surface, _material_inspector.target_material)


func _on_material_inspector_material_created(type: String, material_id: String) -> void:
	Zone.material_manager.lazy_set_material(_mesh_box, 0, material_id, type)
	Zone.material_manager.lazy_set_material(_mesh_sphere, 0, material_id, type)
