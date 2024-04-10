class_name FileCache
extends Node

signal threaded_model_loaded(cache_key: String, node: Node)

const _STORAGE_CACHE_FILENAME: String = "cache.json"

var _storage_cache: Dictionary = {}

var _model_load_queue: Array[KeyPromisePair] = []

class KeyPromisePair:
	extends RefCounted
	var key
	var promise

## Initializes and loads the file cache library json into memory on startup.
func _init() -> void:
	# wait a bit to ensure is status of this aplication is determined (server or client)
	await Zone.wait_till_booted()
	_load_stored_files_cache()
	_setup_storage_directory()



func _process(_delta: float) -> void:
	_manage_queue()


## Manages the threaded model loading queue.
func _manage_queue() -> void:
	if _model_load_queue.size() == 0:
		return
	_thread_load_model(_model_load_queue.pop_front())


## Returns true if the cache file exists on the disk.
func cached_file_exists(cache_key: String) -> bool:
	cache_key = cache_key.uri_decode()
	if not _storage_cache.has(cache_key):
		return false
	var file_name: String = _storage_cache[cache_key]
	var file_path: String = get_file_path(file_name)
	var file_exists = FileAccess.file_exists(file_path)
	if file_exists:
		_storage_cache[cache_key] = file_name
	return file_exists


## Returns the path to cached file or empty in case of error.
func get_cached_file_path(cache_key: String) -> String:
	cache_key = cache_key.uri_decode()
	if not _storage_cache.has(cache_key):
		return ""
	var file_name: String = _storage_cache[cache_key]
	var file_path: String = get_file_path(file_name)
	return file_path


## Deletes the entire file cache.
func delete_cache() -> void:
	var directory: DirAccess = DirAccess.open(Util.get_files_directory_path())
	for cache_key in _storage_cache:
		var file_name: String = _storage_cache[cache_key]
		var file_path: String = get_file_path(file_name)
		var _err = directory.remove(file_path)
		if _err != OK:
			printerr("FileCache.delete_cache(): File could not be removed: ", file_path)
	_storage_cache.clear()
	_save_stored_files_cache()


## Creates the file storage directory if it does not exist yet.
func _setup_storage_directory() -> void:
	if not DirAccess.dir_exists_absolute(Util.get_files_directory_path()):
		var _err = DirAccess.make_dir_absolute(Util.get_files_directory_path())
	if not DirAccess.dir_exists_absolute(Util.get_primitive_models_directory_path()):
		var _err = DirAccess.make_dir_absolute(Util.get_primitive_models_directory_path())
	if not DirAccess.dir_exists_absolute(Util.get_screenshots_directory_path()):
		var _err = DirAccess.make_dir_absolute(Util.get_screenshots_directory_path())


## Loads the file cache library json into memory.
func _load_stored_files_cache() -> void:
	var storage_cache = TMFileUtil.load_json_file(get_file_path(_STORAGE_CACHE_FILENAME))
	if storage_cache and storage_cache is Dictionary:
		_storage_cache = storage_cache


## Saves the file cache library json to disk.
func _save_stored_files_cache() -> void:
	var file = FileAccess.open(get_file_path(_STORAGE_CACHE_FILENAME), FileAccess.WRITE)
	file.store_string(JSON.stringify(_storage_cache))
	file.flush()


## Saves a bytes file to the cache location on disk and adds it to the cache library.
func save_bytes_file_to_cache(cache_key: String, file_name: String, file_data: PackedByteArray) -> void:
	var saved = save_bytes_file(file_name, file_data)
	if not saved:
		return
	_storage_cache[cache_key] = file_name
	_save_stored_files_cache()


## Saves a bytes file to the path on disk and adds it to the cache library.
func save_bytes_file(file_name: String, file_data: PackedByteArray) -> bool:
	var file: FileAccess = FileAccess.open(get_file_path(file_name), FileAccess.WRITE)
	if file == null:
		return false
	file.store_buffer(file_data)
	file.flush()
	return true


## Gets a locally stored cache file path for a file name.
func get_file_path(file_name: String) -> String:
	var storage_path_format = Util.get_files_directory_path() + "%s"
	return storage_path_format % file_name


## Tries to load a file into memory from disk cache and returns the payload or null.
func try_load_cached_file(cache_key: String) -> Variant:
	cache_key = cache_key.uri_decode()
	if not _storage_cache.has(cache_key):
		return null
	var file_name: String = _storage_cache[cache_key]
	var file_path: String = get_file_path(file_name)
	if not FileAccess.file_exists(file_path):
		return null
	if Util.path_is_model(file_path):
		return TMFileUtil.load_gltf_file_as_node(file_path, Zone.is_host())
	elif Util.path_is_image(file_path):
		return Util.load_image(file_path)
	elif Util.path_is_scene(file_path):
		return ScenePacker.get_unpacked_pck_as_node(file_path)
	elif Util.path_is_audio(file_path):
		return Util.load_audio(file_path)
	elif Util.path_is_json(file_path):
		return TMFileUtil.load_json_file(file_path)
	return null


func load_model_threaded(cache_key: String) -> Promise:
	for m in _model_load_queue:
		if m.key == cache_key:
			return m.promise
	var pair = KeyPromisePair.new()
	pair.key = cache_key
	pair.promise = Promise.new()

	# TODO: Fix multithreaded model loading, newer engine versions
	# complain about this not being on the main thread.
	# queue for later when needed
	if cached_file_exists(pair.key):
		_model_load_queue.append(pair)
		return pair.promise

#	_model_load_thread.start(_thread_load_model.bind(pair))
	_thread_load_model(pair)
	return pair.promise


func _thread_load_model(pair: KeyPromisePair) -> void:
	if not cached_file_exists(pair.key):
		pair.promise.set_error("File does not exists, cannot load.")
		return
	var file_name: String = _storage_cache.get(pair.key, "")
	var file_path: String = get_file_path(file_name)
	var node = TMFileUtil.load_gltf_file_as_node(file_path, Zone.is_host())
	_model_loaded.call_deferred(pair, node)


func _model_loaded(pair: KeyPromisePair, node: Node) -> void:
	threaded_model_loaded.emit(pair.key, node)
	pair.promise.set_result(node)
