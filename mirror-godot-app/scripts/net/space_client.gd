class_name SpaceClient
extends MirrorHttpClient

const PER_PAGE = 36

var spaces: Dictionary = Dictionary()
var user_spaces: Array = Array()
var discover_spaces: Array = Array()
var published_spaces: Array = Array()
var space_objects: Dictionary = Dictionary()

enum {
	GET_SPACE,
	CREATE_SPACE,
	DUPLICATE_SPACE,
	UPDATE_SPACE,
	DELETE_SPACE,
	UPDATE_IMAGE_SPACE,
	GET_USER_SPACES,
	GET_DISCOVER_SPACES,
	GET_PUBLISHED_SPACES,
	GET_SPACE_OBJECT,
	CREATE_SPACE_OBJECT,
	UPDATE_SPACE_OBJECT,
	DELETE_SPACE_OBJECT,
	GET_SPACE_OBJECTS,
	CLEAR_VOXELS,
	PUBLISH_SPACE,
	GET_PUBLISHED_SPACE_VERSIONS,
	GET_LATEST_PUBLISHED_SPACE_VERSION,
	GET_SPACE_TEMPLATES,
	COPY_FROM_TEMPLATE,
	UPDATE_USER_ROLE,
	DELETE_USER_ROLE,
	GET_POPULAR,
	GET_FAVORITES,
	GET_RECENTS,
	UPDATE_SPACE_TAGS,
	CREATE_SPACE_VERSION,
	KICK_ME_FROM_SPACE,
}


## Kicks out currently logged user from given space
func kick_me_from_spaces(space_id: String) -> Promise:
	# a POST request that has an empty body responds with 411 body must not be empty.
	var not_empty_request_body = {"requestBody": 0}
	return self.post_request(KICK_ME_FROM_SPACE, "/space/%s/kickme" % space_id, not_empty_request_body)


## Gets the most popular spaces.
func get_popular_spaces() -> Promise:
	var extras: String = "populateCreator=true"
	return self.get_request(GET_POPULAR, "/space/popular?%s" % extras)


## Gets the most popular spaces.
func get_favorites_spaces() -> Promise:
	var extras: String = "populateCreator=true"
	return self.get_request(GET_FAVORITES, "/space/favorites?%s" % extras)


## Gets the most popular spaces.
func get_recent_spaces() -> Promise:
	var extras: String = "populateCreator=true"
	return self.get_request(GET_RECENTS, "/space/recents?%s" % extras)


## Sets the role for a given user
func upate_user_role(space_id: String, targe_user: String, role: int) -> Promise:
	var role_data = {
		"targetUserId": targe_user,
		"role": role
	}
	return self.patch_request(UPDATE_USER_ROLE, "/space/%s/role/set" % space_id, role_data)


## Deletes the role for a given user
func delete_user_role(space_id: String, targe_user: String) -> Promise:
	var role_data = {
		"targetUserId": targe_user,
	}
	return self.patch_request(DELETE_USER_ROLE, "/space/%s/role/unset" % space_id, role_data)


static func _get_paginated_search_params(params: SpaceListRequestParameters) -> String:
	params.page = maxi(params.page, 1)
	var st_fmt: String = "page=%d" % params.page if params.start_by_item < 0 else "startItem=%d" % params.start_by_item
	var per_pg_fmt: String = "&perPage=%d" % params.per_page if params.start_by_item < 0 else "&numberOfItems=%d" % params.per_page
	var field_fmt: String = params.field if params.field.is_empty() else "&field=%s" % params.field.uri_encode()
	var search_fmt: String = params.search if params.search.is_empty() else "&search=%s" % params.search.uri_encode()
	var type_fmt: String = params.type if params.type.is_empty() else "&assetTypes=%s" % params.type.uri_encode()
	var tags_preprocess = params.tags.map(func(x): return "&tag=%s" % x)
	var tag_fmt: String = "" if params.tags.size() == 0 else "&tagType=search" + "".join(tags_preprocess)
	var sort_by_fmt: String = params.sort_by if params.sort_by.is_empty() else "&sortKey=%s" % params.sort_by.uri_encode()
	var order_fmt: String = params.order if params.order.is_empty() else "&sortDirection=%s" % params.order.uri_encode()
	return "%s%s%s%s%s%s%s%s" % [st_fmt, per_pg_fmt, search_fmt, field_fmt, type_fmt, tag_fmt, sort_by_fmt, order_fmt]


