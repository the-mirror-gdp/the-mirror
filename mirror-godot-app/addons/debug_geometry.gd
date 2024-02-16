extends MeshInstance3D


var im := ImmediateMesh.new()
var mat := StandardMaterial3D.new()

var debug_shapes: Array[DebugShape] = []


func _ready() -> void:
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh = im

	process_priority = 1000


func _process(delta: float) -> void:
	_update_geometry_timer(delta)


func _update_geometry_timer(delta: float) -> void:
	_clear_geometry()
	_draw_geometry()
	if not debug_shapes.is_empty():
		var count := debug_shapes.size()
		for i in count:
			var shape := debug_shapes[count - 1 - i]
			shape.draw_time -= delta
			if shape.draw_time < 0.0:
				debug_shapes.remove_at(count - 1 - i)


func _clear_geometry() -> void:
	im.clear_surfaces()


func _draw_geometry(index: int = 0) -> void:
	for i in range(index, debug_shapes.size()):
		var shape := debug_shapes[i]
		_draw_debug_shape(shape)


func _draw_debug_shape(shape: DebugShape) -> void:
	if shape is DebugShapeCompound:
		for sub_shape in shape.debug_shapes:
			_draw_debug_shape(sub_shape)
	else:
		var primitives: Array = []
		if shape.draw_surfaces:
			im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, mat)
			primitives = shape.triangle_primitives
		else:
			im.surface_begin(Mesh.PRIMITIVE_LINES, mat)
			primitives = shape.line_primitives
		im.surface_set_color(shape.color)
		for primitive in primitives:
			for vertex in primitive.vertices:
				im.surface_add_vertex(vertex)
		im.surface_end()


func draw_debug_cube(t: float, p: Transform3D, extents: Vector3, c: Color = Color(0, 0, 0), b_triangles: bool = false) -> void:
	var cube := DebugCube.new(extents)
	cube.position = p.origin
	cube.basis = p.basis
	cube.color = c
	cube.draw_surfaces = b_triangles
	cube.draw_time = t
	debug_shapes.append(cube)
	cube.update_geometry()


func draw_debug_sphere(t: float, p: Vector3, lon: int, lat: int, r: float,
		c: Color = Color(1, 0, 0), b_triangles: bool = false) -> void:
	var sphere := DebugSphere.new(r, lon, lat)
	sphere.position = p
	sphere.color = c
	sphere.draw_surfaces = b_triangles
	sphere.draw_time = t
	debug_shapes.append(sphere)
	sphere.update_geometry()


func draw_debug_cylinder(t: float, p1: Vector3, p2: Vector3, r: float, lon: int = 8, b_caps: bool = true,
		c: Color = Color(0, 0, 0), b_triangles: bool = false) -> void:
	var cylinder := DebugCylinder.new(p1, p2, r, lon)
	cylinder.color = c
	cylinder.draw_caps = b_caps
	cylinder.draw_surfaces = b_triangles
	cylinder.draw_time = t
	debug_shapes.append(cylinder)
	cylinder.update_geometry()


func draw_debug_cone(t: float, p1: Vector3, p2: Vector3, r1: float, r2: float, lon: int = 8,
		b_caps: bool = true, c: Color = Color(0, 0, 0), b_triangles: bool = false) -> void:
	var cone := DebugCone.new(p1, p2, r1, r2, lon)
	cone.color = c
	cone.draw_caps = b_caps
	cone.draw_surfaces = b_triangles
	cone.draw_time = t
	debug_shapes.append(cone)
	cone.update_geometry()


func draw_debug_arrow(t: float, p: Vector3, n: Vector3, s: float = 1.0,
		c: Color = Color(0, 0, 0), b_triangles: bool = true) -> void:
	var arrow := DebugArrow.new(p, n, s)
	arrow.color = c
	arrow.draw_surfaces = b_triangles
	arrow.draw_time = t
	debug_shapes.append(arrow)
	arrow.update_geometry()


