extends "../categories/inspector_category_base.gd"


signal request_select_and_focus_on_node(selected_node: Node)

const _BUTTON_INSPECTOR_PRIMITIVE = preload("res://creator/selection/inspector/primitive/inspector_button.tscn")
const _DROPDOWN_INSPECTOR_PRIMITIVE = preload("res://creator/selection/inspector/primitive/inspector_dropdown.tscn")
const _LINE_EDIT_INSPECTOR_PRIMITIVE = preload("res://creator/selection/inspector/primitive/inspector_line_edit_field.tscn")
const _VECTOR_SCALAR_PRIMITIVE = preload("res://creator/selection/inspector/primitive/inspector_vector_scalar.tscn")

const _SEAT_EDITOR_SCENE = preload("res://creator/selection/inspector/nodes/visual_editor/seat/seat_editor.tscn")
const _TRANSFORM_EDITOR_SCENE = preload("res://creator/selection/inspector/nodes/visual_editor/transform_editor.tscn")
const _OUTLINE_COLOR := Color.CYAN

var target_node: SpaceObject
var target_json_dict: Dictionary
var _visual_editor: Node3D

var _extensions: Dictionary
var _physics_shape_ext: Dictionary
var _spawn_point_ext: Dictionary

var _shape_type_dropdown: Control
var _shape_size_property: Control
var _spawn_point_team_prop: Control

@onready var _property_list = $Properties/MarginContainer/PropertyList


func _process(_delta: float) -> void:
	if not is_instance_valid(target_node):
		queue_free()
		return
	if not _physics_shape_ext.is_empty():
		_process_physics_shape_outlines()
	if target_node.extra_node_dicts.has(target_json_dict):
		return
	# The SpaceObject's extra node list no longer includes the dict we
	# were editing. Let's try to recover by finding one with the same name.
	for dict in target_node.extra_node_dicts:
		if dict["name"] == target_json_dict["name"]:
			_setup_dict_references(dict)
			_refresh_already_setup_inspectors()
			return
	# If we got here, what we were editing has disappeared. Time to self-destruct.
	queue_free()


func populate_extra_node_inspector(in_target_json_dict: Dictionary) -> void:
	_setup_dict_references(in_target_json_dict)
	# Set up properties for specific extensions. It may seem odd to have one
	# inspector category handle multiple extra node types, but it makes sense
	# given the context that different extra node types may have overlapping
	# features (ex: triggers, colliders, and seats all have shapes).
	var visual_editor_prop: Control = _BUTTON_INSPECTOR_PRIMITIVE.instantiate()
	if _extensions.has("OMI_seat"):
		visual_editor_prop.label_text = "Seat"
		visual_editor_prop.button_text = "Toggle Seat Editor"
		if target_node.has_node(^"Seat Editor"):
			_visual_editor = target_node.get_node(^"Seat Editor")
	else:
		visual_editor_prop.label_text = "Transform"
		visual_editor_prop.button_text = "Toggle Transform Editor"
		if target_node.has_node(^"Transform Editor"):
			_visual_editor = target_node.get_node(^"Transform Editor")
	visual_editor_prop.inspector_button_pressed.connect(toggle_visual_editor)
	_property_list.add_child(visual_editor_prop)
	if _extensions.has("OMI_physics_shape"):
		_setup_physics_shape_inspector()
	if _extensions.has("OMI_spawn_point"):
		_setup_spawn_point_inspector()


func toggle_visual_editor() -> void:
	if is_instance_valid(_visual_editor):
		target_node.remove_child(_visual_editor)
		_visual_editor.free()
		_visual_editor = null
		return
	if target_json_dict.get("extensions", {}).has("OMI_seat"):
		_visual_editor = _SEAT_EDITOR_SCENE.instantiate()
	else:
		_visual_editor = _TRANSFORM_EDITOR_SCENE.instantiate()
	target_node.add_child(_visual_editor)
	_visual_editor.setup_visual_editor(target_node, target_json_dict)
	request_select_and_focus_on_node.emit(_visual_editor)


func delete_extra_node():
	target_node.remove_extra_node(target_json_dict)
	_inspected_object_updated(target_node)


func _setup_dict_references(in_target_dict: Dictionary) -> void:
	assert(in_target_dict.has("extensions"))
	target_json_dict = in_target_dict
	_extensions = in_target_dict["extensions"]
	if _extensions.has("OMI_physics_shape"):
		_physics_shape_ext = _extensions["OMI_physics_shape"]
	if _extensions.has("OMI_spawn_point"):
		_spawn_point_ext = _extensions["OMI_spawn_point"]


