extends InspectorCategoryBase


var target_node: Light3D

@onready var _property_list = $Properties/MarginContainer/PropertyList
@onready var _light_range = _property_list.get_node(^"LightRange")
@onready var _spot_angle = _property_list.get_node(^"SpotAngle")
@onready var _light_color = _property_list.get_node(^"LightColor")
@onready var _brightness = _property_list.get_node(^"Brightness")


func _ready():
	refresh()
	super()


func _process(_delta):
	if not is_instance_valid(target_node):
		target_node = null
		return
	if (
		_light_color.current_value != target_node.light_color
		or _brightness.current_value != target_node.light_energy
		or _brightness.current_value < 0 != target_node.light_negative
	):
		refresh()


func refresh():
	update_active_fields_by_permissions()
	# Range and angle.
	if target_node is SpotLight3D:
		_light_range.current_value = target_node.spot_range
		_spot_angle.current_value = target_node.spot_angle
		_spot_angle.refresh()
	else:
		_spot_angle.hide()
		if target_node is OmniLight3D:
			_light_range.current_value = target_node.omni_range
		else: # DirectionalLight3D
			_light_range.hide()
	_light_range.refresh()
	# Color and brightness.
	_light_color.current_value = target_node.light_color
	_brightness.current_value = target_node.light_energy
	if target_node.light_negative:
		_brightness.current_value *= -1.0
	_brightness.refresh()


func _on_light_range_value_changed(new_value):
	if target_node is SpotLight3D:
		target_node.spot_range = abs(new_value)
		_inspected_object_updated(target_node)
	elif target_node is OmniLight3D:
		target_node.omni_range = abs(new_value)
		_inspected_object_updated(target_node)


func _on_spot_angle_value_changed(new_value):
	target_node.spot_angle = abs(new_value)
	_inspected_object_updated(target_node)


func _on_light_color_value_changed(new_color):
	target_node.light_color = new_color
	_inspected_object_updated(target_node)


func _on_brightness_value_changed(new_value):
	target_node.light_energy = abs(new_value)
	target_node.light_negative = new_value < 0.0
	_inspected_object_updated(target_node)