func draw_debug_coordinate_system(t: float, p: Vector3, x: Vector3 = Vector3.RIGHT, y: Vector3 = Vector3.UP,
		s: float = 1.0, c: float = 1.0, b_triangles: bool = true) -> void:
	var coordinate_system := DebugCoordinateSystem.new(x, y, s)
	coordinate_system.position = p
	coordinate_system.color_intensity = c
	coordinate_system.draw_surfaces = b_triangles
	coordinate_system.draw_time = t
	debug_shapes.append(coordinate_system)
	coordinate_system.update_geometry()


func draw_debug_grid(t: float, p: Vector3, a: float, b: float, div_a: int, div_b: int,
		normal: Vector3 = Vector3(0, 1, 0), tangent: Vector3 = Vector3(1, 0, 0), color: Color = Color(0, 0, 0)) -> void:
	var grid := DebugGrid.new(a, b, div_a, div_b, normal, tangent)
	grid.position = p
	grid.color = color
	grid.draw_surfaces = false
	grid.draw_time = t
	debug_shapes.append(grid)
	grid.update_geometry()


func draw_debug_line(t: float, p1: Vector3, p2: Vector3, thickness: float, color: Color = Color(0, 0, 0)) -> void:
	var line := DebugLine.new(p1, p2, thickness)
	line.color = color
	line.draw_time = t
	debug_shapes.append(line)
	line.update_geometry()


func draw_debug_point(t: float, p: Vector3, size: float, color: Color = Color(0, 0, 0), b_triangles: bool = true) -> void:
	var point := DebugPoint.new(size)
	point.position = p
	point.color = color
	point.draw_surfaces = b_triangles
	point.draw_time = t
	debug_shapes.append(point)
	point.update_geometry()


class Primitive:
	var vertex_count := 2
	var vertices: Array[Vector3] = [] :
		get:
			while vertices.size() < vertex_count:
				vertices.append(Vector3.ZERO)
			return vertices
		set(array):
			if array.size() > vertex_count:
				vertices = array.slice(0, vertex_count)
			else:
				while array.size() < vertex_count:
					array.append([Vector3.ZERO])
				vertices = array

	func _init(_vertices: Array[Vector3]) -> void:
		vertices = _vertices

class LinePrimitive extends Primitive:
	func _init(_vertices: Array[Vector3]) -> void:
		vertex_count = 2
		super._init(_vertices)

class TrianglePrimitive extends Primitive:
	func _init(_vertices: Array[Vector3]) -> void:
		vertex_count = 3
		super._init(_vertices)

class DebugShape:
	var line_primitives: Array[LinePrimitive] = []
	var triangle_primitives: Array[TrianglePrimitive] = []

	var position := Vector3.ZERO
	var basis := Basis.IDENTITY
	var color := Color(0, 0, 0)
	var draw_surfaces := false
	var draw_time := 0.0

	func _draw_debug_shape() -> void:
		line_primitives.clear()
		triangle_primitives.clear()

	func _to_string() -> String:
		return "DebugShape"

	func add_line_primitive(vertices: Array[Vector3]) -> void:
		line_primitives.append(LinePrimitive.new(vertices))

	func add_triangle_primitive(vertices: Array[Vector3]) -> void:
		triangle_primitives.append(TrianglePrimitive.new(vertices))

	func set_draw_time(time: float) -> void:
		draw_time = time

	func update_geometry() -> void:
		_draw_debug_shape()

class DebugShapeCompound extends DebugShape:
	var debug_shapes: Array[DebugShape] = []

	func _draw_debug_shape() -> void:
		for shape in debug_shapes:
			shape._draw_debug_shape()

	func _to_string() -> String:
		return "DebugShapeCompound"

	func add_debug_shape(shape: DebugShape) -> void:
		debug_shapes.append(shape)

	func set_draw_time(time: float) -> void:
		for shape in debug_shapes:
			shape.set_draw_time(time)