func _setup_physics_shape_inspector() -> void:
	var shape_type: String = _physics_shape_ext["type"]
	_shape_type_dropdown = _DROPDOWN_INSPECTOR_PRIMITIVE.instantiate()
	_shape_type_dropdown.label_text = "Shape Type"
	_shape_type_dropdown.values = ["box", "sphere", "capsule", "cylinder"]
	_property_list.add_child(_shape_type_dropdown)
	_shape_type_dropdown.select_value_no_signal(shape_type)
	_shape_type_dropdown.value_changed.connect(_on_shape_type_changed)
	_shape_size_property = _VECTOR_SCALAR_PRIMITIVE.instantiate()
	_shape_size_property.label_text = "Shape Size"
	_property_list.add_child(_shape_size_property)
	_shape_size_property.hide_linked_button()
	var size_vector: Vector3 = _get_shape_size_vector_from_ext()
	_set_shape_size_property(_physics_shape_ext["type"], size_vector)
	_shape_size_property.value_changed.connect(_on_shape_size_changed)


func _setup_spawn_point_inspector() -> void:
	_spawn_point_team_prop = _LINE_EDIT_INSPECTOR_PRIMITIVE.instantiate()
	_spawn_point_team_prop.value_changed.connect(_on_spawn_point_team_changed)
	_spawn_point_team_prop.label_text = "Team"
	_property_list.add_child(_spawn_point_team_prop)
	_spawn_point_team_prop.current_value = _spawn_point_ext["team"]


func _process_physics_shape_outlines() -> void:
	var shape_type: String = _physics_shape_ext["type"]
	var shape_size: Vector3 = _get_shape_size_vector_from_ext()
	var shape_transform: Transform3D = target_node.scaled_model.global_transform.scaled_local(shape_size)
	if shape_type == "box":
		GameUI.object_outlines.draw_wireframe_box_transform(shape_transform, _OUTLINE_COLOR)
	elif shape_type == "sphere":
		GameUI.object_outlines.draw_wireframe_sphere(shape_transform, _OUTLINE_COLOR)
	else:
		shape_transform = shape_transform.scaled_local(Vector3(1.0, shape_size.x / shape_size.y, 1.0))
		if shape_type == "capsule":
			var half_mid_height: float = (shape_size.y - shape_size.x) * 0.5
			GameUI.object_outlines.draw_wireframe_capsule(shape_transform, half_mid_height, _OUTLINE_COLOR)
		if shape_type == "cylinder":
			var half_height: float = shape_size.y * 0.5
			GameUI.object_outlines.draw_wireframe_cylinder(shape_transform, half_height, _OUTLINE_COLOR)


func _refresh_already_setup_inspectors() -> void:
	if _shape_type_dropdown:
		var shape_type: String = _physics_shape_ext["type"]
		_shape_type_dropdown.select_value_no_signal(shape_type)
		var size_vector: Vector3 = _get_shape_size_vector_from_ext()
		_set_shape_size_property(shape_type, size_vector)
	if _spawn_point_team_prop:
		_spawn_point_team_prop.current_value = _spawn_point_ext["team"]


func _get_shape_size_vector_from_ext() -> Vector3:
	var shape_type: String = _physics_shape_ext["type"]
	if shape_type == "box":
		if not _physics_shape_ext.has("size"):
			return Vector3.ONE
		return Serialization.array_to_vector3(_physics_shape_ext["size"])
	var radius: float = _physics_shape_ext.get("radius", 0.5)
	if shape_type == "sphere":
		return Vector3(radius, radius, radius)
	var height: float = _physics_shape_ext.get("height", 2.0)
	return Vector3(radius, height, radius)


func _set_shape_size_property(shape_type: String, size_vector: Vector3) -> void:
	var is_sphere: bool = shape_type == "sphere"
	_shape_size_property.set_include_z(shape_type == "box" or is_sphere)
	_shape_size_property.set_unified(is_sphere)
	_shape_size_property.current_value = size_vector
	_shape_size_property.refresh_xyz()


func _on_shape_type_changed(shape_index: int) -> void:
	var shape_type: String = _shape_type_dropdown.get_value_at_index(shape_index)
	if shape_type == _physics_shape_ext["type"]:
		return
	var is_trigger: bool = _physics_shape_ext.get("isTrigger", false)
	var size_vector: Vector3 = _get_shape_size_vector_from_ext()
	# Erase physics shape extension to ensure we don't have any dead keys.
	_physics_shape_ext.clear()
	_physics_shape_ext["isTrigger"] = is_trigger
	_physics_shape_ext["type"] = shape_type
	_set_shape_size_property(shape_type, size_vector)
	_on_shape_size_changed(size_vector)


func _on_shape_size_changed(size_vector: Vector3) -> void:
	var shape_type: String = _physics_shape_ext["type"]
	if shape_type == "box":
		_physics_shape_ext["size"] = Serialization.vector3_to_array(size_vector)
	else:
		_physics_shape_ext["radius"] = size_vector.x
		if shape_type != "sphere":
			if shape_type == "capsule":
				if size_vector.y < size_vector.x * 2.0:
					size_vector.y = size_vector.x * 2.0
			_physics_shape_ext["height"] = size_vector.y
	_inspected_object_updated(target_node)


func _on_spawn_point_team_changed(new_team: String) -> void:
	_spawn_point_ext["team"] = new_team
	_inspected_object_updated(target_node)
