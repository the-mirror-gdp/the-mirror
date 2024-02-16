class_name GroupClient
extends MirrorClient

enum {
	GET_USER_GROUPS,
	CREATE_GROUP,
	DELETE_GROUP,
}

signal group_created(group_data)
signal group_deleted(group_data)
signal user_groups_received(groups)

var groups: Dictionary = Dictionary()
var user_groups: Array = Array()


## Gets the groups that belong to the current user.
func get_current_user_groups() -> void:
	self.get_request(GET_USER_GROUPS, "/user-group")


## Creates a new group that will belong to the current user.
func create_group(group_data: Dictionary) -> void:
	self.post_request(CREATE_GROUP, "/user-group", group_data)


## Deletes a group.
func delete_group(group_id: String) -> void:
	self.delete_request(DELETE_GROUP, "/user-group/%s" % group_id)


## Signal routes a successful request to the appropriate complete method.
func _handle_request_completed(request: Dictionary) -> void:
	var json_result = request["json_result"]
	match request["key"]:
		CREATE_GROUP:
			_create_group_completed(json_result)
		GET_USER_GROUPS:
			_get_user_groups_completed(json_result)
		DELETE_GROUP:
			_delete_group_completed(json_result)


func _get_user_groups_completed(user_groups_arr: Array) -> void:
	print("Loaded %s user groups." % str(user_groups_arr.size()))
	user_groups = user_groups_arr
	for group in user_groups:
		var group_id = group["_id"]
		self.groups[group_id] = group
	print("Total groups: %s" % str(self.groups.keys().size()))
	user_groups_received.emit(user_groups)


func _create_group_completed(group_data: Dictionary) -> void:
	var group_id = group_data["_id"]
	groups[group_id] = group_data
	user_groups.append(group_data)
	group_created.emit(group_data)


func _delete_group_completed(group_data: Dictionary) -> void:
	var group_id = group_data["_id"]
	for i in range(user_groups.size()):
		var user_group = user_groups[i]
		if user_group["_id"] == group_id:
			user_groups.erase(user_group)
			break
	if groups.has(group_id):
		groups.erase(group_id)
	group_deleted.emit(group_data)
