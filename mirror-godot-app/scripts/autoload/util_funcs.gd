#class_name Util
extends Node

const ObjParse = preload("res://scripts/autoload/util_funcs/obj_parse.gd")

const SUPPORTED_SCENES: PackedStringArray = ["pck"]
const SUPPORTED_MODELS: PackedStringArray = ["gltf", "glb"]

# TODO: Fix OGG Import
# Blocked by: https://github.com/godotengine/godot/issues/61091
const SUPPORTED_AUDIO: PackedStringArray = ["wav", "mp3"]
const SUPPORTED_IMAGES: PackedStringArray = ["png", "jpg", "jpeg", "webp", "exr"]

const MAC_NAME = "macos"
const WIN_NAME = "windows"
const LINUX_NAME = "linuxbsd"

const PLATFORMS: Dictionary = {
	"mac": MAC_NAME,
	"macos": MAC_NAME,
	"win": WIN_NAME,
	"win32": WIN_NAME,
	"win64": WIN_NAME,
	"windows": WIN_NAME,
	"bsd": LINUX_NAME,
	"linux": LINUX_NAME,
	"netbsd": LINUX_NAME,
	"freebsd": LINUX_NAME,
	"openbsd": LINUX_NAME,
	"linuxbsd": LINUX_NAME,
}


## Apply delta to the dict and the value
## This generates a diff from a value change
## A value change is recorded on the original data, but also saved to a dictionary with only the different values
## No operation when there is not a original dict change.
static func apply_delta_to_dict(original: Dictionary, delta_dict: Dictionary, key: String, new_value: Variant) -> bool:
	var original_value = original.get(key)
	#assert(key != "collisionEnabled")
	#assert(not (new_value is Array))
	#assert(not (new_value is Dictionary))
	if new_value is Dictionary and original.get(key) is Dictionary or new_value is Array and original.get(key) is Array:
		if original_value.hash() != new_value.hash():
			delta_dict[key] = new_value
			original[key] = new_value
			return true
	if original_value != new_value:
		delta_dict[key] = new_value
		original[key] = new_value
		return true
	return false


static func get_server_token() -> String:
	var commandline_token: String = get_commandline_id_val("WSS_SECRET")
	if not commandline_token.is_empty():
		return commandline_token
	# when hosted from a local machine it supplies the jwt
	return Firebase.Auth.get_jwt()


## gets the current platform executable path.
## executable name is included in path. mac executable path is a special case.
static func get_current_executable_path() -> String:
	return get_executable_path(Util.get_current_platform_name())


## gets the provided platform executable path.
## executable name is included in path. mac executable path is a special case.
static func get_executable_path(os_name: String) -> String:
	var is_mac = Util.get_simple_platform_name(os_name) == Util.MAC_NAME
	return _get_mac_executable_path() if is_mac else OS.get_executable_path()


static func write_text_file(full_path: String, file_contents: String) -> void:
	var file = FileAccess.open(full_path, FileAccess.WRITE)
	file.store_line(file_contents)


## get the executable path for mac, which is a special case.
static func _get_mac_executable_path() -> String:
	# path to executable directory
	var execution_dir = OS.get_executable_path().get_base_dir()
	# are we running game.app from mac?
	var is_app_package = execution_dir.contains(".app/Contents/MacOS")
	var dir = DirAccess.open(execution_dir)
	if dir and is_app_package:
		if dir.change_dir("../../") == OK:
			return dir.get_current_dir()
		else:
			push_error("unable to change directory")
	return OS.get_executable_path()


static func get_current_platform_name() -> String:
	return get_simple_platform_name(OS.get_name())


static func current_platform_is_mac() -> bool:
	return get_current_platform_name() == MAC_NAME


static func current_platform_is_windows() -> bool:
	return get_current_platform_name() == WIN_NAME


static func get_simple_platform_name(os_name:String) -> String:
	var lower_os_name = os_name.to_lower()
	return PLATFORMS.get(lower_os_name, lower_os_name)


