class_name AssetClient
extends MirrorHttpClient


var _net_assets: Dictionary = Dictionary()
var _local_assets: Dictionary = Dictionary()

const PER_PAGE = 36

const _LOCAL_ASSETS_CFG_PATH: String = "res://local_assets_data.cfg"

signal asset_created(asset_data)
signal asset_received(asset_data)
signal asset_updated(asset_data)
signal asset_deleted(asset_data)
signal recent_assets_received(recent_assets_data: Array)


enum AssetRequestType {
	GET_ASSET,
	GET_PUBLIC_LIBRARY_TAGS,
	GET_MY_ASSETS,
	GET_MIRROR_ASSETS,
	GET_MY_LIBRARY,
	GET_RECENT_ASSETS,
	CREATE_ASSET,
	UPDATE_ASSET,
	DELETE_ASSET,
	UPDATE_ASSET_TAG,
	DELETE_ASSET_TAG,
	UPLOAD_FILE,
	UPLOAD_THUMB,
}


func _load_local_asssets_config() -> void:
	var loc_assets_cfg: ConfigFile = ConfigFile.new()
	if loc_assets_cfg.load(_LOCAL_ASSETS_CFG_PATH) != OK:
		print("Error opening local assets data store: %s" % _LOCAL_ASSETS_CFG_PATH)
	for l_asset_data in loc_assets_cfg.get_value("mirror", "assets_data", []):
		_local_assets[l_asset_data['_id']] = l_asset_data


func _init():
	_load_local_asssets_config()


func get_local_assets(search="", type="", tag="") -> Array:
	var filtered: Array[Dictionary] = []
	for asset_id in _local_assets:
		var asset = _local_assets[asset_id]
		if not asset.has("name") or not asset.has("assetType") or not asset.has("tags"):
			continue
		if (
				( search.to_lower() in asset["name"].to_lower() or search == "" )
				and ( asset["assetType"] == type or type == "" )
				and ( asset["tags"].has(tag.to_lower()) or tag == "" )
		):
			filtered.append(asset)
	return filtered


var _last_search_text : String = ""

func _get_assets_list(request_type: int, params: AssetListRequestParameters) -> Promise:
	@warning_ignore("static_called_on_instance")
	var url_params: String = _get_paginated_search_params(params)
	var request_type_string = {
		AssetRequestType.GET_MY_ASSETS: "my-assets-v2",
		AssetRequestType.GET_MIRROR_ASSETS: "mirror-assets-v2",
		AssetRequestType.GET_MY_LIBRARY: "my-library-v2"
	}.get(request_type, "my-assets-v2")
	var url: String = "/asset/%s?%s" % [request_type_string, url_params]
	var aux: Dictionary = params.serialize()
	return self.get_request(request_type, url, aux)
	if _last_search_text != params.search:
		Analytics.track_event_client(AnalyticsEvent.TYPE.SEARCH_ASSET, {"search_text" : params.search, "page" : params.page})
		_last_search_text = params.search


func get_my_assets(params: AssetListRequestParameters) -> Promise:
	return _get_assets_list(AssetRequestType.GET_MY_ASSETS, params)


func get_mirror_assets(params: AssetListRequestParameters) -> Promise:
	return _get_assets_list(AssetRequestType.GET_MIRROR_ASSETS, params)


func get_library_assets(params: AssetListRequestParameters) -> Promise:
	return _get_assets_list(AssetRequestType.GET_MY_LIBRARY, params)


func get_recent_assets() -> Promise:
	var request_type: int = AssetRequestType.GET_RECENT_ASSETS
	var url: String = "/asset/recent?limit=20"
	var params = Net.asset_client.AssetListRequestParameters.new()
	params.page = 1
	var aux: Dictionary = params.serialize()
	return self.get_request(request_type, url, aux)


