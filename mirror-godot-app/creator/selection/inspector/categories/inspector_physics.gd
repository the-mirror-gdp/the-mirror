extends InspectorCategoryBase


var target_node: SpaceObject
var _mass_cache: float
var _gravity_scale_cache: float

@onready var _property_list = $Properties/MarginContainer/PropertyList
@onready var _collision_checkbox = _property_list.get_node(^"CollisionCheckbox")
@onready var _collision_subset = _property_list.get_node(^"CollisionSubset")
@onready var _shape_type = _collision_subset.get_node(^"PropertyList/ShapeType")
@onready var _body_type = _collision_subset.get_node(^"PropertyList/BodyType")
@onready var _dynamic_subset = _collision_subset.get_node(^"PropertyList/DynamicSubset")
@onready var _mass_property = _dynamic_subset.get_node(^"PropertyList/Mass")
@onready var _gravity_scale_property = _dynamic_subset.get_node(^"PropertyList/GravityScale")


func _ready():
	_mass_cache = target_node.mass
	_gravity_scale_cache = target_node.gravity_scale
	refresh()
	super()


func _process(_delta):
	if not is_instance_valid(target_node):
		target_node = null
		return
	if target_node.mass != _mass_cache:
		_mass_cache = target_node.mass
		refresh()
	if target_node.gravity_scale != _gravity_scale_cache:
		_gravity_scale_cache = target_node.gravity_scale
		refresh()


func refresh():
	update_active_fields_by_permissions()
	var extra_options: int = target_node.scaled_model.get_inspector_extra_physics_options()
	if extra_options > 0:
		_shape_type.add_item("Model Shapes")
		if extra_options > 1:
			_shape_type.add_item("Multi Bodies")
	_collision_checkbox.current_value = target_node.collision_enabled
	var space_object_shape_type = target_node._physics_shape_type
	# we will read the physics shape type from the private method
	# this allows our instance manager to in the background mark objects as a custom value
	# this means that we can freeze object on joining but for the player
	# they will see the property set on the space object
	_shape_type.current_value = _shape_type.values.find(target_node._physics_shape_type)
	_body_type.current_value = _body_type.values.find(target_node._physics_body_type)
	_mass_property.current_value = target_node.mass
	_mass_property.refresh()
	_gravity_scale_property.current_value = target_node.gravity_scale
	_gravity_scale_property.refresh()
	_refresh_subset_visibility()


func _refresh_subset_visibility():
	_collision_subset.visible = _collision_checkbox.current_value
	_dynamic_subset.visible = _body_type.current_value == 2 # Dynamic


func _on_collision_checkbox_value_changed(new_value: bool) -> void:
	var old_collision_enabled = target_node.collision_enabled
	if old_collision_enabled == new_value:
		return
	target_node.collision_enabled = new_value
	target_node.record_property_changed(&"collision_enabled", old_collision_enabled, target_node.collision_enabled)
	_refresh_subset_visibility()
	_inspected_object_updated(target_node)


func _on_shape_type_value_changed(new_index: int) -> void:
	var new_shape_type = _shape_type.values[new_index]
	var old_shape_type = target_node.physics_shape_type
	if old_shape_type == new_shape_type:
		return
	target_node.physics_shape_type = new_shape_type
	# Also update the body type to stay in sync with SpaceObject.
	_body_type.current_value = _body_type.values.find(target_node.physics_body_type)
	target_node.record_property_changed(&"physics_shape_type", old_shape_type, new_shape_type)
	_refresh_subset_visibility()
	_inspected_object_updated(target_node)


func _on_body_type_value_changed(new_index: int) -> void:
	var new_body_type: String = _body_type.values[new_index]
	var old_body_type: String = target_node.physics_body_type
	if old_body_type == new_body_type:
		return
	target_node.physics_body_type = new_body_type
	# Also update the shape type to stay in sync with SpaceObject.
	_shape_type.current_value = _shape_type.values.find(target_node.physics_shape_type)
	target_node.record_property_changed(&"physics_body_type", old_body_type, new_body_type)
	_refresh_subset_visibility()
	_inspected_object_updated(target_node)


func _on_mass_value_changed(new_value: float) -> void:
	var old_mass = target_node.mass
	if is_equal_approx(old_mass, new_value):
		return
	_mass_cache = new_value
	target_node.mass = _mass_cache
	target_node.record_property_changed(&"mass", old_mass, _mass_cache)
	_inspected_object_updated(target_node)


func _on_gravity_scale_value_changed(new_value: float) -> void:
	var old_gravity_scale = target_node.gravity_scale
	if is_equal_approx(old_gravity_scale, new_value):
		return
	_gravity_scale_cache = new_value
	target_node.gravity_scale = _gravity_scale_cache
	target_node.record_property_changed(&"gravity_scale", old_gravity_scale, _gravity_scale_cache)
	_inspected_object_updated(target_node)
