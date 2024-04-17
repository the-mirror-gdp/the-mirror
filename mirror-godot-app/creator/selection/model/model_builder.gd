class_name ModelBuilder
extends Node


signal settings_changed
signal state_changed(state)
signal placement_finished
signal placement_failed
signal request_primitive_placement(new_primitive: ModelPrimitive)

enum State { DISABLED = 0, SELECT = 1, DRAG = 2, EXTRUDE = 3, SLIDE = 4 }

const GHOST_OPACITY := 0.5
const OUTLINE_MARGIN := 0.0005
const GRID_SIZES: Array = [0.125, 0.25, 0.5, 1.0, 2.0, 4.0, 8.0]

var model_primitive_type: ModelPrimitive.ShapeType = ModelPrimitive.ShapeType.BOX
var grid_size_index: int
var model_primitive_color: Color
var placement_ghost: ModelPrimitive = null

var _state: State = State.SELECT
var _start: Vector3
var _end: Vector3
var _extrude_base: Vector3
var _plane := Plane()
var _bounds: AABB
var _slide_axis: Vector3
var _slide_amount: float
var _ghost_color = Color.BLUE
var _raycast_dict: Dictionary

@onready var _label_x: Label = $X
@onready var _label_y: Label = $Y
@onready var _label_z: Label = $Z
@onready var _grid_plane: ModelGridPlane = $ModelGridPlane


func _ready() -> void:
	placement_ghost = ModelPrimitive.new()
	placement_ghost.name = "PlacementGhost"
	add_child(placement_ghost)
	placement_ghost.hide()
	set_model_primitive_type(ModelPrimitive.ShapeType.BOX)
	set_model_primitive_color(Color.WHITE)
	set_grid_size(2)
	_set_state(State.DISABLED)


func set_model_builder_enabled(is_enabled: bool) -> void:
	if is_enabled:
		_set_state(State.SELECT)
	else:
		_set_state(State.DISABLED)
	settings_changed.emit()


func set_model_primitive_type(new_type: ModelPrimitive.ShapeType) -> void:
	model_primitive_type = new_type
	settings_changed.emit()


func set_grid_size(new_index: int) -> void:
	grid_size_index = new_index
	settings_changed.emit()


func set_model_primitive_color(new_color: Color) -> void:
	model_primitive_color = new_color
	placement_ghost.color = Color(model_primitive_color, 0.5)
	settings_changed.emit()


func is_currently_modeling() -> bool:
	return _state > State.SELECT


func _unhandled_input(input_event: InputEvent) -> void:
	if _state == State.DISABLED:
		return
	if input_event.is_action_pressed(&"action_deselect") and (_state != State.SELECT):
		_set_state(State.SELECT)
		get_viewport().set_input_as_handled()
	if (
		_state == State.SELECT
		and input_event.is_action_pressed(&"primary_action")
		and not Input.is_action_pressed(&"secondary_action")
		and not _raycast_dict.is_empty()
	):
		_set_state(State.DRAG)


func _process(_delta) -> void:
	if _state == State.DISABLED:
		return
	var local_player = PlayerData.get_local_player()
	_raycast_dict = local_player.camera_get_raycast_dict() if local_player else {}
	_bounds.position = _start
	_bounds.end = _end
	match _state:
		State.SELECT:
			_select()
			_grid_plane.update_rotation()
		State.DRAG:
			_drag()
		State.EXTRUDE:
			_extrude()
		State.SLIDE:
			_slide()
	_grid_plane.update_position(_end)
	_grid_plane.update_grid_scale(_get_grid_size_float())
	_draw_outlines()
	_draw_text()
	_draw_placement_ghost()


func _select() -> void:
	if not _raycast_dict.has("position"):
		return
	_start = _snap_to_grid(_raycast_dict["position"] - _get_grid_size_vector() / 2)
	_end = _start
	_plane = Plane(_grid_plane.get_up_axis(), _start)
	_slide_amount = 0.5


func _drag() -> void:
	_end = _snap_to_grid(_plane_intersection_from_mouse(_plane) - _get_grid_size_vector() / 2)
	if Input.is_action_pressed(&"primary_action"):
		return
	if _start.is_equal_approx(_end):
		placement_failed.emit()
		_set_state(State.SELECT)
		return
	_extrude_base = _end
	_set_state(State.EXTRUDE)


