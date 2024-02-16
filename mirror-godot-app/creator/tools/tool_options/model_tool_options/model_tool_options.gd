extends Control


@export var button_selected_style: StyleBox
@export var button_deselected_style: StyleBox

@export var _current_model_label: Label
@export var _create_button: Button
@export var _settings_container: VBoxContainer

@export var _box_mesh_button: Button
@export var _sphere_mesh_button: Button
@export var _capsule_mesh_button: Button
@export var _cylinder_mesh_button: Button
@export var _cone_mesh_button: Button
@export var _triangle_mesh_button: Button
@export var _grid_size_option_button: OptionButton
@export var _color_picker: ColorPickerButton

var _model_tool: Node
var _model_builder: Node


func setup(model_tool: Node) -> void:
	_model_tool = model_tool
	_model_builder = model_tool.model_builder
	for grid_size in _model_builder.GRID_SIZES:
		_grid_size_option_button.add_item(str(grid_size))
	_model_tool.selected_model_changed.connect(_on_selected_model_changed)
	_model_builder.settings_changed.connect(_model_tool_settings_changed)
	_update_options()
	_on_selected_model_changed(null)


func _on_selected_model_changed(new_model: ModelRoot) -> void:
	if is_instance_valid(new_model):
		_current_model_label.text = "Editing: %s" % str(new_model.name)
		_current_model_label.visible = true
		_settings_container.visible = true
	else:
		_current_model_label.visible = false
		_settings_container.visible = false


func _model_tool_settings_changed() -> void:
	_update_options()


func _update_options() -> void:
	_set_model_primitive_type(_model_builder.model_primitive_type)
	_set_model_primitive_color(_model_builder.model_primitive_color)
	_set_grid_size(_model_builder.grid_size_index)


func _set_model_primitive_type(type: ModelPrimitive.ShapeType) -> void:
	_set_button_style(_box_mesh_button, button_deselected_style)
	_set_button_style(_sphere_mesh_button, button_deselected_style)
	_set_button_style(_capsule_mesh_button, button_deselected_style)
	_set_button_style(_cylinder_mesh_button, button_deselected_style)
	_set_button_style(_cone_mesh_button, button_deselected_style)
	_set_button_style(_triangle_mesh_button, button_deselected_style)
	match type:
		ModelPrimitive.ShapeType.BOX:
			_set_button_style(_box_mesh_button, button_selected_style)
		ModelPrimitive.ShapeType.SPHERE:
			_set_button_style(_sphere_mesh_button, button_selected_style)
		ModelPrimitive.ShapeType.CAPSULE:
			_set_button_style(_capsule_mesh_button, button_selected_style)
		ModelPrimitive.ShapeType.CYLINDER:
			_set_button_style(_cylinder_mesh_button, button_selected_style)
		ModelPrimitive.ShapeType.CONE:
			_set_button_style(_cone_mesh_button, button_selected_style)
		ModelPrimitive.ShapeType.TRIANGLE:
			_set_button_style(_triangle_mesh_button, button_selected_style)


func _set_model_primitive_color(new_color: Color) -> void:
	if _color_picker:
		_color_picker.color = new_color


func _set_grid_size(new_index: int) -> void:
	if _grid_size_option_button:
		_grid_size_option_button.select(new_index)


func _set_button_style(button: Button, style: StyleBox) -> void:
	button.add_theme_stylebox_override("normal", style)


func _on_grid_size_option_selected(new_index: int):
	_model_builder.set_grid_size(new_index)


func _on_box_mesh_button_pressed() -> void:
	_model_builder.set_model_primitive_type(ModelPrimitive.ShapeType.BOX)


func _on_sphere_mesh_button_pressed() -> void:
	_model_builder.set_model_primitive_type(ModelPrimitive.ShapeType.SPHERE)


func _on_capsule_mesh_button_pressed() -> void:
	_model_builder.set_model_primitive_type(ModelPrimitive.ShapeType.CAPSULE)


func _on_cylinder_mesh_button_pressed() -> void:
	_model_builder.set_model_primitive_type(ModelPrimitive.ShapeType.CYLINDER)


func _on_cone_mesh_button_pressed() -> void:
	_model_builder.set_model_primitive_type(ModelPrimitive.ShapeType.CONE)


func _on_triangle_mesh_button_pressed() -> void:
	_model_builder.set_model_primitive_type(ModelPrimitive.ShapeType.TRIANGLE)


func _on_color_picker_changed(color: Color):
	_model_builder.set_model_primitive_color(color)


func _on_create_button_pressed():
	var space_role: Enums.ROLE = Util.get_role_for_user(Zone.space, Net.user_id)
	if space_role >= Enums.ROLE.CONTRIBUTOR:
		_model_tool.create_local_model()
	else:
		Notify.error("Creating Model Error", "You do not have permission to edit this space")


func _on_save_button_pressed():
	_model_tool.save_local_model()
