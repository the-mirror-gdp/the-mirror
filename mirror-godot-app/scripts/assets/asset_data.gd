class_name AssetData
extends Resource


signal files_loaded()
signal preview_generated()
signal preview_downloaded()

const _ASSET_PREVIEW_TSCN = preload("res://ui/new_player_ui/asset_preview/asset_preview.tscn")
const _AUDIO_ICON = preload("res://creator/asset_inventory/browser/icons/audio.svg")
const _GDSCRIPT_ICON = preload("res://script/gd/editor/icons/text_script.svg")
const _VISUAL_SCRIPT_ICON = preload("res://script/visual/editor/icons/visual_script.svg")

var asset_name: String = ""
var preview_texture: Texture
var role: Dictionary = {}
var asset_id: String
var description: String
var collision_enabled: bool = false
var material_asset_id: String = ""
var object_color: Array = []
var object_texture_id: String = ""
var object_texture_size: Vector3 = Vector3.ZERO
var object_texture_triplanar: bool = false
var public: bool = false
var created_at_unix_time: int
var tags: Dictionary = {}
## @deprecated - tags_v2
var tags_v2: Array = []
var thirdparty_source_home_page_url: String = ""
var is_equipable: bool = false
var owner_id: String = ""
var creator_id: String = ""

var type: String # asset type (mesh, primitive, etc)
var file_url: String # Current file string is a file url
var thumbnail_url: String
var _asset_preview: Node
var _populated: bool = false
var _generated: bool = false
var _preview_node: Node = null
var _loaded_file_promise: Promise = Promise.new()


## Tries to download the current file.
## If the file is loaded in memory, it is referenced.
## Otherwise, a download request is made.
func try_download_file(priority: Enums.DownloadPriority = Enums.DownloadPriority.DEFAULT) -> void:
	if _loaded_file_promise.has_result():
		return
	if file_url.is_empty():
		return
	# _loaded_file_promise can be referenced by other classes, so it can't be overwritten
	var promise = Net.file_client.get_file(file_url, priority)
	await promise.wait_till_fulfilled()
	if promise.is_error():
		print("Error loading file for asset: %s Err: %s" % [asset_id, promise.get_error_message()])
		_loaded_file_promise.set_error(promise.get_error_message())
		return
	# Check again after await to make sure than any thing that concurrent requests a file do not reemit signal
	if _loaded_file_promise.has_result():
		return
	_loaded_file_promise.set_result(promise.get_result())
	files_loaded.emit()


## Finds the preview image. Loads from Disk.
## If not found, checks for downloadable and gets it.
## If it has neither, it is generated and then uploaded.
func try_get_preview_texture(in_priority: Enums.DownloadPriority = Enums.DownloadPriority.DEFAULT) -> void:
	# return if preview_texture is already set
	if preview_texture:
		return
	if type == Enums.ASSET_TYPE.AUDIO:
		preview_texture = _AUDIO_ICON
		return
	# try load from disk, necessary because thumbnail can be locally generated
	_try_load_preview_from_disk()

	# preview_texture was not found, so generate it
	if thumbnail_url.is_empty():
		_generate_preview_texture()
		return

	# return if preview_texture is loaded from disk
	if preview_texture:
		return
	# get the thumbnail/preview
	var promise = Net.file_client.get_file(thumbnail_url, in_priority)
	await promise.wait_till_fulfilled()
	if promise.is_error():
		print("Error downloading thumbnail: %s" % [promise.get_error_message()])
		return
	_try_load_preview_from_disk()
	if not preview_texture:
		print("Error getting preview texture.")
		return
	preview_downloaded.emit()


func _generate_preview_texture(force: bool = false) -> void:
	if _generated and not force:
			return
	elif not _loaded_file_promise.has_result():
			try_download_file() # this is safe, as it will result in the same promise even when concurrent
			await _loaded_file_promise.wait_till_fulfilled()
	if _loaded_file_promise.is_error():
		print("Error during generating preview: Issue with downloaded file for asset: %s" % asset_id)
		return
	_generated = true
	var file_promise_result = _loaded_file_promise.get_result()
	var thumbnail_path = (Util.get_files_directory_path() + "%s_thumbnail.webp") % asset_id
	if file_promise_result is ImageTexture:
		_generate_image_preview(file_promise_result.get_image(), thumbnail_path)
		return
	if file_promise_result is AudioStream:
		preview_texture = _AUDIO_ICON
		return
	if file_promise_result is Node:
		_generate_mesh_preview(file_promise_result, thumbnail_path)
		return
	if file_promise_result is Dictionary:
		var type: String = file_promise_result.get("type", "")
		if type == "GDScript":
			preview_texture = _GDSCRIPT_ICON
			return
		elif type == "MirrorVisualScript":
			preview_texture = _VISUAL_SCRIPT_ICON
			return
	push_error("Unable to generate asset preview for unhandled type")
	print("Unable to generate asset preview for unhandled type")


func _generate_mesh_preview(node: Node, path: String) -> void:
	# duplicate node so it is not freed from memory after preview is generated.
	_preview_node = node.duplicate()
	_asset_preview = _ASSET_PREVIEW_TSCN.instantiate()
	GameUI.add_child(_asset_preview)
	# set an offset so it is not on screen.
	_asset_preview.position.x = -1000
	_asset_preview.position.y = -1000
	_asset_preview.preview_generated.connect(_handle_preview_generated, CONNECT_ONE_SHOT)
	_asset_preview.set_deferred("size", Vector2(300, 300))
	_asset_preview.add_asset(_preview_node)
	# use the deferred save image method to allow the render to complete
	_asset_preview.deferred_save_image(path)