## Gets the spaces that belong to the current user.
func get_current_user_spaces(params: SpaceListRequestParameters) -> Promise:
	var query = _get_paginated_search_params(params)
	return self.get_request(GET_USER_SPACES, "/space/me-v2?%s" % query)


## Gets the spaces that do not belong to the current user but are editable for them.
func get_discover_spaces(params: SpaceListRequestParameters) -> Promise:
	var query = _get_paginated_search_params(params)
	return self.get_request(GET_DISCOVER_SPACES, "/space/discover-v2?%s" % query)


## Gets only the spaces that are already published by creators
func get_published_spaces(params: SpaceListRequestParameters) -> Promise:
	var query = _get_paginated_search_params(params)
	return self.get_request(GET_PUBLISHED_SPACES, "/space/get-published-spaces-v2?%s&populateCreator=true" % query)


## Creates a space that will belong to the current user.
func create_space(space_data: Dictionary) -> Promise:
	return self.post_request(CREATE_SPACE, "/space", space_data)


func copy_from_template(template_id: String, space_data: Dictionary) -> Promise:
	return self.post_request(COPY_FROM_TEMPLATE, "/space/copy-from-template/%s" % template_id, space_data )


## Duplicates a space for the current user.
func duplicate_space(space_id: String) -> Promise:
	# a POST request that has an empty body responds with 411 body must not be empty.
	var not_empty_request_body = {"requestBody": 0}
	return self.post_request(DUPLICATE_SPACE, "/space/copy/%s" % space_id, not_empty_request_body)


## Gets a space with the provided space id.
func get_space(space_id: String) -> Promise:
	return self.get_request(GET_SPACE, "/space/%s" % space_id)


## Gets a published space version with the provided space id.
func get_published_space_versions(space_id: String) -> Promise:
	return self.get_request(GET_PUBLISHED_SPACE_VERSIONS, "/space/version/%s" % space_id)


## Creates a space version and publishes it for the provided space id.
func publish_space(space_id: String) -> Promise:
	Analytics.track_event_client(AnalyticsEvent.TYPE.SPACE_PUBLISHED, {"space_id" : space_id})
	var body = {
		"updateSpaceWithActiveSpaceVersion" : true
	}
	return self.post_request(PUBLISH_SPACE, "/space/version/%s" % space_id, body, {"id": space_id})


## Creates a space version with the provided space id and name.
func create_space_version(space_id: String, name: String) -> Promise:
	var body = {
		"name" : name
	}
	return self.post_request(CREATE_SPACE_VERSION, "/space/version/%s" % space_id, body, {"id": space_id})



func get_latest_published_space(space_id: String) -> Promise:
	var url: String = "/space/latest-published/%s" % space_id
	return self.get_request(GET_LATEST_PUBLISHED_SPACE_VERSION, url)


## Gets a space with the provided space id.
func get_space_templates() -> Promise:
	return self.get_request(GET_SPACE_TEMPLATES, "/space/templates")


## Updates a space given the space id and data dictionary.
func update_space(space_id: String, space_data: Dictionary) -> Promise:
	return self.patch_request(UPDATE_SPACE, "/space/%s" % space_id, space_data)


## Deletes a space given the space id.
func delete_space(space_id: String) -> Promise:
	return self.delete_request(DELETE_SPACE, "/space/%s" % space_id)


## Uploads an image that will belong to the space.
func update_image_space(space_id: String, image_index: int,  webp_bytes: PackedByteArray) -> Promise:
	var mime = "image/webp"
	var url: String = "/space/%s/upload/public" % space_id
	@warning_ignore("static_called_on_instance")
	var request_body: PackedByteArray = self.get_form_data(webp_bytes, mime, str(image_index))
	return self.post_request(UPDATE_IMAGE_SPACE, url, request_body, {'image_index': image_index})