class DebugCube extends DebugShape:
	var extents := Vector3.ONE

	func _init(size: Vector3) -> void:
		extents = size

	func _draw_debug_shape() -> void:
		super()

		var x := extents.x
		var y := extents.y
		var z := extents.z
		var t := Transform3D(basis, position)
		var points := [
				t * (0.5 * Vector3(-x, -y, -z)),
				t * (0.5 * Vector3(-x, -y, z)),
				t * (0.5 * Vector3(-x, y, -z)),
				t * (0.5 * Vector3(-x, y, z)),
				t * (0.5 * Vector3(x, -y, -z)),
				t * (0.5 * Vector3(x, -y, z)),
				t * (0.5 * Vector3(x, y, -z)),
				t * (0.5 * Vector3(x, y, z))]
		if draw_surfaces:
			add_triangle_primitive([points[0], points[2], points[3]])
			add_triangle_primitive([points[3], points[1], points[0]])
			add_triangle_primitive([points[4], points[5], points[7]])
			add_triangle_primitive([points[7], points[6], points[4]])
			add_triangle_primitive([points[0], points[1], points[5]])
			add_triangle_primitive([points[5], points[4], points[0]])
			add_triangle_primitive([points[3], points[2], points[7]])
			add_triangle_primitive([points[7], points[2], points[6]])
			add_triangle_primitive([points[0], points[4], points[2]])
			add_triangle_primitive([points[2], points[4], points[6]])
			add_triangle_primitive([points[1], points[3], points[7]])
			add_triangle_primitive([points[7], points[5], points[1]])
		else:
			add_line_primitive([points[0], points[1]])
			add_line_primitive([points[1], points[3]])
			add_line_primitive([points[3], points[2]])
			add_line_primitive([points[2], points[0]])
			add_line_primitive([points[4], points[5]])
			add_line_primitive([points[5], points[7]])
			add_line_primitive([points[7], points[6]])
			add_line_primitive([points[6], points[4]])
			add_line_primitive([points[0], points[4]])
			add_line_primitive([points[1], points[5]])
			add_line_primitive([points[3], points[7]])
			add_line_primitive([points[2], points[6]])

	func _to_string() -> String:
		return "DebugCube"

class DebugSphere extends DebugShape:
	var longitude := 36 :
		set(value):
			longitude = clampi(value, 0, 72)
	var latitude := 18 :
		set(value):
			latitude = clampi(value, 0, 36)
	var radius := 0.5

	func _init(rad: float, lon: int = 36, lat: int = 18) -> void:
		radius = rad
		longitude = lon
		latitude = lat

	func _draw_debug_shape() -> void:
		super()

		for i in range(1, latitude + 1):
			var lat0 := PI * (-0.5 + (i - 1) / (latitude as float))
			var y0 := sin(lat0)
			var r0 := cos(lat0)
			var lat1 := PI * (-0.5 + i / (latitude as float))
			var y1 := sin(lat1)
			var r1 := cos(lat1)
			for j in range(1, longitude + 1):
				var lon0 := 2 * PI * ((j - 1) / (longitude as float))
				var x0 := cos(lon0)
				var z0 := sin(lon0)
				var lon1 := 2 * PI * (j / (longitude as float))
				var x1 := cos(lon1)
				var z1 := sin(lon1)

				var points := [radius * Vector3(x1 * r0, y0, z1 * r0) + position,
						radius * Vector3(x1 * r1, y1, z1 * r1) + position,
						radius * Vector3(x0 * r1, y1, z0 * r1) + position,
						radius * Vector3(x0 * r0, y0, z0 * r0) + position]

				if draw_surfaces:
					add_triangle_primitive([points[0], points[1], points[2]])
					add_triangle_primitive([points[2], points[3], points[0]])
				else:
					add_line_primitive([points[0], points[1]])
					add_line_primitive([points[1], points[2]])

	func _to_string() -> String:
		return "DebugSphere"