static func compare_hash(local_file: String, expected_hash: String) -> bool:
	if expected_hash.is_empty():
		push_error("Invalid expected hash it's empty!")
		return false
	if local_file.is_empty():
		push_error("Invalid local file to compare hash for")
		return false
	return FileAccess.file_exists(local_file) and FileAccess.get_sha256(local_file) == expected_hash


# In the future this will actually return the zones from the Web API
# We want this here because our UI relies on it and so does Deeplinking
static func get_project_settings_zones_array() -> Array:
	return ProjectSettings.get_setting("mirror/zones", []) as Array


## Gets the current environment int that matches with Enums.ENV.
static func get_environment() -> int:
	var env_val = ProjectSettings.get_setting("mirror/env")
	return Enums.ENV.DEV if env_val == null else env_val


## Determines if a path is png filetype.
static func path_is_png(path: String) -> bool:
	return "png" == get_ext(path)


## Determines if a path is webp filetype.
static func path_is_webp(path: String) -> bool:
	return "webp" == get_ext(path)

## Determines if a path is jpeg filetype.
static func path_is_jpeg(path: String) -> bool:
	var ext = get_ext(path)
	return ext in ["jpg", "jpeg"]

## Determines if a path is exr filetype.
static func path_is_exr(path: String) -> bool:
	return "exr" == get_ext(path)

## Determines if a path is supported image filetype.
static func path_is_image(path: String) -> bool:
	return SUPPORTED_IMAGES.has(get_ext(path))


## Determines if a path is supported model filetype.
static func path_is_model(path: String) -> bool:
	return SUPPORTED_MODELS.has(get_ext(path))


## Determines if a path is supported scene filetype.
static func path_is_scene(path: String) -> bool:
	return SUPPORTED_SCENES.has(get_ext(path))


## Determines if a path is supported audio filetype.
static func path_is_audio(path: String) -> bool:
	return SUPPORTED_AUDIO.has(get_ext(path))


## Determines if a path is supported JSON filetype.
static func path_is_json(path: String) -> bool:
	# Note: This will still work for file names like "myscript.vs.json".
	return path.get_extension() == "json"


## Returns a path's file extension string.
static func get_ext(path: String) -> String:
	return path.get_extension() if path != null and not path.is_empty() else ""


## Determines if a filetype is supported based on the path string.
static func filetype_supported(path: String) -> bool:
	var ext: String = get_ext(path)
	var is_scene = SUPPORTED_MODELS.has(ext)
	var is_model = SUPPORTED_IMAGES.has(ext)
	var is_image = SUPPORTED_SCENES.has(ext)
	return is_scene or is_model or is_image


## Gets WebP data from a texture.
static func get_webp_data(texture: Texture2D) -> PackedByteArray:
	var image: Image = texture.get_image()
	var data: PackedByteArray = image.save_webp_to_buffer()
	return data


##  Gets bytes WebP data of any image loaded at the path.
static func get_webp_data_at_path(path) -> PackedByteArray:
	var data: PackedByteArray
	var texture = load_image(path)
	if texture:
		if Util.path_is_webp(path):
			# Now that we confirmed that file is a correct image we load it
			# again from path, as it can be compressed with smaller size
			data = FileAccess.get_file_as_bytes(path)
		else:
			data = get_webp_data(texture)
	return data


## Gets EXR data from a texture.
static func get_exr_data(texture: Texture2D) -> PackedByteArray:
	var image: Image = texture.get_image()
	var data: PackedByteArray = image.save_exr_to_buffer()
	return data


##  Gets bytes EXR data of EXR file at the path.
static func get_exr_data_at_path(path) -> PackedByteArray:
	var data: PackedByteArray
	if not Util.path_is_exr(path):
		# We do not support exporting other image types as exr
		return data
	var image: Image = Image.new()
	var error = image.load(path)
	if not error:
		#data = image.save_exr_to_buffer()
		# Now that we confirmed that file is a correct image we load it
		# again from path, as it can be compressed with smaller size
		data = FileAccess.get_file_as_bytes(path)
	return data


## Determines if a value looks like a JSON string and returns true if it does.
static func looks_like_json(value) -> bool:
	if value == null:
		return false
	var string: String = str(value).strip_edges()
	var has_braces = string.begins_with("{") and string.ends_with("}")
	var has_brackets = string.begins_with("[") and string.ends_with("]")
	return has_braces or has_brackets


