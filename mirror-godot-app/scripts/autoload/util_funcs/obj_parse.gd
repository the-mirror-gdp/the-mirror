# Obj parser made by Ezcha, updated by Deakcor
# Ported to Godot 4.0
# Created on 7/11/2018
# https://ezcha.net
# https://github.com/Ezcha/gd-obj
# MIT License
# https://github.com/Ezcha/gd-obj/blob/master/LICENSE

const debug: bool = false


## Create mesh from obj and mtl paths
static func load_obj(obj_path: String, mtl_path: String = "") -> Mesh:
	if mtl_path.is_empty():
		mtl_path = search_mtl_path(obj_path)
	var obj: String = get_data(obj_path)
	var mats: Dictionary = {}
	if not mtl_path.is_empty():
		mats = _create_mtl(get_data(mtl_path), get_mtl_tex(mtl_path))
	return _create_obj(obj, mats) if not obj.is_empty() and not mats.is_empty() else null


## Create mesh from obj, materials. Materials should be {"matname":data}
static func load_obj_from_buffer(obj_data: String, materials: Dictionary) -> Mesh:
	return _create_obj(obj_data, materials)


## Create materials
static func load_mtl_from_buffer(mtl_data: String, textures: Dictionary) -> Dictionary:
	return _create_mtl(mtl_data, textures)


## Get data from file path
static func get_data(path: String) -> String:
	if not path.is_empty():
		var file: FileAccess = FileAccess.open(path, FileAccess.READ)
		if file:
			var res: String = file.get_as_text()
			file.flush()
			return res
	return ""


## Get textures from mtl path (return {"tex_path":data})
static func get_mtl_tex(mtl_path: String) -> Dictionary:
	var file_paths: Array = get_mtl_tex_paths(mtl_path)
	var textures: Dictionary = {}
	for k in file_paths:
		textures[k] = _get_image(mtl_path, k).save_png_to_buffer()
	return textures


## Get textures paths from mtl path
static func get_mtl_tex_paths(mtl_path: String) -> Array:
	var file: FileAccess = FileAccess.open(mtl_path, FileAccess.READ)
	var paths: Array = []
	if file:
		var lines: PackedStringArray = file.get_as_text().split("\n", false)
		file.flush()
		for line in lines:
			var parts = line.split(" ", false, 1)
			if parts[0] in ["map_Kd", "map_Ks", "map_Ka"] and not (parts[1] in paths):
				paths.push_back(parts[1])
	return paths


## Try to find mtl path from obj path
static func search_mtl_path(obj_path: String) -> String:
	var mtl_path: String = obj_path.get_base_dir().path_join(obj_path.get_file().rsplit(".", false, 1)[0] + ".mtl")
	if not FileAccess.file_exists(mtl_path):
		mtl_path = obj_path.get_base_dir().path_join(obj_path.get_file() + ".mtl")
	if not FileAccess.file_exists(mtl_path):
		return ""
	return mtl_path


static func _create_mtl(obj: String, textures: Dictionary) -> Dictionary:
	var mats: Dictionary = {}
	var currentMat: StandardMaterial3D = null
	var lines: PackedStringArray = obj.split("\n", false)
	for line in lines:
		var parts = line.split(" ", false)
		match parts[0]:
			"#":
				# Comment
				#print("Comment: "+line)
				pass
			"newmtl":
				# Create a new material
				if debug:
					print("Adding new material " + parts[1])
				currentMat = StandardMaterial3D.new()
				mats[parts[1]] = currentMat
			"Ka":
				# Ambient color
				#currentMat.albedo_color = Color(float(parts[1]), float(parts[2]), float(parts[3]))
				pass
			"Kd":
				# Diffuse color
				currentMat.albedo_color = Color(parts[1].to_float(), parts[2].to_float(), parts[3].to_float())
				if debug:
					print("Setting material color " + str(currentMat.albedo_color))
				pass
			_:
				if parts[0] in ["map_Kd", "map_Ks", "map_Ka"]:
					var path = line.split(" ", false, 1)[1]
					if textures.has(path):
						currentMat.albedo_texture = _create_texture(textures[path])
	return mats


static func _parse_mtl_file(path: String) -> Dictionary:
	return _create_mtl(get_data(path), get_mtl_tex(path))


static func _get_image(mtl_filepath: String, tex_filename: String) -> Image:
	if debug:
		print("    Debug: Mapping texture file %s" % tex_filename)
	var texfilepath: String = tex_filename
	if tex_filename.is_relative_path():
		texfilepath = mtl_filepath.get_base_dir().path_join(tex_filename)
	var filetype: String = texfilepath.get_extension()
	if debug:
		print("    Debug: texture file path: %s of type %s" % [texfilepath, filetype])

	var img: Image = Image.new()
	img.load(texfilepath)
	return img


static func _create_texture(data: PackedByteArray) -> ImageTexture:
	var img: Image = Image.new()
	img.load_png_from_buffer(data)
	return ImageTexture.create_from_image(img)