class DebugCone extends DebugShape:
	var longitude := 8
	var radius_top := 0.5
	var radius_base := 0.5
	var base := Vector3.ZERO
	var top := Vector3.ZERO
	var draw_caps := false

	func _init(p1: Vector3, p2: Vector3, r1: float, r2: float, sides: int = 8) -> void:
		base = p1
		top = p2
		radius_base = r1
		radius_top = r2
		longitude = sides

	func _draw_debug_shape() -> void:
		super()

		position = (top + base) / 2
		var height := (top - base).length()
		for i in range(1, longitude + 1):
			var lon0 := 2 * PI * ((i - 1) as float / longitude)
			var x0 := cos(lon0)
			var z0 := sin(lon0)
			var lon1 := 2 * PI * (i as float / longitude)
			var x1 := cos(lon1)
			var z1 := sin(lon1)

			var points := [Vector3(x0 * radius_base, 0, z0 * radius_base),
					Vector3(x0 * radius_top, height, z0 * radius_top),
					Vector3(x1 * radius_base, 0, z1 * radius_base),
					Vector3(x1 * radius_top, height, z1 * radius_top),
					Vector3(0.0, 0, 0.0),
					Vector3(0.0, height, 0.0)]

			var dir := (top - base).normalized()
			var rot := Vector3.RIGHT
			var ang := 0.0
			if dir == Vector3.DOWN:
				ang = PI
			elif dir != Vector3.UP and dir != Vector3.ZERO:
				rot = Vector3.UP.cross(dir).normalized()
				ang = Vector3.UP.angle_to(dir)
			for j in range(points.size()):
				points[j] = points[j].rotated(rot, ang) + base

			if draw_surfaces:
				add_triangle_primitive([points[0], points[2], points[1]])
				add_triangle_primitive([points[1], points[2], points[3]])
				if draw_caps:
					add_triangle_primitive([points[0], points[4], points[2]])
					add_triangle_primitive([points[1], points[3], points[5]])
			else:
				add_line_primitive([points[0], points[1]])
				add_line_primitive([points[1], points[3]])
				add_line_primitive([points[2], points[0]])
				if draw_caps:
					add_line_primitive([points[0], points[4]])
					add_line_primitive([points[1], points[5]])

	func _to_string() -> String:
		return "DebugCone"

class DebugCylinder extends DebugCone:
	func _init(p1: Vector3, p2: Vector3, rad: float, lon: int = 8) -> void:
		super(p1, p2, rad, rad, lon)

	func _to_string() -> String:
		return "DebugCylinder"

class DebugArrow extends DebugShapeCompound:
	var direction := Vector3.ONE
	var length := 1.0

	func _init(pos: Vector3, dir: Vector3, size: float) -> void:
		position = pos
		direction = dir
		length = size

	func _draw_debug_shape() -> void:
		debug_shapes.clear()

		direction = direction.normalized()
		var arrow_end_local := direction * length
		var arrow_body := DebugCylinder.new(
				position, position + 0.8 * arrow_end_local, 0.05 * length, 8)
		arrow_body.color = color
		arrow_body.draw_surfaces = draw_surfaces
		arrow_body.draw_caps = true
		var arrow_tip := DebugCone.new(
				position + 0.8 * arrow_end_local, position + arrow_end_local, 0.1 * length, 0, 8)
		arrow_tip.color = color
		arrow_tip.draw_surfaces = draw_surfaces
		arrow_tip.draw_caps = true
		add_debug_shape(arrow_body)
		add_debug_shape(arrow_tip)

		super()

	func _to_string() -> String:
		return "DebugArrow"

class DebugCoordinateSystem extends DebugShapeCompound:
	var size := 1.0
	var dir_x := Vector3.RIGHT
	var dir_y := Vector3.UP
	var color_intensity := 1.0

	func _init(x: Vector3 = Vector3.RIGHT, y: Vector3 = Vector3.UP, s: float = 1.0) -> void:
		dir_x = x
		dir_y = y
		size = s

	func _draw_debug_shape() -> void:
		debug_shapes.clear()

		dir_x = dir_x.normalized()
		var dir_z = dir_x.cross(dir_y).normalized()
		dir_y = dir_z.cross(dir_x).normalized()

		color_intensity = clamp(color_intensity, 0, 10)
		var arrow_x := DebugArrow.new(position, dir_x, size)
		var arrow_y := DebugArrow.new(position, dir_y, size)
		var arrow_z := DebugArrow.new(position, dir_z, size)
		arrow_x.draw_surfaces = draw_surfaces
		arrow_y.draw_surfaces = draw_surfaces
		arrow_z.draw_surfaces = draw_surfaces
		arrow_x.color = Color(color_intensity, 0, 0)
		arrow_y.color = Color(0, color_intensity, 0)
		arrow_z.color = Color(0, 0, color_intensity)
		add_debug_shape(arrow_x)
		add_debug_shape(arrow_y)
		add_debug_shape(arrow_z)

		super()

	func _to_string() -> String:
		return "DebugCoordinateSystem"

