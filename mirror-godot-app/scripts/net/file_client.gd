class_name FileClient
extends MirrorHttpClient

enum {
	GET_FILE,
}


const _AVATARS_CFG_PATH: String = "res://avatars.cfg"

var files: Dictionary = Dictionary()
var resource_avatars: Dictionary = Dictionary()

var _file_cache: FileCache = FileCache.new()
var _file_requests_queued: Dictionary = {}


func _ready() -> void:
	add_child(_file_cache)
	_load_resource_avatars_config()


func _load_resource_avatars_config() -> void:
	var avatar_cfg: ConfigFile = ConfigFile.new()
	avatar_cfg.load(_AVATARS_CFG_PATH)
	for resource_avatar in avatar_cfg.get_value("mirror", "resource_avatars", []):
		if not resource_avatar.has("url") or not resource_avatar.has("resource"):
			continue
		resource_avatars[resource_avatar["url"]] = resource_avatar["resource"]


func is_file_downloaded(in_url: String) -> bool:
	var is_local = in_url.begins_with("res://") and ResourceLoader.exists(in_url)
	return _file_cache.cached_file_exists(in_url) or is_local


func is_downloading() -> bool:
	return not _requests.is_empty()


func file_is_queued_or_downloading(url: String) -> bool:
	return _file_requests_queued.has(url)


func _on_loaded_model_threaded(file_url: String, promise: Promise) -> void:
	if promise.is_error():
		print("Failed to load a file: %s" % [promise.get_error_message()])
		return
	_set_file_data(file_url, promise.get_result())


func _copy_from_cache(url: String, path: String) -> bool:
	if _file_cache.cached_file_exists(url):
		var cache_path = _file_cache.get_cached_file_path(url)
		DirAccess.copy_absolute(cache_path, path)
		return true
	return false


func save_file(url: String, path: String, priority: Enums.DownloadPriority = Enums.DownloadPriority.DEFAULT) -> Promise:
	var promise = Promise.new()
	if _copy_from_cache(url, path):
		promise.set_result(true)
		return promise
	var promise_query = get_file(url, priority)
	promise_query.connect_func_to_fulfill(func():
		if promise_query.is_error():
			promise.set_error(promise_query.get_error_message())
			return
		if _copy_from_cache(url, path):
			promise.set_result(true)
		else:
			promise.set_error("Error during saving the file to disk")
		)
	return promise


## Retrieves a file at the provided url.
## If the file is stored locally, the file is loaded.
func get_file(url: String, priority: Enums.DownloadPriority = Enums.DownloadPriority.DEFAULT) -> Promise:
	if files.has(url):
		var promise = Promise.new()
		promise.set_result(files.get(url))
		return promise
	if Util.path_is_model(url) and _file_cache.cached_file_exists(url):
		var promise = _file_cache.load_model_threaded(url)
		promise.connect_func_to_fulfill(_on_loaded_model_threaded.bind(url, promise))
		return promise
	var cached_file = _file_cache.try_load_cached_file(url)
	if cached_file:
		_set_file_data(url, cached_file)
		var promise = Promise.new()
		promise.set_result(cached_file)
		return promise
	if url.begins_with("res://"):
		var promise = Promise.new()
		if not ResourceLoader.exists(url):
			promise.set_error("Non existent local resource: %s" % url)
			return promise
		_set_file_data(url, load(url))
		if files[url] == null:
			promise.set_error("Error loading local resource: %s" % url)
		else:
			promise.set_result(files[url])
		return promise

	if _file_requests_queued.has(url):
		return _file_requests_queued.get(url)



	var promise = self.get_request_ext(GET_FILE, url, {"priority": priority})
	_file_requests_queued[url] = promise
	return promise


## Loads a model from the disk with a unique reference so it can be unloaded.
## Duplicating models was not working for instantiating an animated skeleton multiple times,
## so the model gets uniquely generated from a GLTFDocument.
## TODO: Assess storing GLTFDocument in memory and generating node from that instead of entire file read.
func get_model_instance_promise(url: String) -> Promise:
	return _file_cache.load_model_threaded(url)


func _promise_fulfill_successful(request: Dictionary, promise: Promise) -> void:
	match request["key"]:
		GET_FILE: _get_file_completed(request, promise)


## Success method called when an individual file is loaded.
func _get_file_completed(request: Dictionary, promise: Promise) -> void:
	_load_file_data(request, promise)
	var url: String = request["url"].uri_decode()
	if _file_requests_queued.has(url):
		_file_requests_queued.erase(url)


## Loads file data from a request dictionary.
## Checks the file's extension and calls the appropriate method.
func _load_file_data(request: Dictionary, promise: Promise) -> void:
	var url: String = request["url"].uri_decode()
	var body: PackedByteArray = request["body"]
	if Util.path_is_image(url):
		_load_response_body_as_image(body, url)
	elif Util.path_is_model(url):
		_load_response_body_as_gltf(body, url)
	elif Util.path_is_scene(url):
		_load_response_body_as_pck(body, url)
	elif Util.path_is_audio(url):
		_load_response_body_as_audio(body, url)
	elif Util.path_is_json(url):
		_load_response_body_as_json(body, url)
	var loaded_file = files.get(url)
	if loaded_file == null:
		promise.set_error("Unable to load a file: %s" % [url])
	else:
		promise.set_result(loaded_file)


