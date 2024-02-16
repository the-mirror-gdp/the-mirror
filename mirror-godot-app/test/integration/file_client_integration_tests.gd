extends LoginIntegrationTest


# Data that is created when we run this test
var _test_asset_data: Dictionary
var _test_image_url: String
var _test_thumb_url: String
var _test_model_url: String
var _test_pck_url: String
var _test_wav_url: String
var _test_mp3_url: String
var _test_ogg_url: String

const GLB_FILE_PATH = "res://test/test_files/bench.glb"
const GLB2_FILE_PATH = "res://test/test_files/medieval.gltf"
const PCK_FILE_PATH = "res://test/test_files/test-packed-scene-file-2.pck"
const WAV_FILE_PATH = "res://test/test_files/test_wav.wav"
const MP3_FILE_PATH = "res://test/test_files/test_mp3.mp3"
const OGG_FILE_PATH = "res://test/test_files/test_ogg.ogg"


## Initializes the FileClient integration test queue.
func _init() -> void:
	_test_queue.append_array([
		&"login_firebase",
		&"test_create_asset",
		&"test_image_public_upload",
		&"test_thumb_upload",
		&"test_glb_public_upload",
		&"test_pck_public_upload",
		&"test_wav_public_upload",
		&"test_mp3_public_upload",
		&"test_ogg_public_upload",
		&"test_get_image",
		&"test_get_thumb",
		&"test_get_glb",
		&"test_get_pck",
		&"test_get_wav",
		&"test_get_mp3",
		# Blocked by engine bug. See: https://github.com/godotengine/godot/issues/61091
		#&"test_get_ogg",
		&"test_delete_asset",
		&"test_material_assets",
		&"test_download_priorities",
	])


func _fail_on_promise_error(promise: Promise) -> void:
	await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())


##  Test: Creates an asset to upload file data to.
func test_create_asset() -> void:
	var asset_data: Dictionary = {
		"name": "Test Asset",
		"assetType": Enums.ASSET_TYPE.MESH,
	}
	Net.asset_client.asset_created.connect(_asset_created_pass, CONNECT_ONE_SHOT)
	_fail_on_promise_error(Net.asset_client.create_asset(asset_data))


## Pass: asset creation test case pass method.
func _asset_created_pass(asset_data: Dictionary) -> void:
	_test_asset_data = asset_data
	test_passed("Created asset %s" % _test_asset_data["_id"])


## Test: Uploads a WebP image to the REST server.
func test_image_public_upload() -> void:
	var image = load("res://test/test_files/test-image.webp")
	var image_bytes = Util.get_webp_data(image)
	var promise = Net.asset_client.upload_asset_image_public(_test_asset_data["_id"], image_bytes)
	var asset_entity = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	_test_image_url = asset_entity["currentFile"]
	test_passed(_test_image_url)


## Test: Uploads a thumbnail image to the REST server.
func test_thumb_upload() -> void:
	var image = load("res://test/test_files/test-image.webp")
	var image_bytes = Util.get_webp_data(image)
	var promise = Net.asset_client.upload_asset_thumb(_test_asset_data["_id"], image_bytes, "image/webp")
	var asset_entity = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	_test_thumb_url = asset_entity["thumbnail"]
	test_passed(_test_image_url)


## Tests uploading a GLB model to the RESTful server.
func test_glb_public_upload() -> void:
	var model_bytes = TMFileUtil.load_file_bytes(GLB_FILE_PATH)
	var promise = Net.asset_client.upload_file_public(_test_asset_data["_id"], model_bytes, "model/gltf-binary")
	var asset_entity = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	_test_model_url = asset_entity["currentFile"]
	test_passed(_test_model_url)



## Tests uploading a PCK file to the RESTful server.
func test_pck_public_upload() -> void:
	var pck_bytes = TMFileUtil.load_file_bytes(PCK_FILE_PATH)
	var promise = Net.asset_client.upload_file_public(_test_asset_data["_id"], pck_bytes, "application/scene-binary")
	var asset_entity = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	_test_pck_url = asset_entity["currentFile"]
	test_passed(_test_pck_url)