class DebugGrid extends DebugShape:
	var length := 5.0
	var width := 5.0
	var length_divs := 6 :
		set(value):
			length_divs = 1 if value < 1 else value
	var width_divs := 6 :
		set(value):
			width_divs = 1 if value < 1 else value
	var normal_direction := Vector3(0, 1, 0)
	var tangent_direction := Vector3(1, 0, 0)

	func _init(a: float, b: float, div_a: int, div_b: int,
			normal: Vector3 = Vector3(0, 1, 0), tangent: Vector3 = Vector3(1, 0, 0)) -> void:
		length = a
		width = b
		length_divs = div_a
		width_divs = div_b
		normal_direction = normal
		tangent_direction = tangent

	func _draw_debug_shape() -> void:
		super()

		if tangent_direction == normal_direction:
			tangent_direction = Vector3.RIGHT

		var normal_rotation := Vector3.RIGHT
		var normal_angle := 0.0
		if normal_direction == Vector3.DOWN:
			normal_angle = PI
		elif normal_direction != Vector3.UP and normal_direction != Vector3.ZERO:
			normal_rotation = Vector3.UP.cross(normal_direction).normalized()
			normal_angle = Vector3.UP.angle_to(normal_direction)
			if normal_direction.cross(Vector3.UP).normalized() == -normal_direction.normalized():
				normal_angle = -normal_angle
		var rotated_right_vector := Vector3.RIGHT.rotated(normal_rotation, normal_angle)
		var tangent_rotation := normal_direction.normalized()
		var projection := tangent_direction - tangent_direction.dot(normal_direction) / normal_direction.length_squared() * normal_direction
		var tangent_angle := rotated_right_vector.angle_to(projection)
		if rotated_right_vector.cross(projection).normalized() != normal_direction.normalized():
			tangent_angle = -tangent_angle

		for i in range(0, length_divs + 1):
			var lx := length * (i as float / length_divs - 0.5)
			add_line_primitive([Vector3(lx, 0, -width / 2.0).rotated(normal_rotation, normal_angle).rotated(
					tangent_rotation, tangent_angle) + position,
					Vector3(lx, 0, width / 2.0).rotated(normal_rotation, normal_angle).rotated(
					tangent_rotation, tangent_angle) + position])
		for j in range(0, width_divs + 1):
			var lz := width * (j as float / width_divs - 0.5)
			add_line_primitive([Vector3(-length / 2.0, 0, lz).rotated(normal_rotation, normal_angle).rotated(
					tangent_rotation, tangent_angle) + position,
					Vector3(length / 2.0, 0, lz).rotated(normal_rotation, normal_angle).rotated(
					tangent_rotation, tangent_angle) + position])

	func _to_string() -> String:
		return "DebugGrid"

class DebugLine extends DebugCylinder:
	var line_thickness := 0.0

	func _init(p1: Vector3, p2: Vector3, thickness: float) -> void:
		super(p1, p2, thickness, 8)
		base = p1
		top = p2
		line_thickness = thickness

	func _draw_debug_shape() -> void:
		if line_thickness <= 0.0:
			draw_surfaces = false
			add_line_primitive([base, top])
		else:
			draw_surfaces = true
			super()

	func _to_string() -> String:
		return "DebugLine"

class DebugPoint extends DebugSphere:
	func _init(size: float) -> void:
		super(size / 2, 8, 4)
		if size < 0.005:
			radius = 0.005

	func _draw_debug_shape() -> void:
		super()

	func _to_string() -> String:
		return "DebugPoint"
