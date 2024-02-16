class_name ModelPrimitive
extends JBody3D


signal node_property_changed(object_node: ModelPrimitive, property_name: StringName, old_value: Variant, new_value: Variant)
signal scale_applied()

enum ShapeType {
	NONE = 0,
	BOX = 1,
	SPHERE = 2,
	CAPSULE = 3,
	CYLINDER = 4,
	CONE = 5,
	TRIANGLE = 6,
}

var color: Color = Color.WHITE:
	set(value):
		color = value
		_set_mesh_material()

var shape_type: ShapeType:
	get:
		return _shape_type
	set(value):
		record_property_changed(&"shape_type", _shape_type, value)
		_shape_type = value
		_update_shape()

var shape_size: PackedFloat64Array:
	get:
		return _shape_size.duplicate()
	set(value):
		record_property_changed(&"shape_size", _shape_size.duplicate(), value.duplicate())
		_shape_size = value.duplicate()
		_update_shape()

var _shape_type: ShapeType = ShapeType.NONE
var _shape_size: PackedFloat64Array = PackedFloat64Array()
var _mesh_instance: MeshInstance3D = null
var _material: StandardMaterial3D = null


func duplicate_model_primitive() -> ModelPrimitive:
	var ret = ModelPrimitive.new()
	ret.setup_primitive_shape(_shape_type, _shape_size)
	ret.color = color
	ret.transform = transform
	ret.name = name + " copy"
	return ret


func _init() -> void:
	set_layer_name(&"STATIC")
	body_mode = JBody3D.STATIC


## Only used by the GLTF exporter. Returns the actual Dictionary that will
## be written to the node's extensions (so, size is an array, not a vector).
func serialize_to_mi_model_gltf_extension() -> Dictionary:
	var mi_model_ext: Dictionary = {
		"color": Serialization.color_to_array(color)
	}
	if shape is JConvexHullShape3D:
		if _shape_type == ShapeType.CONE:
			mi_model_ext["shape"] = "cone"
		elif _shape_type == ShapeType.TRIANGLE:
			mi_model_ext["shape"] = "triangle"
		mi_model_ext["size"] = Array(_shape_size)
	return mi_model_ext


## Used when importing data from a node tree that was imported from a GLTF.
func setup_primitive_shape_from_gltf_shape_and_mi_model_meta(gltf_shape: GLTFPhysicsShape, mi_model_meta: Dictionary) -> void:
	var shape_type: String = gltf_shape.shape_type
	if shape_type == "box":
		setup_primitive_shape(ShapeType.BOX, Serialization.vector3_to_array(gltf_shape.size))
	elif shape_type == "sphere":
		setup_primitive_shape(ShapeType.SPHERE, [gltf_shape.radius])
	elif shape_type == "capsule":
		setup_primitive_shape(ShapeType.CAPSULE, [gltf_shape.radius, gltf_shape.height])
	elif shape_type == "cylinder":
		setup_primitive_shape(ShapeType.CYLINDER, [gltf_shape.radius, gltf_shape.height])
	elif shape_type == "convex":
		# In most cases we want to use the collision shape resource for the
		# shape information, but that only works for standardized shapes.
		# For non-standard shapes like cones and triangles we use our metadata.
		var dict_shape_type: ShapeType = mi_model_meta["shape"]
		var dict_shape_size: PackedFloat64Array = mi_model_meta["size"]
		setup_primitive_shape(dict_shape_type, dict_shape_size)
	else:
		setup_primitive_shape(ShapeType.NONE, _shape_size)
	color = mi_model_meta["color"]


func setup_primitive_shape_from_resource_and_mi_model_meta(shape_resource: Shape3D, mi_model_meta: Dictionary) -> void:
	if shape_resource is BoxShape3D:
		setup_primitive_shape(ShapeType.BOX, Serialization.vector3_to_array(shape_resource.size))
	elif shape_resource is SphereShape3D:
		setup_primitive_shape(ShapeType.SPHERE, [shape_resource.radius])
	elif shape_resource is CapsuleShape3D:
		setup_primitive_shape(ShapeType.CAPSULE, [shape_resource.radius, shape_resource.height])
	elif shape_resource is CylinderShape3D:
		setup_primitive_shape(ShapeType.CYLINDER, [shape_resource.radius, shape_resource.height])
	elif shape_resource is ConvexPolygonShape3D:
		# In most cases we want to use the collision shape resource for the
		# shape information, but that only works for standardized shapes.
		# For non-standard shapes like cones and triangles we use our metadata.
		var dict_shape_type: ShapeType = mi_model_meta["shape"]
		var dict_shape_size: PackedFloat64Array = mi_model_meta["size"]
		setup_primitive_shape(dict_shape_type, dict_shape_size)
	else:
		setup_primitive_shape(ShapeType.NONE, _shape_size)
	color = mi_model_meta["color"]


## Used above and also used directly by the block tool editor.
func setup_primitive_shape(type: ShapeType, size: PackedFloat64Array) -> void:
	_shape_type = type
	_shape_size = size
	_update_node_names()
	_update_shape()


