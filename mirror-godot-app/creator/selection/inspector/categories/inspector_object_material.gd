extends InspectorCategoryBase


var target_node: SpaceObject

@onready var _property_list = $Properties/MarginContainer/PropertyList
@onready var _base_material_property = _property_list.get_node(^"BaseMaterial")
@onready var _albedo_color_node = _property_list.get_node(^"AlbedoColor")
@onready var _texture_property = _property_list.get_node(^"Texture")
@onready var _triplanar_property = _property_list.get_node(^"Triplanar")
@onready var _uv_scale_property = _property_list.get_node(^"UVScale")
@onready var _uv_offset_property = _property_list.get_node(^"UVOffset")
@onready var _texture_repeat_property = _property_list.get_node(^"TextureRepeat")

var _cache_object_texture_id: String = ""

func _ready() -> void:
	refresh()
	super()


func _refresh_uv_editable_axes():
	_uv_offset_property.set_include_z(target_node.object_texture_triplanar)
	_uv_scale_property.set_include_z(target_node.object_texture_triplanar)


func refresh() -> void:
	update_active_fields_by_permissions()
	_base_material_property.current_value = target_node.material_id
	_albedo_color_node.current_value = target_node.object_color
	_texture_property.current_value = target_node.object_texture_id
	_triplanar_property.current_value = target_node.object_texture_triplanar
	_texture_repeat_property.current_value = target_node.object_texture_repeat
	_uv_scale_property.setup_from_vector3(target_node.object_texture_size)
	_uv_offset_property.setup_from_vector3(target_node.object_texture_offset)
	_uv_offset_property.set_unified(false)
	_refresh_uv_editable_axes()


func _on_base_material_value_changed(new_value: String) -> void:
	var old_value = target_node.material_id
	if old_value == new_value:
		return
	target_node.material_id = new_value
	target_node.record_property_changed(&"material_id", old_value, target_node.material_id)
	_inspected_object_updated(target_node)


func _on_albedo_color_value_changed(new_value: Color) -> void:
	var old_value = target_node.object_color
	if old_value == new_value:
		return
	target_node.object_color = new_value
	target_node.record_property_changed(&"object_color", old_value, target_node.object_color)
	_inspected_object_updated(target_node)


func _on_texture_value_changed(new_value: String) -> void:
	var old_value = target_node.object_texture_id
	if old_value == new_value:
		return
	target_node.object_texture_id = new_value
	target_node.record_property_changed(&"object_texture_id", old_value, target_node.object_texture_id)
	_inspected_object_updated(target_node)


func _on_triplanar_value_changed(new_value: bool) -> void:
	var old_value = target_node.object_texture_triplanar
	if old_value == new_value:
		return
	target_node.object_texture_triplanar = new_value
	target_node.record_property_changed(&"object_texture_triplanar", old_value, target_node.object_texture_triplanar)
	_refresh_uv_editable_axes()
	_inspected_object_updated(target_node)


func _on_uv_scale_value_changed(new_value: Vector3) -> void:
	var old_value = target_node.get_last_rest_api_value(&"object_texture_size")
	if old_value == new_value:
		return
	target_node.object_texture_size = new_value
	target_node.record_property_changed(&"object_texture_size", old_value, target_node.object_texture_size)
	_inspected_object_updated(target_node)


func _on_uv_offset_value_changed(new_value: Vector3) -> void:
	var old_value = target_node.get_last_rest_api_value(&"object_texture_offset")
	if old_value == new_value:
		return
	target_node.object_texture_offset = new_value
	target_node.record_property_changed(&"object_texture_offset", old_value, target_node.object_texture_offset)
	_inspected_object_updated(target_node)


func _on_texture_repeat_value_changed(new_value: bool) -> void:
	var old_value = target_node.object_texture_repeat
	if old_value == new_value:
		return
	target_node.object_texture_repeat = new_value
	target_node.record_property_changed(&"object_texture_repeat", old_value, target_node.object_texture_repeat)
	_inspected_object_updated(target_node)


func _on_uv_offset_value_preview(new_value):
	target_node.object_texture_offset = new_value


func _on_uv_scale_value_preview(new_value):
	target_node.object_texture_size = new_value


func _process(_delta):
	if target_node == null and is_visible_in_tree():
		return
	if not is_instance_valid(target_node):
		target_node = null
		printerr("WARNING: The inspector is not being used properly. When the target node is no longer valid, tell the inspector to inspect null so that it deletes the instanced categories. Check that the node_structure_changed signal is being emitted.")
		return
	var changed: bool = false
	if target_node is SpaceObject and target_node.asset_type == Enums.ASSET_TYPE.MESH:
		if target_node.object_texture_id != _cache_object_texture_id:
			_cache_object_texture_id = target_node.object_texture_id
			changed = true
	if changed:
		refresh()