static func _get_paginated_search_params(params: AssetListRequestParameters) -> String:
	params.page = maxi(params.page, 1)
	var st_fmt: String = "page=%d" % params.page if params.start_by_item < 0 else "startItem=%d" % params.start_by_item
	var per_pg_fmt: String = "&perPage=%d" % params.per_page if params.start_by_item < 0 else "&numberOfItems=%d" % params.per_page
	var field_fmt: String = params.field if params.field.is_empty() else "&field=%s" % params.field.uri_encode()
	var search_fmt: String = params.search if params.search.is_empty() else "&search=%s" % params.search.uri_encode()
	var type_fmt: String = params.type if params.type.is_empty() else "&assetTypes=%s" % params.type.uri_encode()
	var tag_fmt: String = ""
	if params.tags.size() != 0 and not params.order.is_empty():
		var tags_preprocess = params.tags.map(func(x): return "&tag=%s" % x)
		tag_fmt = "&tagType=%s" % params.tag_type + "".join(tags_preprocess)
	var sort_by_fmt: String = params.sort_by if params.sort_by.is_empty() else "&sortKey=%s" % params.sort_by.uri_encode()
	var order_fmt: String = params.order if params.order.is_empty() else "&sortDirection=%s" % params.order.uri_encode()
	return "%s%s%s%s%s%s%s%s" % [st_fmt, per_pg_fmt, search_fmt, field_fmt, type_fmt, tag_fmt, sort_by_fmt, order_fmt]


func get_public_library_tags() -> Promise:
	return self.get_request(AssetRequestType.GET_PUBLIC_LIBRARY_TAGS, "/tag/mirror-public-library")


## Creates an asset that will belong to the current user.
func create_asset(asset_data: Dictionary) -> Promise:
	return self.post_request(AssetRequestType.CREATE_ASSET, "/asset", asset_data)


## Downloads an asset with the provided asset id.
func queue_download_asset(asset_id: String, priority: Enums.DownloadPriority = Enums.DownloadPriority.DEFAULT) -> Promise:
	if asset_id in _local_assets:
		print_debug("Failure: Can't http request local assset")
		var error_promise = Promise.new()
		error_promise.set_error("Failure: Can't http request local assset")
		return error_promise
	var url = "/asset/%s" % asset_id
	return self.get_request(AssetRequestType.GET_ASSET, url, {"priority": priority})


func get_asset_file(asset_id: String) -> Variant:
	var asset_json: Dictionary = get_asset_json(asset_id)
	if asset_json.is_empty():
		var asset_promise: Promise = queue_download_asset(asset_id)
		await asset_promise.wait_till_fulfilled()
		if asset_promise.is_error():
			return null
		asset_json = get_asset_json(asset_id)
	if not asset_json.has("currentFile"):
		return null
	var file_url: String = asset_json["currentFile"]
	var file_promise: Promise = Net.file_client.get_file(file_url)
	await file_promise.wait_till_fulfilled()
	if file_promise.is_error():
		return null
	return file_promise.get_result()


## Updates an asset given the asset id and data dictionary.
func update_asset(asset_id: String, asset_data: Dictionary) -> Promise:
	if asset_id in _local_assets:
		print_debug("Failure: Can't update local asset")
		return
	return self.patch_request(AssetRequestType.UPDATE_ASSET, "/asset/%s" % asset_id, asset_data)


## Uploads an image that will belong to the asset of the provided asset_id.
func upload_asset_image_public(asset_id: String, image_bytes: PackedByteArray) -> Promise:
	return upload_file_public(asset_id, image_bytes, "image/webp")


## Uploads a file that will belong to the asset of the provided asset_id.
func upload_file_public(asset_id: String, file_bytes: PackedByteArray, mime: String) -> Promise:
	var url: String = "/asset/%s/upload/public" % asset_id
	@warning_ignore("static_called_on_instance")
	var request_body: PackedByteArray = self.get_form_data(file_bytes, mime)
	return self.post_request(AssetRequestType.UPLOAD_FILE, url, request_body)


## Uploads an image that will belong to the asset of the provided asset_id.
func upload_asset_thumb(asset_id: String, image_bytes: PackedByteArray, mime = "image/webp") -> Promise:
	var url: String = "/asset/%s/upload/thumbnail" % asset_id
	@warning_ignore("static_called_on_instance")
	var request_body: PackedByteArray = self.get_form_data(image_bytes, mime)
	return self.post_request(AssetRequestType.UPLOAD_THUMB, url, request_body)