## Gets a space with the provided space id.
func clear_voxels(space_id: String) -> Promise:
	return self.delete_request(CLEAR_VOXELS, "/space/voxels/%s" % space_id, {"id": space_id})


## Creates a space object that will belong to the space.
func create_space_object(space_id: String, asset_id: String) -> Promise:
	var body = {
		"asset": asset_id,
		"spaceId": space_id,
		"name": "New Object",
		"position": [0.0, 0.0, 0.0],
		"rotation": [0.0, 0.0, 0.0],
		"scale": [1.0, 1.0, 1.0],
		"offset": [0.0, 0.0, 0.0],
	}
	return self.post_request(CREATE_SPACE_OBJECT, "/space-object/space", body)


## Updates a space object
func update_space_object(space_object: Dictionary) -> Promise:
	var space_object_id = space_object["_id"]
	var url = "/space-object/%s" % space_object_id
	return self.patch_request(UPDATE_SPACE_OBJECT, url, space_object)


## Gets a space object
func get_space_object(object_id: String) -> Promise:
	return self.get_request(GET_SPACE_OBJECT, "/space-object/%s" % object_id)


## Deletes a space object given the id.
func delete_space_object(space_object_id: String) -> Promise:
	return self.delete_request(DELETE_SPACE_OBJECT, "/space-object/%s" % space_object_id)


## Gets space objects belonging to a space
func get_space_objects(space_id: String) -> Promise:
	return self.get_request(GET_SPACE_OBJECTS, "/space-object/space/%s" % space_id)


func update_space_tags(space_id: String, space_tags_data: Dictionary) -> Promise:
	space_tags_data["spaceId"] = space_id
	return self.patch_request(UPDATE_SPACE_TAGS, "/space/tag" , space_tags_data)


func _promise_fulfill_successful(request: Dictionary, promise: Promise) -> void:
	var result = request.get("json_result")
	if request.get("key") in [CLEAR_VOXELS]:
		result = request.get("id")
	if result == null:
		push_error("SpaceClient request succeeded but parsed result is null. %s" % str(request))
		promise.set_error("SpaceClient request succeeded but parsed result is null. %s" % str(request))
		return
	match request.get("key"):
		GET_SPACE:
			_get_space_completed(result)
		CREATE_SPACE:
			_create_space_completed(result)
		UPDATE_SPACE:
			_update_space_completed(result)
		GET_USER_SPACES:
			_get_user_spaces_completed(result.get("data", []))
		GET_DISCOVER_SPACES:
			_get_discover_spaces_completed(result.get("data", []))
		GET_PUBLISHED_SPACES:
			_get_published_spaces_completed(result.get("data", []))
		DELETE_SPACE:
			_delete_space_completed(result)
		UPDATE_IMAGE_SPACE:
			result["image_index"] = request.get("image_index", -1)
			_update_image_space_completed(result)
		CREATE_SPACE_OBJECT:
			_create_space_object_completed(result)
		GET_SPACE_OBJECT:
			_get_space_object_completed(result)
		UPDATE_SPACE_OBJECT:
			_update_space_object_completed(result)
		DELETE_SPACE_OBJECT:
			_delete_space_object_completed(result)
		GET_SPACE_OBJECTS:
			_get_space_objects_completed(result)
		COPY_FROM_TEMPLATE:
			_create_space_completed(result)
		#DUPLICATE_SPACE:
		#CLEAR_VOXELS:
		#PUBLISH_SPACE:
		#GET_PUBLISHED_SPACE_VERSIONS:
		#GET_LATEST_PUBLISHED_SPACE_VERSION:
		#GET_POPULAR:
		#GET_FAVORITES:
		#GET_RECENTS:
		#	pass
	promise.set_result(result)


## Success method called when an individual space is loaded.
func _get_space_completed(space_data: Dictionary) -> void:
	var space_id = space_data["_id"]
	spaces[space_id] = space_data


## Success method called when a new space is created.
func _create_space_completed(space_data: Dictionary) -> void:
	var space_id = space_data["_id"]
	spaces[space_id] = space_data
	user_spaces.append(space_data)