## Loads a response body as an image texture and sets to the in memory files.
func _load_response_body_as_image(body: PackedByteArray, file_url: String) -> void:
	if Util.path_is_png(file_url):
		var texture: ImageTexture = Util.convert_png_bytes_to_texture(body)
		files[file_url] = texture
	elif Util.path_is_webp(file_url):
		var texture: ImageTexture = Util.convert_webp_bytes_to_texture(body)
		files[file_url] = texture
	elif Util.path_is_jpeg(file_url):
		var texture: ImageTexture = Util.convert_jpeg_bytes_to_texture(body)
		files[file_url] = texture
	var url_split = file_url.split("/")
	var file_name: String = url_split[url_split.size() - 1]
	var cache_key: String = file_url
	if file_url.contains("thumbnail.") and url_split.size() > 3:
		var asset_id = url_split[url_split.size() - 3]
		file_name = "%s_%s" % [asset_id, file_name]
	_file_cache.save_bytes_file_to_cache(cache_key, file_name, body)
	if Util.path_is_exr(file_url):
		# This is a workaround for exr, as loadin is not supported as raw buffer
		files[file_url] = _file_cache.try_load_cached_file(file_url)


## Loads a response body as a gltf or glb and sets to the in memory files.
func _load_response_body_as_gltf(body: PackedByteArray, file_url: String) -> void:
	var file_name: String = _get_file_name_from_url(file_url)
	_file_cache.save_bytes_file_to_cache(file_url, file_name, body)
	var node = _file_cache.try_load_cached_file(file_url)
	if node and node is Node:
		_set_file_data(file_url, node)


## Loads a response body as a pck and sets to the in memory files
func _load_response_body_as_pck(body: PackedByteArray, file_url: String) -> void:
	var file_name: String = _get_file_name_from_url(file_url)
	_file_cache.save_bytes_file_to_cache(file_url, file_name, body)
	var path_to_pck_file: String = _file_cache.get_file_path(file_name)
	var node = ScenePacker.get_unpacked_pck_as_node(path_to_pck_file)
	if node:
		_set_file_data(file_url, node)


## Loads a response body as a pck and sets to the in memory files
func _load_response_body_as_audio(body: PackedByteArray, file_url: String) -> void:
	var file_name: String = _get_file_name_from_url(file_url)
	_file_cache.save_bytes_file_to_cache(file_url, file_name, body)
	var path_to_audio_file: String = _file_cache.get_file_path(file_name)
	var stream = AudioLoader.loadfile(path_to_audio_file)
	if stream:
		_set_file_data(file_url, stream)


## Loads a response body as a pck and sets to the in memory files
func _load_response_body_as_json(body: PackedByteArray, file_url: String) -> void:
	var file_name: String = _get_file_name_from_url(file_url)
	_file_cache.save_bytes_file_to_cache(file_url, file_name, body)
	var path_to_json_file: String = _file_cache.get_file_path(file_name)
	_set_file_data(file_url, TMFileUtil.load_json_file(path_to_json_file))


func _set_file_data(file_url: String, file_data: Variant) -> void:
	files[file_url] = file_data
	if file_data is Node and file_url.ends_with(".pck"):
		_setup_node_pck_metadata(file_data)


func _setup_node_pck_metadata(node: Node) -> void:
	# The true doesn't actually matter, we later just check if the key exists.
	node.set_meta(&"from_pck", true)
	if node.has_meta(&"OMI_spawn_point") or TMNodeUtil.recursive_get_node_by_meta(node, &"OMI_spawn_point") != null:
		node.set_meta(&"has_omi_spawn_points", true)


func _get_file_name_from_url(file_url: String) -> String:
	var url_split: PackedStringArray = file_url.split("/")
	var file_name: String = url_split[url_split.size() - 1]
	return file_name


func _find_highest_priority_request() -> Variant:
	var priority: Enums.DownloadPriority = Enums.DownloadPriority.UNDEFINED
	# iterate through list to find highest priority item
	for r in _requests:
		var p = r.get("priority", Enums.DownloadPriority.UNDEFINED)
		if p > priority:
			priority = p
		if priority == Enums.DownloadPriority.HIGHEST:
			break
	# find the actual highest priority request
	for r in _requests:
		var p = r.get("priority", Enums.DownloadPriority.UNDEFINED)
		if p == priority:
			return r
	return null


# Overwritten in order to make sure request are handled in the order defined by PrioritizedQueue
func _process_request_queue() -> void:
	if self.is_request_queue_full() or _requests.is_empty():
		return
	var request = _find_highest_priority_request()
	if request == null:
		return
	_requests.erase(request)
	_make_request(request)