## Deletes an asset with the provided asset id.
func delete_asset(asset_id: String) -> Promise:
	if asset_id in _local_assets:
		print_debug("Failure: Can't delete local asset")
		return
	return self.delete_request(AssetRequestType.DELETE_ASSET, "/asset/%s" % asset_id)


func update_asset_tag(asset_id: String, asset_tags_data: Dictionary) -> Promise:
	if asset_id in _local_assets:
		print_debug("Failure: Can't update local asset")
		return
	asset_tags_data["assetId"] = asset_id
	return self.post_request(AssetRequestType.UPDATE_ASSET_TAG, "/asset/tag" , asset_tags_data)


func delete_asset_tag(asset_id: String, tag_type: String, tag_name: String) -> Promise:
	if asset_id in _local_assets:
		print_debug("Failure: Can't delete local asset")
		return
	return self.delete_request(AssetRequestType.DELETE_ASSET_TAG, "/asset/tag/%s/%s/%s" % [asset_id, tag_type, tag_name])



func get_asset_json(asset_id: String) -> Dictionary:
	if asset_id in _local_assets:
		return _local_assets[asset_id]
	if asset_id in _net_assets:
		return _net_assets[asset_id]
	return {}


func set_asset_json(asset_id: String, asset_json: Dictionary) -> void:
	_net_assets[asset_id] = asset_json


func get_asset_url(asset_id: String) -> String:
	return get_asset_json(asset_id).get("currentFile", "")


func populate_space_object_dict_with_name(space_object_dict: Dictionary) -> void:
	if "name" in space_object_dict and not space_object_dict["name"].is_empty():
		return # If there is already a name, prefer that.
	var asset_id: String = space_object_dict["asset"]
	# Use the asset's name, or fallback to "New Object".
	var asset_json: Dictionary = get_asset_json(asset_id)
	space_object_dict["name"] = asset_json.get("name", "New Object")



func _promise_fulfill_successful(request: Dictionary, promise: Promise) -> void:
	var json_result = request.get("json_result")
	if request.get("key") in [AssetRequestType.UPDATE_ASSET_TAG]:
		json_result = request.get("code")
	if json_result == null:
		push_error("AssetClient request succeeded but parsed result is null. %s" % str(request))
		promise.set_error("AssetClient request succeeded but parsed result is null. %s" % str(request))
		return
	# We emit a signals for events that should be broadcasted
	match request["key"]:
		AssetRequestType.GET_ASSET:
			_get_asset_completed(request)
			asset_received.emit(json_result)
		AssetRequestType.CREATE_ASSET:
			_create_asset_completed(json_result)
			asset_created.emit(json_result)
		AssetRequestType.UPDATE_ASSET:
			_update_asset_completed(json_result)
			asset_updated.emit(json_result)
		AssetRequestType.DELETE_ASSET:
			_delete_asset_completed(json_result)
			asset_deleted.emit(json_result)
		AssetRequestType.UPLOAD_FILE:
			_upload_file_public_completed(json_result)
			asset_updated.emit(json_result)
		AssetRequestType.UPLOAD_THUMB:
			_upload_thumb_completed(json_result)
			#asset_updated.emit(json_result)
		AssetRequestType.GET_MY_ASSETS:
			_get_my_assets_completed(request, promise)
			return
		AssetRequestType.GET_MY_LIBRARY:
			_get_my_library_completed(request, promise)
			return
		AssetRequestType.GET_MIRROR_ASSETS:
			_get_mirror_assets_completed(request, promise)
			return
		AssetRequestType.GET_RECENT_ASSETS:
			_get_recent_assets_completed(request, promise)
			return
		#GET_PUBLIC_LIBRARY_TAGS:
		#	pass
	promise.set_result(json_result)


## Success method called when file upload is complete.
func _upload_file_public_completed(asset_data: Dictionary) -> void:
	_update_local_asset(asset_data)


## Success method called when thumb upload is complete.
func _upload_thumb_completed(asset_data: Dictionary) -> void:
	_update_local_asset(asset_data)


func _update_self_assets(user_assets: Array) -> void:
	for asset in user_assets:
		@warning_ignore("return_value_discarded", "static_called_on_instance")
		_http_unescape_asset_data(asset)
		var asset_id = asset.get("_id", "")
		_net_assets[asset_id] = asset


