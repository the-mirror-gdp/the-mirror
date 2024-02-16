extends InspectorCategoryBase

var target_node: SpaceObject

@onready var _property_list = $Properties/MarginContainer/PropertyList
@onready var _cast_shadow_checkbox = _property_list.get_node(^"CastShadowsCheckbox")
@onready var _visibility_from = _property_list.get_node(^"VisibiltyFrom")
@onready var _visibility_to = _property_list.get_node(^"VisibilityTo")
@onready var _visibilty_from_margin =_property_list.get_node(^"VisibiltyFromMargin")
@onready var _visibility_to_margin = _property_list.get_node(^"VisibilityToMargin")

@onready var _params_mapping: Dictionary = {
	&"visible_from": _visibility_from,
	&"visible_to": _visibility_to,
	&"visible_from_margin": _visibilty_from_margin,
	&"visible_to_margin": _visibility_to_margin
}

func _ready():
	refresh()
	for param in _params_mapping:
		_params_mapping[param].value_changed.connect(_on_field_float_value_changed.bind(param))
	super()


func refresh():
	if not is_instance_valid(target_node) or not target_node is SpaceObject:
		return
	update_active_fields_by_permissions()
	_cast_shadow_checkbox.current_value = target_node.cast_shadows
	for param in _params_mapping:
		_params_mapping[param].current_value = target_node[param]
		_params_mapping[param].refresh()


func _on_cast_shadows_checkbox_value_changed(new_value):
	if not is_instance_valid(target_node) or not target_node is SpaceObject:
		printerr("Trying to change cast_shadows field not on a valid SpaceObject")
		return
	var old_cast_shadows_enabled = target_node.cast_shadows
	if old_cast_shadows_enabled == new_value:
		return
	target_node.cast_shadows = new_value
	target_node.record_property_changed(&"cast_shadows", old_cast_shadows_enabled, target_node.cast_shadows)
	_inspected_object_updated(target_node)


func _on_field_float_value_changed(new_value: float, field_name: StringName):
	if not is_instance_valid(target_node) or not target_node is SpaceObject:
		printerr("Trying to change %s field not on a valid SpaceObject" % field_name)
		return
	var old_value = target_node[field_name]
	if is_equal_approx(old_value, new_value):
		return
	target_node[field_name] = new_value
	target_node.record_property_changed(field_name, old_value, new_value)
	_inspected_object_updated(target_node)
