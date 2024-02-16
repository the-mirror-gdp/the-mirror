extends InspectorCategoryBase


const _DEG2RAD = 0.0174532925199432957692369077
const _RAD2DEG = 57.295779513082320876798154814

var target_node: Node3D
var _transform_cache: Transform3D
# The scale and offset caches are only used for SpaceObject children.
var _scale_cache: Vector3
var _model_offset_cache: Vector3

@onready var _property_list = $Properties/MarginContainer/PropertyList
@onready var _position_property = _property_list.get_node(^"Position")
@onready var _rotation_property = _property_list.get_node(^"Rotation")
@onready var _scale_property = _property_list.get_node(^"Scale")
@onready var _model_offset_property = _property_list.get_node(^"ModelOffset")
@onready var _center_model_button = _property_list.get_node(^"CenterModel")


func _ready():
	_transform_cache = target_node.transform
	if target_node is SpaceObject and target_node.asset_type != Enums.ASSET_TYPE.MAP:
		_scale_cache = target_node.get_model_scale()
		_model_offset_cache = target_node.get_model_offset()
		_model_offset_property.show()
		_center_model_button.show()
	elif target_node is Light3D:
		# Lights do not care about scale, and some types of rotation.
		_scale_property.hide()
		if target_node is DirectionalLight3D:
			_position_property.hide()
			_rotation_property.reset_value = Vector3(-60.0, -30.0, 0.0)
		if target_node is OmniLight3D:
			_rotation_property.hide()
		else:
			_rotation_property._number_fields[2].hide()
	elif target_node.name.contains("Control Point"):
		_rotation_property.hide()
	elif (
			target_node is Heightmap
			or (target_node is SpaceObject and target_node.asset_type == Enums.ASSET_TYPE.MAP)
	):
		_rotation_property._number_fields[Vector3.AXIS_X].hide()
		_rotation_property._number_fields[Vector3.AXIS_Z].hide()
		_scale_property.hide()
	elif "terrain_generator_name" in target_node:
		self.hide()
	refresh()
	super()


func _process(_delta):
	if target_node == null:
		return
	if not is_instance_valid(target_node):
		target_node = null
		printerr("WARNING: The inspector is not being used properly. When the target node is no longer valid, tell the inspector to inspect null so that it deletes the instanced categories. Check that the node_structure_changed signal is being emitted.")
		return
	var changed: bool = false
	if target_node.transform != _transform_cache:
		_transform_cache = target_node.transform
		changed = true
	if target_node is SpaceObject:
		if not target_node.get_model_scale().is_equal_approx(_scale_cache):
			_scale_cache = target_node.get_model_scale()
			changed = true
		if not target_node.get_model_offset().is_equal_approx(_model_offset_cache):
			_model_offset_cache = target_node.get_model_offset()
			changed = true
	if changed:
		refresh()


func refresh():
	var can_edit = update_active_fields_by_permissions()
	_center_model_button.disabled = not can_edit
	_position_property.current_value = target_node.position
	_rotation_property.current_value = target_node.rotation * _RAD2DEG
	if target_node is SpaceObject:
		_scale_property.current_value = target_node.get_model_scale()
		_model_offset_property.current_value = target_node.get_model_offset()
	else:
		_scale_property.current_value = target_node.scale


func _on_transform_changed(_new_value: Vector3) -> void:
	_transform_cache = Transform3D(
		Basis.from_euler(_rotation_property.current_value * _DEG2RAD),
		_position_property.current_value
	)
	_scale_cache = _scale_property.current_value
	_model_offset_cache = _model_offset_property.current_value
	for i in range(3):
		if abs(_scale_cache[i]) < 0.001:
			_scale_cache[i] = 0.001
	if target_node is SpaceObject:
		# Update the SpaceObject's model scale and record a change for the undo system.
		var old_scale: Vector3 = target_node.get_model_scale()
		target_node.set_model_scale(_scale_cache)
		if not old_scale.is_equal_approx(_scale_cache):
			target_node.record_property_changed(&"scale", old_scale, _scale_cache)
		# Update the SpaceObject's model offset and record a change for the undo system.
		var old_model_offset: Vector3 = target_node.get_model_offset()
		target_node.set_model_offset(_model_offset_cache)
		if not old_model_offset.is_equal_approx(_model_offset_cache):
			target_node.record_property_changed(&"model_offset", old_model_offset, _model_offset_cache)
		# Update the SpaceObject and record a change for the undo system.
		var old_transform: Transform3D = target_node.transform
		target_node.editmode_set_new_transform(_transform_cache)
		if not old_transform.is_equal_approx(_transform_cache):
			target_node.record_property_changed(&"transform", old_transform, _transform_cache)
	else:
		# Update a Node3D that isn't a SpaceObject (scale is directly on it).
		_transform_cache.basis *= Basis.from_scale(_scale_property.current_value)
		if target_node is SelectionHelper:
			target_node.apply_transform_to_selection(_transform_cache.origin, _transform_cache.basis, _scale_cache)
		target_node.transform = _transform_cache
	_inspected_object_updated(target_node)


func _on_center_model_pressed() -> void:
	assert(target_node is SpaceObject)
	var old_model_offset: Vector3 = target_node.get_model_offset()
	target_node.center_model_offset()
	target_node.record_property_changed(&"model_offset", old_model_offset, target_node.get_model_offset())