## Loads a GLTF file from the disk as a node object.
static func load_gltf_file_as_node(path: String) -> Variant:
	var state: GLTFState = GLTFState.new()
	if Zone.is_host():
		# Discard the textures when on the server
		state.set_handle_binary_image(GLTFState.HANDLE_BINARY_DISCARD_TEXTURES)
	var doc: GLTFDocument = GLTFDocument.new()
	var err = doc.append_from_file(path, state, 8)
	if err:
		push_error(str(err))
		return null
	var node: Node = doc.generate_scene(state)
	if not is_instance_valid(node):
		print_debug("generate_scene failed from path:", path)
		return null
	# Disallow importing a model with an empty root node name.
	if node.name == &"":
		node.name = &"Model"
	return node


## Converts a GLTF document (including all its external dependencies ) to a GLB byte array.
## See https://github.com/the-mirror-megaverse/mirror-godot-app/pull/261 for why
static func convert_gltf_to_glb_data(path: String) -> PackedByteArray:
	var state: GLTFState = GLTFState.new()
	var doc: GLTFDocument = GLTFDocument.new()
	var err = doc.append_from_file(path, state, 8)
	if err:
		push_error(str(err))
		return PackedByteArray()
	return doc.generate_buffer(state)


static func convert_obj_to_gltf_doc(path: String) -> GLTFDocument:
	var mesh = ObjParse.load_obj(path)
	if mesh == null:
		return null
	var inst_node = MeshInstance3D.new()
	var state: GLTFState = GLTFState.new()
	var doc: GLTFDocument = GLTFDocument.new()
	inst_node.mesh = mesh
	doc.append_from_scene(inst_node, state)
	return doc


static func convert_obj_to_glb_data(path: String, mtl_path: String = "") -> PackedByteArray:
	var mesh = ObjParse.load_obj(path, mtl_path)
	if mesh == null:
		return PackedByteArray()
	var inst_node = MeshInstance3D.new()
	var state: GLTFState = GLTFState.new()
	var doc: GLTFDocument = GLTFDocument.new()
	inst_node.name = &"MeshFromOBJ"
	inst_node.mesh = mesh
	doc.append_from_scene(inst_node, state)
	return doc.generate_buffer(state)


## Gets the byte data of a file on the disk.
static func get_file_bytes(path: String) -> PackedByteArray:
	var data: PackedByteArray
	if not FileAccess.file_exists(path):
		push_error("File does not exist at path: %s" % path)
		return data
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("File read error: %s" % file)
		return data
	data = file.get_buffer(file.get_length())
	#file.flush()
	return data


static func get_vertices(mesh: MeshInstance3D) -> PackedVector3Array:
	var vertices: PackedVector3Array = []
	var mesh_data_tool = MeshDataTool.new()
	mesh_data_tool.create_from_surface(mesh.mesh, 0)
	for vtx in range(mesh_data_tool.get_vertex_count()):
		vertices.append(mesh_data_tool.get_vertex(vtx))
	return vertices


static func convert_png_bytes_to_texture(bytes: PackedByteArray) -> ImageTexture:
	var image = Image.new()
	var error = image.load_png_from_buffer(bytes)
	if error:
		push_error("Byte Image conversion error: " + str(error))
		return null
	if not image.has_mipmaps():
		error = image.generate_mipmaps()
		if error:
			push_error("Mipmap generation error: " + str(error))
	return ImageTexture.create_from_image(image)


static func convert_webp_bytes_to_texture(bytes: PackedByteArray) -> ImageTexture:
	var image = Image.new()
	var error = image.load_webp_from_buffer(bytes)
	if error:
		push_error("Byte Image conversion error: " + str(error))
		return null
	if not image.has_mipmaps():
		error = image.generate_mipmaps()
		if error:
			push_error("Mipmap generation error: " + str(error))
	return ImageTexture.create_from_image(image)