## Success method called when a space is updated.
func _update_space_completed(space_data: Dictionary) -> void:
	var space_id = space_data["_id"]
	spaces[space_id] = space_data
	for i in range(user_spaces.size()):
		var user_space = user_spaces[i]
		if user_space["_id"] == space_id:
			user_space[i] = space_data


## Success method called when a space is deleted.
func _delete_space_completed(space_data: Dictionary) -> void:
	var deleted_space_id = space_data["_id"]
	for i in range(user_spaces.size()):
		var user_space = user_spaces[i]
		if user_space["_id"] == deleted_space_id:
			user_spaces.erase(user_space)
			break
	spaces.erase(deleted_space_id)


## Success method called when user spaces are loaded.
func _get_user_spaces_completed(user_spaces_arr: Array) -> void:
	print("Loaded %s user spaces." % str(user_spaces_arr.size()))
	user_spaces = user_spaces_arr
	for space in user_spaces:
		var space_id = space["_id"]
		self.spaces[space_id] = space
	print("Total spaces: %s" % str(self.spaces.keys().size()))


func _get_discover_spaces_completed(discover_spaces_arr: Array) -> void:
	print("Loaded %s discover spaces." % str(discover_spaces_arr.size()))
	discover_spaces = discover_spaces_arr
	for space in discover_spaces:
		var space_id = space["_id"]
		self.spaces[space_id] = space
	print("Total discover spaces: %s" % str(self.spaces.keys().size()))


func _get_published_spaces_completed(published_spaces_arr: Array) -> void:
	print("Loaded %s published spaces." % str(published_spaces_arr.size()))
	published_spaces = published_spaces_arr
	for space in published_spaces_arr:
		var space_id = space["_id"]
		self.spaces[space_id] = space
	print("Total published spaces: %s" % str(self.spaces.keys().size()))


## Success method called when an updated image is uploaded.
func _update_image_space_completed(space_data: Dictionary) -> void:
	var space_id = space_data["_id"]
	spaces[space_id] = space_data
	for i in range(user_spaces.size()):
		var user_space = user_spaces[i]
		if user_space["_id"] == space_id:
			user_space[i] = space_data
	print("Updated image for space: %s index: %d" %
			[space_data.get("_id",""), space_data.get("image_index", -1)])


## Success method called when a new space object is created.
func _create_space_object_completed(space_object_data: Dictionary) -> void:
	_set_space_object(space_object_data)


## Success method called when a space object is updated.
func _update_space_object_completed(space_object_data: Dictionary) -> void:
	_set_space_object(space_object_data)


## Success method called when a space object is deleted.
func _delete_space_object_completed(space_object_data: Dictionary) -> void:
	var space_id = space_object_data["space"]
	var object_id = space_object_data["_id"]
	if space_object_data.is_empty() and space_objects[space_id].has(object_id):
		space_objects[space_id].erase(space_id)


## Success method called when a space object is received.
func _get_space_object_completed(space_object_data: Dictionary) -> void:
	_set_space_object(space_object_data)


## Success method called when an array of space objects is received.
func _get_space_objects_completed(space_objects_arr: Array) -> void:
	for obj in space_objects_arr:
		_set_space_object(obj)


## Sets a space object value into an organized dictionary.
func _set_space_object(space_object_data: Dictionary) -> void:
	var space_id = space_object_data["space"]
	var object_id = space_object_data["_id"]
	if not space_objects.has(space_id):
		space_objects[space_id] = Dictionary()
	space_objects[space_id][object_id] = space_object_data


class SpaceListRequestParameters:
	var page: int = 1
	var start_by_item: int = -1
	var per_page: int = PER_PAGE
	var search: String = ""
	var field: String = ""
	var type: String = ""
	var tags: Array[String] = []
	var sort_by: String = ""
	var order: String = ""

	func serialize():
		return { "search": search, "field": field, "type": type, "tag": tags,
			"per_page": per_page,"sort_by": sort_by,
			"order": order, "start_by_item": start_by_item}