## Tests uploading a WAV file to the RESTful server.
func test_wav_public_upload() -> void:
	var wav_bytes = TMFileUtil.load_file_bytes(WAV_FILE_PATH)
	var promise = Net.asset_client.upload_file_public(_test_asset_data["_id"], wav_bytes, "audio/wav")
	var asset_entity = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	_test_wav_url = asset_entity["currentFile"]
	test_passed(_test_wav_url)


## Tests uploading a MP3 file to the RESTful server.
func test_mp3_public_upload() -> void:
	var mp3_bytes = TMFileUtil.load_file_bytes(MP3_FILE_PATH)
	var promise = Net.asset_client.upload_file_public(_test_asset_data["_id"], mp3_bytes, "audio/mpeg")
	var asset_entity = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	_test_mp3_url = asset_entity["currentFile"]
	test_passed(_test_mp3_url)



## Tests uploading a OGG file to the RESTful server.
func test_ogg_public_upload() -> void:
	var ogg_bytes = TMFileUtil.load_file_bytes(OGG_FILE_PATH)
	var promise = Net.asset_client.upload_file_public(_test_asset_data["_id"], ogg_bytes, "audio/ogg")
	var asset_entity = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	_test_ogg_url = asset_entity["currentFile"]
	test_passed(_test_ogg_url)


## Test: Downloads a previously uploaded GLB file
func test_get_glb() -> void:
	var promise = Net.file_client.get_file(_test_model_url)
	var file = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	if file is Node:
		test_passed(_test_model_url)
	else:
		test_failed("GLB file received but could not load cached file.")


## Test: Downloads a previously uploaded image/PNG file
func test_get_image() -> void:
	var promise = Net.file_client.get_file(_test_image_url)
	await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	test_passed(_test_image_url)


## Test: Downloads a previously uploaded thumbnail file
func test_get_thumb() -> void:
	var promise = Net.file_client.get_file(_test_thumb_url)
	await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	test_passed(_test_thumb_url)


## Test: Downloads a previously uploaded PCK file
func test_get_pck() -> void:
	var promise = Net.file_client.get_file(_test_pck_url)
	await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	test_passed(_test_pck_url)


## Test: Downloads a previously uploaded WAV file
func test_get_wav() -> void:
	var promise = Net.file_client.get_file(_test_wav_url)
	await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	test_passed(_test_wav_url)


## Test: Downloads a previously uploaded MP3 file
func test_get_mp3() -> void:
	var promise = Net.file_client.get_file(_test_mp3_url)
	await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	test_passed(_test_mp3_url)


## Test: Downloads a previously uploaded OGG file
func test_get_ogg() -> void:
	var promise = Net.file_client.get_file(_test_ogg_url)
	await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	test_passed(_test_ogg_url)


## Test: Deletes an asset
func test_delete_asset() -> void:
	Net.asset_client.asset_deleted.connect(_asset_deleted_pass, CONNECT_ONE_SHOT)
	_fail_on_promise_error(Net.asset_client.delete_asset(_test_asset_data["_id"]))


## Pass: Deleted the asset
func _asset_deleted_pass(asset_data: Dictionary) -> void:
	test_passed("Deleted asset %s" % asset_data["_id"])
	Net.file_client._file_cache.delete_cache()



func test_material_assets() -> void:
	var mat_test = MaterialTexturesAssetTest.new(self)
	mat_test.test_material_assets()


func test_download_priorities() -> void:
	var priorities_test = DownloadPrioritiesTest.new(self)
	priorities_test.test_download_priorities()


