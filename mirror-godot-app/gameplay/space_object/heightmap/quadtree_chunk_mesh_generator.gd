@tool
class_name QuadTreeChunkMeshGenerator
extends MeshInstance3D

## This is only used for previewing inside Godot Editor as a debug tool
@export var generate := false:
	set(v):
		generate_mesh()

## Number of "quads" inside generated chunk. Take a look at wireframe view
@export var resolution := 8
## Height and Width of generated chunk in meters
@export var size := 8.0

enum PERMUTATION {
	NONE,
	TOP,
	RIGHT,
	BOTTOM,
	LEFT,
	TOP_RIGHT,
	RIGHT_BOTTOM,
	BOTTOM_LEFT,
	LEFT_TOP,
	MAX
}

@export var permutation: PERMUTATION = PERMUTATION.NONE;

func generate_mesh() -> Mesh:

	var new_mesh := ArrayMesh.new()
	var verts := PackedVector3Array()
	var indices := PackedInt32Array()
	var tangets := PackedFloat32Array()
	var resolution_v = resolution + 1

	verts.resize(resolution_v*resolution_v)
	tangets.resize(resolution_v*resolution_v*4)

	# generate vertices
	for y in resolution_v:
		for x in resolution_v:
			var index = y * resolution_v + x
			verts[index] = (Vector3(float(x) / resolution * size - size/2.0, 0.0, float(y) / resolution * size  - size/2.0))
			tangets[index * 4] = 1
			tangets[index * 4 + 1] = 0
			tangets[index * 4 + 2] = 0
			tangets[index * 4 + 3] = 1

	# generate indices
	var full_indices_x = range(0, resolution)
	var full_indices_y = range(0, resolution)
	match permutation:
		PERMUTATION.TOP:
			full_indices_y = range(1, resolution)
		PERMUTATION.RIGHT:
			full_indices_x = range(0, resolution -1)
		PERMUTATION.BOTTOM:
			full_indices_y = range(0, resolution-1)
		PERMUTATION.LEFT:
			full_indices_x = range(1, resolution)
		PERMUTATION.TOP_RIGHT:
			full_indices_y = range(1, resolution)
			full_indices_x = range(0, resolution -1)
		PERMUTATION.RIGHT_BOTTOM:
			full_indices_x = range(0, resolution -1)
			full_indices_y = range(0, resolution -1)
		PERMUTATION.BOTTOM_LEFT:
			full_indices_y = range(0, resolution -1)
			full_indices_x = range(1, resolution)
		PERMUTATION.LEFT_TOP:
			full_indices_y = range(1, resolution)
			full_indices_x = range(1, resolution)

	for y in full_indices_y:
		for x in full_indices_x:
			if (x +y) % 2 == 0:
				indices.append(x + y*resolution_v)
				indices.append(x + 1 + y*resolution_v)
				indices.append(x + (y+1)*resolution_v)

				indices.append(x + 1 + (y+1)*resolution_v)
				indices.append(x + (y+1)*resolution_v)
				indices.append(x + 1 + y*resolution_v)
			else:
				indices.append(x + y*resolution_v)
				indices.append(x + 1 + y*resolution_v)
				indices.append(x+1 + (y+1)*resolution_v)

				indices.append(x + 1 + (y+1)*resolution_v)
				indices.append(x + (y+1)*resolution_v)
				indices.append(x + y*resolution_v)
	var lower_res_fragment_top = func():
		for x in range(0,resolution,2):
			indices.append(x + 0*resolution_v)
			indices.append(x + 2 + 0*resolution_v)
			indices.append(x + 1 + (0+1)*resolution_v)
		#from inside - we create standard grid
		for x in range(1,resolution - 1,2):
			indices.append(x + (0+1)*resolution_v)
			indices.append(x + 1 + 0*resolution_v)
			indices.append(x + 1 + (0+1)*resolution_v)

			indices.append(x + 1 + 0*resolution_v)
			indices.append(x + 2 + (0+1)*resolution_v)
			indices.append(x + 1 + (0+1)*resolution_v)

	var lower_res_fragment_right = func():
		for y in range(0,resolution,2):
			indices.append(resolution_v - 1 + y*resolution_v)
			indices.append(resolution_v - 1 + (y+2)*resolution_v)
			indices.append(resolution_v - 2 + (y+1)*resolution_v)
		for y in range(1,resolution - 1,2):
			indices.append(resolution_v - 2 + y*resolution_v)
			indices.append(resolution_v - 1 + (y+1)*resolution_v)
			indices.append(resolution_v - 2 + (y+1)*resolution_v)

			indices.append(resolution_v - 1 + (y+1)*resolution_v)
			indices.append(resolution_v - 2 + (y+2)*resolution_v)
			indices.append(resolution_v - 2 + (y+1)*resolution_v)

	var lower_res_fragment_bottom = func():
		for x in range(0,resolution,2):
			indices.append(x + (resolution_v - 1)*resolution_v)
			indices.append(x + 1 + (resolution_v - 2)*resolution_v)
			indices.append(x + 2 + (resolution_v - 1)*resolution_v)
		#from inside - we create standard grid
		for x in range(1,resolution - 1,2):
			indices.append(x + (resolution_v - 2)*resolution_v)
			indices.append(x + 1 + (resolution_v - 2)*resolution_v)
			indices.append(x + 1 + (resolution_v - 1)*resolution_v)

			indices.append(x + 1 + (resolution_v - 2)*resolution_v)
			indices.append(x + 2 + (resolution_v - 2)*resolution_v)
			indices.append(x + 1 + (resolution_v - 1)*resolution_v)

	var lower_res_fragment_left = func():
		for y in range(0,resolution,2):
			indices.append(0 + y*resolution_v)
			indices.append(1 + (y+1)*resolution_v)
			indices.append(0+ (y+2)*resolution_v)
		for y in range(1,resolution - 1,2):
			indices.append(1 + (y)*resolution_v)
			indices.append(1+ (y+1)*resolution_v)
			indices.append(0 + (y+1)*resolution_v)

			indices.append(1 + (y+1)*resolution_v)
			indices.append(1+ (y+2)*resolution_v)
			indices.append(0 + (y+1)*resolution_v)

	# add lower resolution fragments according to permutation
	match permutation:
		#TOP
		PERMUTATION.TOP:
			lower_res_fragment_top.call()
		PERMUTATION.LEFT_TOP:
			lower_res_fragment_top.call()
			lower_res_fragment_left.call()
		PERMUTATION.TOP_RIGHT:
			lower_res_fragment_top.call()
			lower_res_fragment_right.call()
		PERMUTATION.RIGHT:
			lower_res_fragment_right.call()
		PERMUTATION.RIGHT_BOTTOM:
			lower_res_fragment_right.call()
			lower_res_fragment_bottom.call()
		PERMUTATION.BOTTOM:
			lower_res_fragment_bottom.call()
		PERMUTATION.BOTTOM_LEFT:
			lower_res_fragment_bottom.call()
			lower_res_fragment_left.call()
		PERMUTATION.LEFT:
			lower_res_fragment_left.call()


	# TOP ^^^ LEFT
	var corner_low_res_top_left = func():
		indices.append(0 + 0*resolution_v)
		indices.append(0 + 1 + (0+1)*resolution_v)
		indices.append(0 + (0+1)*resolution_v)

	# TOP ^^^ RIGHT
	var corner_low_res_top_right = func():
		indices.append(resolution_v - 1 + (0)*resolution_v)
		indices.append(resolution_v - 1 + (0+1)*resolution_v)
		indices.append(resolution_v - 2 + (0+1)*resolution_v)

	# RIGHT >>> TOP
	var corner_low_res_right_top = func():
		indices.append(resolution_v - 1 + 0*resolution_v)
		indices.append(resolution_v - 2 + (1)*resolution_v)
		indices.append(resolution_v - 2 + 0*resolution_v)

	# RIGHT >>> BOTTOM
	var corner_low_res_right_bottom = func():
		indices.append(resolution_v - 2 + (resolution_v - 2)*resolution_v)
		indices.append(resolution_v - 1 + (resolution_v - 1)*resolution_v)
		indices.append(resolution_v - 2 + (resolution_v - 1)*resolution_v)

	# BOTTOM ___ RIGHT
	var corner_low_res_bottom_right = func():
		indices.append(resolution_v - 2 + (resolution_v - 2)*resolution_v)
		indices.append(resolution_v - 1 + (resolution_v - 2)*resolution_v)
		indices.append(resolution_v - 1 + (resolution_v - 1)*resolution_v)

	# BOTTOM ___ LEFT
	var corner_low_res_bottom_left = func():
		indices.append(0 + (resolution_v - 2)*resolution_v)
		indices.append(1 + (resolution_v - 2)*resolution_v)
		indices.append(0 + (resolution_v - 1)*resolution_v)

	# LEFT <<< BOTTOM
	var corner_low_res_left_bottom = func():
		indices.append(1 + (resolution_v - 2)*resolution_v)
		indices.append(1 + (resolution_v - 1)*resolution_v)
		indices.append(0+ (resolution_v - 1)*resolution_v)

	# LEFT <<< TOP
	var corner_low_res_left_top = func():
		indices.append(0 + 0*resolution_v)
		indices.append(1 + 0*resolution_v)
		indices.append(1+ (0+1)*resolution_v)

	#corners for lower resolution fragmets
	match permutation:
		PERMUTATION.TOP:
			corner_low_res_top_left.call()
			corner_low_res_top_right.call()
		PERMUTATION.TOP_RIGHT:
			corner_low_res_top_left.call()
			corner_low_res_right_bottom.call()
		PERMUTATION.LEFT_TOP:
			corner_low_res_top_right.call()
			corner_low_res_left_bottom.call()
		PERMUTATION.RIGHT:
			corner_low_res_right_top.call()
			corner_low_res_right_bottom.call()
		PERMUTATION.RIGHT_BOTTOM:
			corner_low_res_right_top.call()
			corner_low_res_bottom_left.call()
		PERMUTATION.BOTTOM:
			corner_low_res_bottom_right.call()
			corner_low_res_bottom_left.call()
		PERMUTATION.BOTTOM_LEFT:
			corner_low_res_bottom_right.call()
			corner_low_res_left_top.call()
		PERMUTATION.LEFT:
			corner_low_res_left_bottom.call()
			corner_low_res_left_top.call()

	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_INDEX] = indices
	arrays[Mesh.ARRAY_TANGENT] = tangets
	var blend_shapes = []

	new_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays, blend_shapes, {})
	mesh = new_mesh
	return new_mesh