func _generate_image_preview(image: Image, path: String) -> void:
	const max_image_size := 256
	image.convert(Image.FORMAT_RGBA8)
	var dimm = image.get_size()
	if dimm.x > max_image_size or dimm.y > max_image_size:
		var max_dimm: float = dimm.x if dimm.x > dimm.y else dimm.y
		var scaled_dimm = dimm / max_dimm * max_image_size
		image.resize(scaled_dimm.x, scaled_dimm.y)
	image.save_webp(path, true)
	_handle_preview_generated(image)


func _can_thumbnail_be_uploaded() -> bool:
	if role.is_empty():
		return false
	var asset_role = {"role": role}
	var current_user_role = Util.get_role_for_user(asset_role, Net.user_id)
	return current_user_role >= Enums.ROLE.MANAGER and asset_id is String


func _free_previews() -> void:
	if is_instance_valid(_preview_node):
		_preview_node.queue_free()
		_preview_node = null
	if is_instance_valid(_asset_preview):
		GameUI.remove_child(_asset_preview)
		_asset_preview.queue_free()
		_asset_preview = null


## Listens to the preview generated signal, generates the texture, and emits a signal.
func _handle_preview_generated(image: Image) -> void:
	var bytes = image.save_webp_to_buffer(true)
	preview_texture = ImageTexture.create_from_image(image)
	if not _can_thumbnail_be_uploaded():
		#print("No permission to upload asset thumbnail: ", asset_id)
		_free_previews()
		preview_generated.emit()
		return
	var promise = Net.asset_client.upload_asset_thumb(asset_id, bytes)
	promise.connect_func_to_fulfill(func():
			if promise.is_error():
				print("Error during uploading a preview texture: ", promise.get_error_message())
			_free_previews()
			preview_generated.emit()
	)


## Tries to load the preview image from disk and populates the preview_texture
func _try_load_preview_from_disk() -> void:
	if preview_texture:
		return

	var file_path = (Util.get_files_directory_path() + "%s_thumbnail.webp") % asset_id
	var img = Util.load_image(file_path)
	if img:
		preview_texture = img
		return
	file_path = "%s%s_thumbnail.jpg" % [Util.get_files_directory_path(), asset_id]
	img = Util.load_image(file_path)
	if img:
		preview_texture = img
		return
	file_path = (Util.get_files_directory_path() + "%s_thumbnail.png") % asset_id
	img = Util.load_image(file_path)
	if img:
		preview_texture = img
		return
	if thumbnail_url.begins_with("res://") and ResourceLoader.exists(thumbnail_url):
		img = load(thumbnail_url) as Texture2D
	if img:
		preview_texture = img


## Iterates through the files on the asset data and finds the first GLTF, GLB, or PCK file.
## If the file can be loaded into a node, the node is returned.
func get_asset_file_promise() -> Promise:
	return _loaded_file_promise


## Finds first ThirdPartySourceTag tag with thirdPartySourceHomePageUrl
## and returns its value
func _extract_home_page_url(tags_v2: Array) -> String:
	for tag in tags_v2:
		if not tag is Dictionary:
			continue
		if tag.get("__t", "") != "ThirdPartySourceTag":
			continue
		var tag_source_url = tag.get("thirdPartySourceHomePageUrl", "")
		if tag_source_url.is_empty():
			continue
		return tag_source_url
	return ""


func populate(dict: Dictionary) -> void:
	if dict == null:
		return
	if dict.has("_id"):
		asset_id = dict["_id"]
	if dict.get("role", {}) is Dictionary:
		role = dict.get("role", {})
	if dict.has("tags"):
		tags = dict.get("tags", {})
	if dict.has("tagsV2"):
		tags_v2 = dict.get("tagsV2", [])
		thirdparty_source_home_page_url = _extract_home_page_url(tags_v2)
	if dict.has("name"):
		asset_name = dict["name"]
	if dict.has("description"):
		description = dict["description"]
	if dict.has("createdAt"):
		var created_at_dt_string = dict.get("createdAt", "")
		var created_at_dt = Time.get_datetime_dict_from_datetime_string(created_at_dt_string, false)
		created_at_unix_time = Time.get_unix_time_from_datetime_dict(created_at_dt)
	if dict.has("assetType"):
		type = dict["assetType"]
	if dict.has("currentFile"):
		file_url = str(dict["currentFile"]).uri_decode()
		if Net.file_client.files.has(file_url):
			var loaded_file = Net.file_client.files[file_url]
			_loaded_file_promise.set_result(loaded_file)
	if dict.has("collisionEnabled"):
		collision_enabled = dict["collisionEnabled"]
	if dict.has("thumbnail"):
		thumbnail_url = dict["thumbnail"]
	if dict.has("materialAssetId"):
		material_asset_id = dict["materialAssetId"]
	if dict.has("objectColor"):
		object_color = dict["objectColor"]
	if dict.has("objectTexture"):
		object_texture_id = dict["objectTexture"]
	if dict.has("objectTextureSizeV2"):
		object_texture_size = Serialization.array_to_vector3(dict["objectTextureSizeV2"])
	if dict.has("objectTextureTriplanar"):
		object_texture_triplanar = dict["objectTextureTriplanar"]
	if dict.has("mirrorPublicLibrary"):
		public = dict.get("mirrorPublicLibrary", false)
	if dict.has("isEquipable"):
		is_equipable = dict.get("isEquipable", false)
	if dict.has("owner"):
		var owner = dict.get("owner")
		if owner is Dictionary:
			owner_id = owner.get("_id", "")
		elif owner is String:
			owner_id = owner
	if dict.has("creator"):
		var creator = dict.get("creator")
		if creator is Dictionary:
			creator_id = creator.get("_id", "")
		elif creator is String:
			creator_id = creator
	_populated = true