static func convert_jpeg_bytes_to_texture(bytes: PackedByteArray) -> ImageTexture:
	var image = Image.new()
	var error = image.load_jpg_from_buffer(bytes)
	if error:
		push_error("Byte Image conversion error: " + str(error))
		return null
	if not image.has_mipmaps():
		error = image.generate_mipmaps()
		if error:
			push_error("Mipmap generation error: " + str(error))
	return ImageTexture.create_from_image(image)


static func load_image(path: String) -> ImageTexture:
	if not FileAccess.file_exists(path):
		return null
	var image: Image = Image.new()
	var error = image.load(path)
	if error:
		return null
	if Zone.is_host() and path_is_exr(path):
		image.convert(Image.FORMAT_RH) # do not really care about color, R for samplig heightmap
	if not image.has_mipmaps() and not path_is_exr(path) and not Zone.is_host():
		error = image.generate_mipmaps()
		if error:
			push_error("Mipmap generation error: " + str(error))
	return ImageTexture.create_from_image(image)


static func load_audio(path: String) -> AudioStream:
	if not FileAccess.file_exists(path):
		return null
	return AudioLoader.loadfile(path)


static func load_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json_string: String = FileAccess.get_file_as_string(path)
	var parsed_data = JSON.parse_string(json_string)
	if parsed_data is Dictionary:
		return parsed_data
	return {}


static func get_bounding_box(size: Vector3) -> BoxShape3D:
	var collision_shape: BoxShape3D = BoxShape3D.new()
	collision_shape.extents = size / 2
	return collision_shape


static func get_bounding_sphere(radius: float) -> SphereShape3D:
	var collision_shape: SphereShape3D = SphereShape3D.new()
	collision_shape.radius = radius
	return collision_shape


static func try_get_value(dict: Dictionary, key: String, default):
	return dict[key] if not dict.is_empty() and dict.has(key) else default


## Snaps a vector3 position to a specific grid unit size and returns it.
static func get_snapped_position(v3: Vector3, grid_unit: float = 5.0) -> Vector3:
	v3.x = ceil(v3.x / grid_unit) * grid_unit
	v3.y = ceil(v3.y / grid_unit) * grid_unit
	v3.z = ceil(v3.z / grid_unit) * grid_unit
	return v3


## Gets ray information from a mouse click.
static func create_ray_from_mouse_click(viewport: Viewport) -> Dictionary:
	var camera = viewport.get_camera_3d()
	var mouse_position = viewport.get_mouse_position()
	var ray = {
		origin = camera.project_ray_origin(mouse_position),
		normal = camera.project_ray_normal(mouse_position),
	}
	return ray


## Gets and returns the mouse raycast dictionary.
static func get_mouse_raycast(
	camera: Camera3D,
	viewport: Viewport,
	object_layers_list: Array = [],
	ignore_objects_list: Array = []
) -> Dictionary:
	var mouse_pos = viewport.get_mouse_position()
	var origin: Vector3 = camera.project_ray_origin(mouse_pos)
	var dest: Vector3 = origin + camera.project_ray_normal(viewport.get_mouse_position()) * camera.far
	return get_raycast(camera, origin, dest, object_layers_list, ignore_objects_list)


## Shoots a raycast from an origin to a destination and returns the raycast info.
static func get_raycast(
	camera: Camera3D,
	origin: Vector3,
	dest: Vector3,
	object_layers_list: Array = [],
	ignore_objects_list: Array = []
) -> Dictionary:
	var dic = Jolt.cast_ray(0, origin, (dest - origin).normalized(), (dest - origin).length(), object_layers_list, ignore_objects_list)
	#if object_layers_list.size() > 0:
	#	print(object_layers_list, " -- ", dic)
	return dic


static func is_host_commandline() -> bool:
	var cmd_line_args = Array(OS.get_cmdline_args())
	return cmd_line_args.has("server") or cmd_line_args.has("--server")


static func get_commandline_id_val(cmd_line_id: String) -> String:
	var id_val: String = ""
	var cmd_line_args = Array(OS.get_cmdline_args())
	var index = cmd_line_args.find("--%s" % cmd_line_id)
	if index >= 0 and cmd_line_args.size() > index + 1:
		id_val = cmd_line_args[index + 1]
	return id_val