static func _get_texture(mtl_filepath: String, tex_filename: String) -> ImageTexture:
	var tex := ImageTexture.create_from_image(_get_image(mtl_filepath, tex_filename))
	if debug:
		print("    Debug: texture is " + str(tex))
	return tex


static func _create_obj(obj: String, mats: Dictionary) -> Mesh:
	var count_mtl: int = 0
	var faces: Dictionary = {}
	var mat_name: String = "default"
	var mesh: ArrayMesh = ArrayMesh.new()
	var uvs: PackedVector2Array = PackedVector2Array()
	var normals: PackedVector3Array = PackedVector3Array()
	var vertices: PackedVector3Array = PackedVector3Array()

	var lines: PackedStringArray = obj.split("\n", false)
	for line in lines:
		var parts: PackedStringArray = line.split(" ", false)
		match parts[0]:
			"#":
				# Comment
				#print("Comment: "+line)
				pass
			"v":
				# Vertice
				var n_v = Vector3(parts[1].to_float(), parts[2].to_float(), parts[3].to_float())
				vertices.append(n_v)
			"vn":
				# Normal
				var n_vn = Vector3(parts[1].to_float(), parts[2].to_float(), parts[3].to_float())
				normals.append(n_vn)
			"vt":
				# UV
				var n_uv = Vector2(parts[1].to_float(), 1 - parts[2].to_float())
				uvs.append(n_uv)
			"usemtl":
				# Material group
				count_mtl += 1
				mat_name = parts[1]
				if not faces.has(mat_name):
					var mats_keys: Array = mats.keys()
					if not mats.has(mat_name):
						if mats_keys.size() > count_mtl:
							mat_name = mats_keys[count_mtl]
					faces[mat_name] = []
			"f":
				if not faces.has(mat_name):
					var mats_keys := mats.keys()
					if mats_keys.size() > count_mtl:
						mat_name = mats_keys[count_mtl]
					faces[mat_name] = []
				# Face
				if parts.size() == 4:
					# Tri
					var face = {"v": [], "vt": [], "vn": []}
					for map in parts:
						var vertices_index = map.split("/")
						if str(vertices_index[0]) != "f":
							face["v"].append(vertices_index[0].to_int() - 1)
							face["vt"].append(vertices_index[1].to_int() - 1)
							if vertices_index.size() > 2:
								face["vn"].append(vertices_index[2].to_int() - 1)
					if faces.has(mat_name):
						faces[mat_name].append(face)
				elif parts.size() > 4:
					# Triangulate
					var points = []
					for map in parts:
						var vertices_index = map.split("/")
						if str(vertices_index[0]) != "f":
							var point = []
							point.append(vertices_index[0].to_int() - 1)
							point.append(vertices_index[1].to_int() - 1)
							if vertices_index.size() > 2:
								point.append(vertices_index[2].to_int() - 1)
							points.append(point)
					for i in points.size():
						if i == 0:
							continue
						var face = {"v": [], "vt": [], "vn": []}
						var point0 = points[0]
						var point1 = points[i]
						var point2 = points[i - 1]
						face["v"].append(point0[0])
						face["v"].append(point2[0])
						face["v"].append(point1[0])
						face["vt"].append(point0[1])
						face["vt"].append(point2[1])
						face["vt"].append(point1[1])
						if point0.size() > 2:
							face["vn"].append(point0[2])
						if point2.size() > 2:
							face["vn"].append(point2[2])
						if point1.size() > 2:
							face["vn"].append(point1[2])
						faces[mat_name].append(face)

	# Make tri
	for matgroup in faces.keys():
		if debug:
			print("Creating surface for matgroup " + matgroup + " with " + str(faces[matgroup].size()) + " faces")

		# Mesh Assembler
		var st = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		if not mats.has(matgroup):
			mats[matgroup] = StandardMaterial3D.new()
		st.set_material(mats[matgroup])
		for face in faces[matgroup]:
			if face["v"].size() == 3:
				# Vertices
				var fan_v = PackedVector3Array()
				fan_v.append(vertices[face["v"][0]])
				fan_v.append(vertices[face["v"][2]])
				fan_v.append(vertices[face["v"][1]])

				# Normals
				var fan_vn = PackedVector3Array()
				if face["vn"].size() > 0:
					fan_vn.append(normals[face["vn"][0]])
					fan_vn.append(normals[face["vn"][2]])
					fan_vn.append(normals[face["vn"][1]])

				# Textures
				var fan_vt = PackedVector2Array()
				if face["vt"].size() > 0:
					for k in [0, 2, 1]:
						var f = face["vt"][k]
						if f > -1:
							var uv = uvs[f]
							fan_vt.append(uv)

				st.add_triangle_fan(fan_v, fan_vt, PackedColorArray(), PackedVector2Array(), fan_vn, [])
		mesh = st.commit(mesh)
	for k in mesh.get_surface_count():
		var mat: Material = mesh.surface_get_material(k)
		mat_name = ""
		for m in mats:
			if mats[m] == mat:
				mat_name = m
		mesh.surface_set_name(k, mat_name)
	return mesh
