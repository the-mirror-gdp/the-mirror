extends InspectorCategoryBase


const _MINIMUM_SIZE_METERS := 0.001

var target_node: ModelPrimitive
var _shape_type: ModelPrimitive.ShapeType
var _shape_size: PackedFloat64Array

@onready var _category_title_text = $CategoryTitle/ToggleButton/Name/Text
@onready var _property_list = $Properties/MarginContainer/PropertyList
@onready var _albedo_color_node = _property_list.get_node(^"AlbedoColor")
@onready var _size = _property_list.get_node(^"Size")
@onready var _radius = _property_list.get_node(^"Radius")
@onready var _height = _property_list.get_node(^"Height")
@onready var _slide = _property_list.get_node(^"Slide")


func _ready() -> void:
	refresh()
	_setup_category_title()
	super()
	target_node.scale_applied.connect(refresh)


func refresh() -> void:
	update_active_fields_by_permissions()
	_shape_type = target_node.shape_type
	_shape_size = target_node.shape_size
	_albedo_color_node.current_value = target_node.color
	if _shape_type == ModelPrimitive.ShapeType.BOX or _shape_type == ModelPrimitive.ShapeType.TRIANGLE:
		_size.current_value = Vector3(_shape_size[0], _shape_size[1], _shape_size[2])
		_size.show()
		if _shape_type == ModelPrimitive.ShapeType.TRIANGLE:
			_slide.current_value = _shape_size[3]
			_slide.show()
			_slide.refresh_full()
	else: # Sphere, capsule, cylinder, cone.
		_radius.current_value = _shape_size[0]
		_radius.show()
		_radius.refresh_full()
		if _shape_type != ModelPrimitive.ShapeType.SPHERE: # Capsule, cylinder, cone.
			_height.current_value = _shape_size[1]
			_height.show()
			_height.refresh_full()


func _setup_category_title() -> void:
	var category_name: String
	match _shape_type:
		ModelPrimitive.ShapeType.BOX:
			category_name = "BOX PRIMITIVE"
		ModelPrimitive.ShapeType.SPHERE:
			category_name = "SPHERE PRIMITIVE"
		ModelPrimitive.ShapeType.CAPSULE:
			category_name = "CAPSULE PRIMITIVE"
		ModelPrimitive.ShapeType.CYLINDER:
			category_name = "CYLINDER PRIMITIVE"
		ModelPrimitive.ShapeType.CONE:
			category_name = "CONE PRIMITIVE"
		ModelPrimitive.ShapeType.TRIANGLE:
			category_name = "TRIANGLE PRISM PRIMITIVE"
		_:
			category_name = "MODEL PRIMITIVE"
	var old_category_title: String = _category_title_text.text
	_category_title_text.text = category_name
	var suffix_index: int = old_category_title.find(": ")
	if suffix_index != -1:
		_category_title_text.text += old_category_title.substr(suffix_index)


func _on_albedo_color_value_changed(new_value: Color) -> void:
	var old_value = target_node.color
	if old_value == new_value:
		return
	target_node.color = new_value
	target_node.record_property_changed(&"color", old_value, target_node.color)
	_inspected_object_updated(target_node)


func _on_size_value_changed(new_value: Vector3) -> void:
	var clamped: Vector3 = new_value.clamp(Vector3.ONE * _MINIMUM_SIZE_METERS, Vector3.INF)
	_shape_size[0] = clamped.x
	_shape_size[1] = clamped.y
	_shape_size[2] = clamped.z
	target_node.shape_size = _shape_size
	_inspected_object_updated(target_node)


func _on_radius_value_changed(new_value: float) -> void:
	new_value = max(new_value, _MINIMUM_SIZE_METERS)
	_shape_size[0] = new_value
	target_node.shape_size = _shape_size
	_inspected_object_updated(target_node)


func _on_height_value_changed(new_value: float) -> void:
	new_value = max(new_value, _MINIMUM_SIZE_METERS)
	_shape_size[1] = new_value
	target_node.shape_size = _shape_size
	_inspected_object_updated(target_node)


func _on_slide_value_changed(new_value: float) -> void:
	_shape_size[3] = new_value
	target_node.shape_size = _shape_size
	_inspected_object_updated(target_node)