static func is_headless_server() -> bool:
	return OS.has_feature("Server")


static func parse_json_from_string(json_text_str: String) -> Variant:
	if not looks_like_json(json_text_str):
		return null
	var json = JSON.new()
	if json.parse(json_text_str) == OK:
		return json.get_data()
	push_error("JSON Parse Error: %s " % str(json.get_error_message()))
	return null


## Parses the git managed version string from version.json and returns it.
## If parse fails, empty string is returned.
static func get_version_string() -> String:
	var version_str: String = ""
	var version_json = TMFileUtil.load_json_file("res://package.json")
	if version_json is Dictionary and version_json.has("version"):
		version_str = str(version_json["version"])
	return version_str


static func clean_string_for_model_file_path(text: String) -> String:
	text = TMFileUtil.clean_string_for_file_path(text)
	if text.is_empty():
		text = "Unnamed Model"
	assert(text.is_valid_filename())
	return text


static func get_space_object(target_node: Node) -> SpaceObject:
	while target_node != null:
		if target_node is SpaceObject:
			return target_node
		target_node = target_node.get_parent()
	return null


## Recursively find nodes with the given metadata key.
static func recursive_find_nodes_with_meta(current_node: Node, meta_key: StringName, array: Array = []) -> Array:
	if current_node.has_meta(meta_key):
		array.append(current_node)
	for child in current_node.get_children():
		recursive_find_nodes_with_meta(child, meta_key, array)
	return array


## Like `TMNodeUtil.recursive_find_nodes_by_type` but includes self.
static func recursive_find_nodes_of_type(current_node: Node, node_type) -> Array[Node]:
	var valid_type_children: Array[Node] = TMNodeUtil.recursive_find_nodes_by_type(current_node, node_type)
	if is_instance_of(current_node, node_type):
		valid_type_children.append(current_node)
	return valid_type_children


static func get_files_directory_path() -> String:
	if Zone.is_host():
		return "user://files_server/"
	else:
		return "user://files/"


static func get_primitive_models_directory_path() -> String:
	return "user://primitive_models/"


static func get_screenshots_directory_path() -> String:
	return "%s/%s/" % [OS.get_system_dir(OS.SYSTEM_DIR_PICTURES), "TheMirror"]


static func save_screenshot(image: Image) -> void:
	var unix_time: float = Time.get_unix_time_from_system()
	var dt: Dictionary = Time.get_datetime_dict_from_unix_time(unix_time)
	var ms: int = Time.get_ticks_msec()
	var timestamp: String = "%s-%02d-%02d-%02d%02d%02d-%02d" % [dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second, ms]
	var path: String = "%s%s%s" % [get_screenshots_directory_path(), "Screenshot ", timestamp]
	image.save_png(path + ".png")
	print("Saved screenshot to - " + path)


static func publish_space( space_id: String ) -> bool:
	var promise = Net.space_client.publish_space(space_id)
	var space_version = await promise.wait_till_fulfilled()
	if promise.is_error():
		var promise_error = promise.get_error_message()
		if promise_error is Dictionary and promise_error.has("message"):
			promise_error = promise_error["message"]
		Notify.error("Error on Space Publish", promise_error)
		return false
	Notify.success("Space Published", "")
	return true


static func open_folder_at_path(path: String) -> void:
	var global_path = ProjectSettings.globalize_path(path)
	if not global_path.begins_with("file:/"):
		# Must have three slashes https://en.wikipedia.org/wiki/File_URI_scheme
		if global_path.begins_with("/"):
			global_path = "file://" + global_path
		else:
			global_path = "file:///" + global_path
	OS.shell_open(global_path)


static func can_edit_object_in_space(object: Object) -> bool:
	var space_role = Util.get_role_for_user(Zone.space, Net.user_id)
	if space_role >= Enums.ROLE.MANAGER:
		return true
	if space_role < Enums.ROLE.CONTRIBUTOR:
		return false

	var creator_user_id = ""
	if object is SpaceObject:
		var data: Dictionary = object.space_object_data
		if data.has("creator"):
			creator_user_id = data["creator"]
		else:
			# Compatibility: This is not used anymore for new objects.
			creator_user_id = data.get("receipt", {}).get("created_by_user", "")
	return creator_user_id == Net.user_id