func _extrude() -> void:
	_end = _line_intersection_from_mouse(_extrude_base, _plane.normal)
	_end = _end.snapped(_get_grid_size_vector())
	if not Input.is_action_just_pressed(&"primary_action"):
		return
	if model_primitive_type == ModelPrimitive.ShapeType.TRIANGLE:
		if _plane.normal.abs().max_axis_index() == Vector3.AXIS_X:
			_slide_axis = Vector3.BACK
		else:
			_slide_axis = Vector3.RIGHT
		_set_state(State.SLIDE)
	else:
		_set_state(State.SELECT)
		_finalize()


func _slide() -> void:
	var slide_vector: Vector3 = _line_intersection_from_mouse(_end, _slide_axis)
	slide_vector -= _end
	if _slide_axis.x == 1.0:
		_slide_amount = slide_vector.x / absf(_bounds.size.x)
		if _bounds.size.x > 0:
			_slide_amount += 1.0
	else:
		_slide_amount = -slide_vector.z / absf(_bounds.size.z)
		if _bounds.size.z < 0:
			_slide_amount += 1.0
	_slide_amount = snappedf(_slide_amount, 0.25)
	if Input.is_action_just_pressed(&"primary_action"):
		_set_state(State.SELECT)
		_finalize()


func _finalize() -> void:
	if is_zero_approx(_bounds.get_volume()):
		placement_failed.emit()
		return
	placement_finished.emit()
	_place()


func _place() -> void:
	var model_primitive = ModelPrimitive.new()
	_update_model_primitive_with_current_data(model_primitive)
	request_primitive_placement.emit(model_primitive)


func _update_model_primitive_with_current_data(model_primitive: ModelPrimitive) -> void:
	var plane_axis: int = _plane.normal.abs().max_axis_index()
	var bounds_abs = _bounds.abs()
	var bounds_size: Vector3 = bounds_abs.size
	if model_primitive_type != ModelPrimitive.ShapeType.BOX:
		# Swizzle the size values depending on the plane axis, so that we can
		# give consistent data to the shapes. Except: Not for the box shape.
		match plane_axis:
			Vector3.AXIS_X:
				# For X, X=Z, Y=X, Z=Y (imagine "spinning" around Vector3.ONE)
				var extrusion_size: float = bounds_size.x
				bounds_size.x = bounds_size.z
				bounds_size.z = bounds_size.y
				bounds_size.y = extrusion_size
			Vector3.AXIS_Z:
				# For Z, swap Y and Z (image "tilting" around X)
				var extrusion_size: float = bounds_size.z
				bounds_size.z = bounds_size.y
				bounds_size.y = extrusion_size
	var size_array := PackedFloat64Array()
	if model_primitive_type == ModelPrimitive.ShapeType.BOX or model_primitive_type == ModelPrimitive.ShapeType.TRIANGLE:
		size_array.append(bounds_size.x)
		size_array.append(bounds_size.y)
		size_array.append(bounds_size.z)
		if model_primitive_type == ModelPrimitive.ShapeType.TRIANGLE:
			size_array.append(_slide_amount)
	elif model_primitive_type == ModelPrimitive.ShapeType.SPHERE:
		# The radius size is for the radius of capsules/cylinders/cones,
		# For spheres we skip this and use the extrusion size as the radius.
		size_array.append(bounds_size.y * 0.5)
	else: # Capsule, cylinder, cone.
		var radius_size: float = minf(bounds_size.x, bounds_size.z) * 0.5
		size_array.append(radius_size)
		size_array.append(bounds_size.y)
	model_primitive.setup_primitive_shape(model_primitive_type, size_array)
	model_primitive.color = model_primitive_color
	var prim_global_transform := Transform3D(Basis.IDENTITY, bounds_abs.get_center())
	if model_primitive_type != ModelPrimitive.ShapeType.BOX and model_primitive_type != ModelPrimitive.ShapeType.SPHERE:
		prim_global_transform.basis = _get_desired_block_rotation(plane_axis, model_primitive_type)
	# When placing a primitive, this data will be re-interpreted as the global transform.
	model_primitive.transform = prim_global_transform