class MaterialTexturesAssetTest extends Object:

	var _material_data: Dictionary = {
		"name": "Test Asset - DiamondPlate006C",
		"tagsV2": ["63e88dde69680a48ef73ce4e", "63e87c9413ab8049e8eb8ddc" ],
		"thumb_file": "res://test/test_files/material/DiamondPlate006C_PREVIEW.jpg"
	}
	var _test_textures: Dictionary = {
		"albedo_texture": {
			"name": "Test Asset - DiamondPlate006C_1K_Color",
			"file": "res://test/test_files/material/DiamondPlate006C_1K_Color.jpg",
			"thumb_file": "res://test/test_files/material/DiamondPlate006C_1K_Color_thumb.jpg"
		},
		"normal_texture": {
			"name": "Test Asset - DiamondPlate006C_1K_NormalGL",
			"file": "res://test/test_files/material/DiamondPlate006C_1K_NormalGL.jpg",
			"thumb_file": "res://test/test_files/material/DiamondPlate006C_1K_NormalGL_thumb.jpg"
		},
		"metallic_texture": {
			"name": "Test Asset - DiamondPlate006C_1K_Metalness",
			"file": "res://test/test_files/material/DiamondPlate006C_1K_Metalness.jpg",
			"thumb_file": "res://test/test_files/material/DiamondPlate006C_1K_Metalness_thumb.jpg"
		},
		"roughness_texture": {
			"name": "Test Asset - DiamondPlate006C_1K_Roughness",
			"file": "res://test/test_files/material/DiamondPlate006C_1K_Roughness.jpg",
			"thumb_file": "res://test/test_files/material/DiamondPlate006C_1K_Roughness_thumb.jpg"
		}
	}

	var _test_textures_tagsv2 = ["63e88dde69680a48ef73ce4e"]
	var _file_integration_tests
	var _textures_asssets_ids: Array[String] = []
	var _material_asset_data: Dictionary


	func _init(in_file_integration_tests) -> void:
		_file_integration_tests = in_file_integration_tests


	func test_failed(payload = null) -> void:
		_file_integration_tests.test_failed(payload)


	func test_passed(payload = null) -> void:
		_file_integration_tests.test_passed(payload)

	func _fail_on_promise_error(promise: Promise) -> void:
		await promise.wait_till_fulfilled()
		if promise.is_error():
			test_failed(promise.get_error_message())


	func test_material_assets() -> void:
		await _create_material_asset()
		await _get_material_asset()
		await _delete_material_assets()
		test_passed("All material asset tests passed")


	func _create_texture_asset(name: String, property: String, file: String, thumb_file: String) -> String:
		print("Uploading: ", name)
		# 1. Create texture asset
		var asset_data: Dictionary = {
			"name": name,
			"assetType": Enums.ASSET_TYPE.TEXTURE,
			"textureImagePropertyAppliesTo": property,
			"tagsV2": _test_textures_tagsv2,
			"mirrorPublicLibrary": false
		}
		_fail_on_promise_error(Net.asset_client.create_asset(asset_data))
		var _test_asset_texture_data = await(Net.asset_client.asset_created)

		# 2. Upload image
		var image = load(file)
		# image will be converted to webp
		var image_bytes = Util.get_webp_data(image)
		var promise_tex1 = Net.asset_client.upload_asset_image_public(_test_asset_texture_data["_id"], image_bytes)
		var _test_tex_image  = await promise_tex1.wait_till_fulfilled()

		# 3. Upload thumbnail image
		var image_thumb = load(thumb_file)
		# image will be converted to webp
		var image_thumb_bytes = Util.get_webp_data(image_thumb)
		var promise_thumb = Net.asset_client.upload_asset_thumb(_test_asset_texture_data["_id"], image_thumb_bytes, "image/webp")
		var _test_tex_thumb_image = await promise_thumb.wait_till_fulfilled()

		return _test_asset_texture_data["_id"]


	func _create_material_asset() -> void:
		# 1. Delete existing files
		Net.file_client._file_cache.delete_cache()

		# 2. Create all necessary textures for material
		for tex_type in _test_textures:
			var tex = _test_textures[tex_type]
			var asset_id = await(_create_texture_asset(tex["name"], tex_type, tex["file"], tex["thumb_file"]))
			_textures_asssets_ids.append(asset_id)

		# 3. Create Material Asset
		var asset_data: Dictionary = {
			"name": _material_data["name"],
			"assetType": Enums.ASSET_TYPE.MATERIAL,
			"textures": _textures_asssets_ids,
			"tagsV2": _material_data["tagsV2"],
			"mirrorPublicLibrary": false
		}
		_fail_on_promise_error(Net.asset_client.create_asset(asset_data))
		_material_asset_data = await(Net.asset_client.asset_created)

		# 3. Upload Material thumbnail
		var image = load(_material_data["thumb_file"])
		# image will be converted to webp
		var image_bytes = Util.get_webp_data(image)
		var promise = Net.asset_client.upload_asset_thumb(_material_asset_data["_id"], image_bytes, "image/webp")
		var image_thumb = await promise.wait_till_fulfilled()


	func _get_material_asset() -> void:
		if not _material_asset_data.has("_id"):
			print("Missing material id")
			test_failed("Missing material id")
			return
		_fail_on_promise_error(Net.asset_client.queue_download_asset(_material_asset_data["_id"]))
		var mat_asset_data = await(Net.asset_client.asset_received)

		if not mat_asset_data.has("textures") or not mat_asset_data["textures"] is Array:
			print("Missing textures or incorrect format")
			test_failed("Missing textures or incorrect format")
			return

		if mat_asset_data["textures"].size() != _test_textures.size():
			print("Incorrect number of textures")
			test_failed("Incorrect number of textures")
			return

		# Get all textures assets
		for tex_asset_id in mat_asset_data["textures"]:
			_fail_on_promise_error(Net.asset_client.queue_download_asset(tex_asset_id))
			var tex_asset_data = await(Net.asset_client.asset_received)


	func _delete_material_assets():
		if not _material_asset_data.has("_id"):
			print("Missing material id")
			test_failed("Missing material id")
			return
		# 1. Detele material asset
		_fail_on_promise_error(Net.asset_client.delete_asset(_material_asset_data["_id"]))
		var mat_ass_deleted = await(Net.asset_client.asset_deleted)

		# 2. Detele texture assets
		for tex_asset_id in _textures_asssets_ids:
			_fail_on_promise_error(Net.asset_client.delete_asset(tex_asset_id))
			var mat_tex_deleted = await(Net.asset_client.asset_deleted)

		Net.file_client._file_cache.delete_cache()