static func can_local_user_edit_scripts() -> bool:
	var space_role = Util.get_role_for_user(Zone.space, Net.user_id)
	return space_role > Enums.ROLE.CONTRIBUTOR


static func get_role_for_user(entity: Dictionary, user_id: String) -> int:
	if entity.is_empty():
		return Enums.ROLE.NO_ROLE
	var roles = entity.get("role")
	if not roles is Dictionary:
		printerr("Roles are not a dict!!")
		return Enums.ROLE.NO_ROLE

	var default_role = roles.get("defaultRole", Enums.ROLE.NO_ROLE)

	var entity_owners = roles.get("owners", [])
	if not entity_owners is Array:
		#This is anomally, return default role
		printerr("Roles: Owners is not an array")
		return default_role

	if user_id in entity_owners:
		return Enums.ROLE.OWNER

	var users = roles.get("users", {})
	if not users is Dictionary:
		#This is anomally, return default role
		printerr("Roles: Users is not a dictionary")
		return default_role

	var user_role = users.get(user_id, default_role)
	## TODO implement users_groups check
	return user_role


static func datetime_dict_to_mmm_dd_yyyy(datetime_dict: Dictionary) -> String:
	var day = datetime_dict["day"] # 1-31
	var month= datetime_dict["month"] # 1-12
	var year= datetime_dict["year"]
	var name_month= ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
	# TODO: find a way to use tr() from a static function in the future
	return  "%s %02d, %d" % [ name_month[month-1], day, year]


static func safe_signal_connect(sig: Signal, callable: Callable, flags: int = 0):
	if not sig.is_connected(callable):
			sig.connect(callable, flags)


static func safe_signal_disconnect(sig: Signal, callable: Callable):
	if sig.is_connected(callable):
			sig.disconnect(callable)


## 	Used for collision layers/mask mostly
## 	Simpler interface on top of discord_gd's BitField
# Inspired from https://godotengine.org/qa/95753/how-to-check-an-individual-binary-digit
class SimpleBitField:
	extends BitField


	func get_bit(index: int) -> bool:
		_assert_index(index)
		# Bit wise AND (&), so we only keep the bits
		# if both side have it set as 1
		# Example: 0b1100 & 0b0101 = 0b0100
		var _shared_bits_only: int = bitfield & (1 << index)
		return _shared_bits_only != 0


	func toggle_bit_on(index: int) -> void:
		change_bit(index, 1)


	func toggle_bit_off(index: int) -> void:
		change_bit(index, 0)


	func change_bit(index: int, new_value: int) -> void:
		_assert_index(index)
		assert(new_value == 1 or new_value == 0)
		# Bit wise OR (|)
		# Example: 0b1100 & 0b0101 = 0b1101
		bitfield |= (new_value << index)


	func toggle_bit(index: int) -> void:
		_assert_index(index)
		# Bit wise XOR (^)
		bitfield ^= (1 << index)


	## Make sure that the index is not over/under flowing
	##   the max amount of bits in an int
	func _assert_index(index: int):
		assert(index >= 0)
		assert(index <= 32)


	func simple_bit_field_to_string():
		var as_binary_str = ""
		for i in range(32, 0, -1):
			as_binary_str += str(int(self.get_bit(i)))
			if (i - 1) % 4 == 0:
				as_binary_str += ","
		return as_binary_str


##in_schema is a dict with properties in the format:
##{ PROPERTY : PROPERTY_TYPE}
##Where PROPERTY is a string identifying property and PROPERTY_TYPE is one from Variant.Type enum
static func compare_with_schema(in_dict_to_compare: Dictionary, in_schema: Dictionary) -> bool:
	if in_dict_to_compare.size() != in_schema.size():
		return false
	for key in in_schema:
		if not in_dict_to_compare.has(key):
			return false
		if typeof(in_dict_to_compare[key]) != in_schema[key]:
			return false
	return true


static func is_vr_enabled() -> bool:
	var interface = XRServer.find_interface("OpenXR")
	return interface and interface.is_initialized()