## Used above and also used directly by the block tool editor.
func _update_node_names() -> void:
	if not _mesh_instance:
		_mesh_instance = MeshInstance3D.new()
		add_child(_mesh_instance)
	match _shape_type:
		ShapeType.NONE:
			_mesh_instance.name = &"EmptyMesh"
			name = &"EmptyPrimitive"
		ShapeType.BOX:
			_mesh_instance.name = &"BoxMesh"
			name = &"BoxPrimitive"
		ShapeType.SPHERE:
			_mesh_instance.name = &"SphereMesh"
			name = &"SpherePrimitive"
		ShapeType.CAPSULE:
			_mesh_instance.name = &"CapsuleMesh"
			name = &"CapsulePrimitive"
		ShapeType.CYLINDER:
			_mesh_instance.name = &"CylinderMesh"
			name = &"CylinderPrimitive"
		ShapeType.CONE:
			_mesh_instance.name = &"ConeMesh"
			name = &"ConePrimitive"
		ShapeType.TRIANGLE:
			_mesh_instance.name = &"TrianglePrismMesh"
			name = &"TrianglePrismPrimitive"


## Used by setup_primitive_shape and also used in the properties.
func _update_shape() -> void:
	match _shape_type:
		ShapeType.NONE:
			_mesh_instance.mesh = null
			shape = null
		ShapeType.BOX:
			var size: Vector3 = Vector3(_shape_size[0], _shape_size[1], _shape_size[2])
			_mesh_instance.mesh = BoxMesh.new()
			_mesh_instance.mesh.size = size
			shape = JBoxShape3D.new()
			shape.size = size
		ShapeType.SPHERE:
			var radius: float = _shape_size[0]
			_mesh_instance.mesh = SphereMesh.new()
			_mesh_instance.mesh.radius = radius
			# Why does a sphere mesh have height? Good question!
			_mesh_instance.mesh.height = radius * 2.0
			shape = JSphereShape3D.new()
			shape.radius = radius
		ShapeType.CAPSULE:
			var radius: float = _shape_size[0]
			var height: float = _shape_size[1]
			_mesh_instance.mesh = CapsuleMesh.new()
			_mesh_instance.mesh.radius = radius
			_mesh_instance.mesh.height = height
			shape = JCapsuleShape3D.new()
			shape.radius = radius
			shape.height = height
		ShapeType.CYLINDER:
			var radius: float = _shape_size[0]
			var height: float = _shape_size[1]
			_mesh_instance.mesh = CylinderMesh.new()
			_mesh_instance.mesh.bottom_radius = radius
			_mesh_instance.mesh.top_radius = radius
			_mesh_instance.mesh.height = height
			shape = JCylinderShape3D.new()
			shape.radius = radius
			shape.height = height
		ShapeType.CONE:
			var radius: float = _shape_size[0]
			var height: float = _shape_size[1]
			_mesh_instance.mesh = CylinderMesh.new()
			_mesh_instance.mesh.bottom_radius = radius
			_mesh_instance.mesh.top_radius = 0.0
			_mesh_instance.mesh.height = height
			var godot_shape: ConvexPolygonShape3D = _mesh_instance.mesh.create_convex_shape()
			var jolt_shape := JConvexHullShape3D.new()
			jolt_shape.points = godot_shape.points
			shape = jolt_shape
		ShapeType.TRIANGLE:
			var size: Vector3 = Vector3(_shape_size[0], _shape_size[1], _shape_size[2])
			var left_to_right: float = _shape_size[3]
			_mesh_instance.mesh = PrismMesh.new()
			_mesh_instance.mesh.size = size
			_mesh_instance.mesh.left_to_right = left_to_right
			var godot_shape: ConvexPolygonShape3D = _mesh_instance.mesh.create_convex_shape()
			var jolt_shape := JConvexHullShape3D.new()
			jolt_shape.points = godot_shape.points
			shape = jolt_shape


func _set_mesh_material() -> void:
	if not _mesh_instance:
		return
	_material = StandardMaterial3D.new()
	_material.albedo_color = color
	if color.a < 1:
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mesh_instance.set_surface_override_material(0, _material)


## Constrains the given scale. This is required to be separate from the
## apply_scale() method so that the undo/redo system can get a constrained value.
func apply_scale_constraint(delta_scale: Vector3) -> Vector3:
	var size_count: int = _shape_size.size()
	if size_count == 1:
		# The scale must be uniform for shapes with only one size number (sphere).
		if delta_scale.x > 1.0001 or delta_scale.y > 1.0001 or delta_scale.z > 1.0001:
			delta_scale = Vector3.ONE * maxf(delta_scale.x, maxf(delta_scale.y, delta_scale.z))
		else:
			delta_scale = Vector3.ONE * minf(delta_scale.x, minf(delta_scale.y, delta_scale.z))
	elif size_count == 2:
		# The scale must be uniform on X and Z for shapes with
		# a horizontal radius and a height (capsule, cylinder, cone).
		if delta_scale.x > 1.0001 or delta_scale.z > 1.0001:
			delta_scale.x = maxf(delta_scale.x, delta_scale.z)
		else:
			delta_scale.x = minf(delta_scale.x, delta_scale.z)
		delta_scale.z = delta_scale.x
	return delta_scale


## Applies scale changes to the shape, so that we can keep the node unscaled.
## Expects that the input is properly constrained by apply_scale_constraint().
func apply_scale(delta_scale: Vector3) -> void:
	var size_count: int = _shape_size.size()
	if size_count > 0:
		_shape_size[0] *= delta_scale.x
		if size_count > 1:
			_shape_size[1] *= delta_scale.y
			if size_count > 2:
				_shape_size[2] *= delta_scale.z
				# If more than 2, don't touch them (ex: triangle slide).
	_update_shape()
	scale_applied.emit()


func record_property_changed(property_name: StringName, old_value: Variant, new_value: Variant) -> void:
	node_property_changed.emit(self, property_name, old_value, new_value)


func scene_hierarchy_delete() -> void:
	queue_free()


func grab() -> void:
	set_layer_name(&"NO_COLLIDE")


func release() -> void:
	set_layer_name(&"STATIC")