## Gets the desired rotation Basis for a primitive type that has orientation.
## The returned Basis has the up vector pointing in the plane axis direction.
func _get_desired_block_rotation(plane_axis: int, model_primitive_type: ModelPrimitive.ShapeType) -> Basis:
	var is_directional: bool = model_primitive_type == ModelPrimitive.ShapeType.CONE \
			or model_primitive_type == ModelPrimitive.ShapeType.TRIANGLE
	match plane_axis:
		Vector3.AXIS_X:
			if is_directional and _bounds.size.x < 0.0:
				return Basis(Vector3.FORWARD, Vector3.LEFT, Vector3.UP)
			else:
				return Basis(Vector3.FORWARD, Vector3.RIGHT, Vector3.DOWN)
		Vector3.AXIS_Y:
			if is_directional and _bounds.size.y < 0.0:
				return Basis(Vector3.RIGHT, Vector3.DOWN, Vector3.FORWARD)
			else:
				return Basis.IDENTITY # RIGHT, UP, BACK
		Vector3.AXIS_Z:
			if is_directional and _bounds.size.z < 0.0:
				return Basis(Vector3.RIGHT, Vector3.FORWARD, Vector3.UP)
			else:
				return Basis(Vector3.RIGHT, Vector3.BACK, Vector3.DOWN)
	return Basis.IDENTITY


func _draw_outlines() -> void:
	match _state:
		State.EXTRUDE:
			_ghost_color = Color.BLUE_VIOLET
			GameUI.instance.object_outlines.draw_line(_end - _plane.normal * 100, _end + _plane.normal * 100, Color.RED)
		State.SLIDE:
			_ghost_color = Color.VIOLET
			GameUI.instance.object_outlines.draw_line(_end - _slide_axis * 100, _end + _slide_axis * 100, Color.RED)
		_:
			_ghost_color = Color.BLUE
	GameUI.instance.object_outlines.draw_wireframe_box_aabb(_bounds.grow(OUTLINE_MARGIN), _ghost_color)


func _draw_text() -> void:
	if _state == State.SELECT:
		_label_x.text = ""
		_label_y.text = ""
		_label_z.text = ""
		return
	var bounds_abs := _bounds.abs()
	var camera = PlayerData.get_local_player().camera_get_viewport().get_camera_3d()
	_label_x.position = camera.unproject_position(bounds_abs.get_center() + Vector3.FORWARD * bounds_abs.size.z / 2)
	_label_y.position = camera.unproject_position(_end)
	_label_z.position = camera.unproject_position(bounds_abs.get_center() + Vector3.RIGHT * bounds_abs.size.x / 2)
	_label_x.text = "X:" + str(snapped(bounds_abs.size.x, _get_grid_size_float()))
	_label_y.text = "Y:" + str(snapped(bounds_abs.size.y, _get_grid_size_float()))
	_label_z.text = "Z:" + str(snapped(bounds_abs.size.z, _get_grid_size_float()))


func _draw_placement_ghost() -> void:
	if _state == State.SELECT:
		placement_ghost.hide()
		return
	placement_ghost.show()
	_update_model_primitive_with_current_data(placement_ghost)
	placement_ghost.color.a *= GHOST_OPACITY


func _set_state(state: State) -> void:
	_state = state
	state_changed.emit(state)
	placement_ghost.visible = _state > State.SELECT
	if _state == State.SELECT or _state == State.DRAG:
		_grid_plane.show()
	else:
		_grid_plane.hide()
		return
	_draw_outlines()
	_draw_text()
	_draw_placement_ghost()


func _snap_to_grid(position: Vector3) -> Vector3:
	return Util.get_snapped_position(position, _get_grid_size_float())


func _get_grid_size_float() -> float:
	return GRID_SIZES[grid_size_index]


func _get_grid_size_vector() -> Vector3:
	return Vector3.ONE * GRID_SIZES[grid_size_index]


func _plane_intersection_from_mouse(plane: Plane) -> Vector3:
	var player_viewport = PlayerData.get_local_player().camera_get_viewport()
	var ray: Dictionary = Util.create_ray_from_mouse_click(player_viewport)
	var intersection = plane.intersects_ray(ray.origin, ray.normal)
	if intersection:
		return intersection
	return Vector3.ZERO


func _line_intersection_from_mouse(line_position: Vector3, line_normal: Vector3) -> Vector3:
	var player_viewport = PlayerData.get_local_player().camera_get_viewport()
	var ray: Dictionary = Util.create_ray_from_mouse_click(player_viewport)
	# https://math.stackexchange.com/questions/1993953/closest-points-between-two-lines
	var pos_diff = line_position - ray.origin
	var cross_normal = line_normal.cross(ray.normal).normalized()
	var rejection = pos_diff - pos_diff.project(ray.normal) - pos_diff.project(cross_normal)
	var distance_to_line_pos = rejection.length() / line_normal.dot(rejection.normalized())
	var closest_approach = line_position - line_normal * distance_to_line_pos
	return closest_approach