func _get_my_library_completed(request: Dictionary, promise: Promise) -> void:
	var assets_page: Dictionary = _get_assets_page_from_request(request, "my_library")
	promise.set_result(assets_page)


func _get_my_assets_completed(request: Dictionary, promise: Promise) -> void:
	var assets_page: Dictionary = _get_assets_page_from_request(request, "my_assets")
	promise.set_result(assets_page)


func _get_mirror_assets_completed(request: Dictionary, promise: Promise) -> void:
	var assets_page: Dictionary = _get_assets_page_from_request(request, "mirror")
	promise.set_result(assets_page)


func _get_recent_assets_completed(request: Dictionary, promise: Promise) -> void:
	if not request.has("body"):
		promise.set_error("Response did not have a body.")
	var body_str: String = request["body"].get_string_from_utf8()
	var recent_assets_data: Array = JSON.parse_string(body_str)
	promise.set_result(recent_assets_data)
	recent_assets_received.emit(recent_assets_data)


func _get_assets_page_from_request(request: Dictionary, source: String) -> Dictionary:
	var assets_page: Dictionary = _http_unescape_assets_page(request["json_result"])
	assets_page["source"] = source
	assets_page["field"] = request.get("field", "")
	assets_page["search"] = request.get("search", "")
	assets_page["type"] = request.get("type", "")
	assets_page["tag"] = request.get("tag", "")
	assets_page["sort_by"] = request.get("sort_by", "")
	assets_page["order"] = request.get("order", "")
	assets_page["tags"] = request.get("tagsV2", [])
	var tagv2_text = ",".join(assets_page["tags"])
	assets_page["cache_key"] = "%s_%s_%s_%s_%s_%s_%s_%s" % [assets_page["source"],
			assets_page["search"], assets_page["field"], assets_page["type"],
			assets_page["tag"], tagv2_text, assets_page["sort_by"], assets_page["order"]]
	assets_page["page_num"] = str(assets_page.get("page", 1)).to_int()
	_update_self_assets(assets_page.get("data", []))
	return assets_page


func _http_unescape_assets_page(assets_page: Dictionary) -> Dictionary:
	assets_page["data"] = assets_page.get("data", []).map(_http_unescape_asset_data)
	return assets_page


## Success method called when an individual asset is loaded.
func _get_asset_completed(request: Dictionary) -> void:
	var asset_data = request["json_result"]
	var asset_id = asset_data["_id"]
	@warning_ignore("return_value_discarded", "static_called_on_instance")
	_http_unescape_asset_data(asset_data)
	_net_assets[asset_id] = asset_data


## Modifies an asset data dict's array of file url strings to be http unescaped.
static func _http_unescape_asset_data(asset_data) -> Dictionary:
	if asset_data.has("currentFile"):
		asset_data["currentFile"] = str(asset_data["currentFile"]).uri_decode()
	return asset_data


## Success method called when a new user asset is created.
func _create_asset_completed(asset_data: Dictionary) -> void:
	var asset_id = asset_data["_id"]
	_net_assets[asset_id] = asset_data


## Success method called when a user asset is updated.
func _update_asset_completed(asset_data: Dictionary) -> void:
	_update_local_asset(asset_data)


func _update_local_asset(asset_data: Dictionary) -> void:
	var asset_id = asset_data["_id"]
	@warning_ignore("return_value_discarded", "static_called_on_instance")
	_http_unescape_asset_data(asset_data)
	_net_assets[asset_id] = asset_data


## Success method called when a user asset is deleted. Only for network assets
func _delete_asset_completed(asset_data: Dictionary) -> void:
	var deleted_asset_id = asset_data["_id"]
	_net_assets.erase(deleted_asset_id)


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


class AssetListRequestParameters:
	var page: int = 1
	var start_by_item: int = -1
	var per_page: int = PER_PAGE
	var search: String = ""
	var field: String = ""
	var type = ""
	var tag_type: String = ""
	var tags = []
	var sort_by: String = ""
	var order: String = ""


	func serialize():
		return { "search": search, "field": field, "type": type, "tag": tags,
			"tag_type": tag_type ,"per_page": per_page,"sort_by": sort_by,
			"order": order, "start_by_item": start_by_item}