# Inner class containing test for download priorities
class DownloadPrioritiesTest extends Object:
	var _file_integration_tests
	var _pck_url = ""
	var _glb1_url = ""
	var _glb2_url = ""
	var _already_downloaded_files = []
	var _max_parallel_requests_backup = -1


	func _init(in_file_integration_tests) -> void:
		_file_integration_tests = in_file_integration_tests


	func test_failed(payload = null) -> void:
		_file_integration_tests.test_failed(payload)
		GameplaySettings.concurrent_http_requests = _max_parallel_requests_backup


	func test_passed(payload = null) -> void:
		_file_integration_tests.test_passed(payload)
		GameplaySettings.concurrent_http_requests = _max_parallel_requests_backup

	func _fail_on_promise_error(promise: Promise) -> void:
		await promise.wait_till_fulfilled()
		if promise.is_error():
			test_failed(promise.get_error_message())


	func test_download_priorities() -> void:
		# 0. Disable parallel downloads to test order
		_max_parallel_requests_backup = GameplaySettings.concurrent_http_requests
		GameplaySettings.concurrent_http_requests = 1

		# 1. Delete existing files
		Net.file_client._file_cache.delete_cache()

		# 1.5 Disconnect anything that might be triggered by creation in asset
		for callable in Net.asset_client.asset_created.get_connections():
			Net.asset_client.asset_created.disconnect(callable["callable"])


		# 2. Create new assets containers
		var asset_data: Dictionary = {
			"name": "Test Asset PCK",
			"assetType": Enums.ASSET_TYPE.MESH,
		}
		_fail_on_promise_error(Net.asset_client.create_asset(asset_data))
		var _test_pck_asset_data = await(Net.asset_client.asset_created)

		var asset_data_glb1: Dictionary = {
			"name": "Test Asset GLB1",
			"assetType": Enums.ASSET_TYPE.MESH,
		}
		_fail_on_promise_error(Net.asset_client.create_asset(asset_data_glb1))
		var _test_glb1_asset_data = await(Net.asset_client.asset_created)

		var asset_data_glb2: Dictionary = {
			"name": "Test Asset GLB2",
			"assetType": Enums.ASSET_TYPE.MESH,
		}
		_fail_on_promise_error(Net.asset_client.create_asset(asset_data_glb2))
		var _test_glb2_asset_data = await(Net.asset_client.asset_created)


		# 2.5 Download all assets again. This makes sure that all events
		# that are listening are already connected.
		# Hours wasted here: 3
		var promise = Net.asset_client.queue_download_asset(_test_pck_asset_data["_id"])
		await promise.wait_till_fulfilled()
		promise = Net.asset_client.queue_download_asset(_test_glb1_asset_data["_id"])
		await promise.wait_till_fulfilled()
		promise = Net.asset_client.queue_download_asset(_test_glb2_asset_data["_id"])
		await promise.wait_till_fulfilled()

		# Disconnect anything that might be triggered by change in asset
		for callable in Net.asset_client.asset_updated.get_connections():
			Net.asset_client.asset_updated.disconnect(callable["callable"])

		# 3. Upload data to the asset containers
		var pck_bytes = TMFileUtil.load_file_bytes(PCK_FILE_PATH)
		var promise_pck_up = Net.asset_client.upload_file_public(_test_pck_asset_data["_id"], pck_bytes, "application/scene-binary")
		var result_pck = await promise_pck_up.wait_till_fulfilled()
		_pck_url = result_pck["currentFile"]

		# glb 1
		var model_bytes = TMFileUtil.load_file_bytes(GLB_FILE_PATH)
		var promise_glb1_up = Net.asset_client.upload_file_public(_test_glb1_asset_data["_id"], model_bytes, "model/gltf-binary")
		var result_glb1 = await promise_glb1_up.wait_till_fulfilled()
		_glb1_url = result_glb1["currentFile"]

		# glb 2
		var model2_bytes = TMFileUtil.load_file_bytes(GLB2_FILE_PATH)
		var promise_glb2_up = Net.asset_client.upload_file_public(_test_glb2_asset_data["_id"], model2_bytes, "model/gltf-binary")
		var result_glb2 = await promise_glb2_up.wait_till_fulfilled()
		_glb2_url = result_glb2["currentFile"]

		# 4. Actually start prioritized download test

		# should be downloaded second
		var promise_pck = Net.file_client.get_file(_pck_url, Enums.DownloadPriority.SPACE_OBJECT_MEDIUM)
		promise_pck.connect_func_to_fulfill(_download_priorities_pck_file_downloaded.bind(promise_pck, _pck_url))

		# should be downloaded last
		var promise_glb1 = Net.file_client.get_file(_glb1_url, Enums.DownloadPriority.DEFAULT)
		promise_glb1.connect_func_to_fulfill(_download_priorities_glb1_file_downloaded.bind(promise_glb1, _glb1_url))

		# should be downloaded first
		var promise_glb2 = Net.file_client.get_file(_glb2_url, Enums.DownloadPriority.SPACE_OBJECT_HIGH)
		promise_glb2.connect_func_to_fulfill(_download_priorities_glb2_file_downloaded.bind(promise_glb2, _glb2_url))


	func _download_priorities_pck_file_downloaded(promise: Promise, file_url: String) -> void:
		if promise.is_error():
			test_failed(promise.get_error_message())
			return
		if _already_downloaded_files.size() != 1:
			test_failed("PCK file had medium priority, should be downloaded second.")
		_already_downloaded_files.append(file_url)


	func _download_priorities_glb1_file_downloaded(promise: Promise, file_url: String) -> void:
		if promise.is_error():
			test_failed(promise.get_error_message())
			return
		if _already_downloaded_files.size() != 2:
			test_failed("GLB1 file had lowest priority, should be downloaded last.")
			return
		_already_downloaded_files.append(file_url)
		test_passed("All files downloaded in the right order")
		Net.file_client._file_cache.delete_cache()


	func _download_priorities_glb2_file_downloaded(promise: Promise, file_url: String) -> void:
		if promise.is_error():
			test_failed(promise.get_error_message())
			return
		if _already_downloaded_files.size() != 0:
			test_failed("GLB2 file had highest priority, should be downloaded first.")
		_already_downloaded_files.append(file_url)
