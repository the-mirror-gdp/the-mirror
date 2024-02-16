extends VBoxContainer

@export var _loading_overlay_panel: Node

@onready var _users_table: Table = $UsersTable
@onready var _filter_menu = $FilterMenu
@onready var _user_search_timer = $UserSearchTimer
@onready var _search_loading_spinner = %SearchField/Panel/LoadingSpinner
@onready var _search_field = %SearchField
@onready var _role_user: OptionButton = %role_user
@onready var _public_permissions: OptionButton = $HBoxContainer/PublicPermissions


@onready var _roles = {
	1000: tr("Owner"),
	700: tr("Manager"),
	400: tr("Contributor"),
	100: tr("Observer"),
	0: tr("Blocked")
}

@onready var _permission_text = {
	1000: tr("Full Permissions\n"),
	700: tr("[b]Can:[/b]\n"
		+ " - Enter Space\n"
		+ " - Add Objects\n"
		+ " - Modify Any Object\n"
		+ " - Modify Environment\n"
		+ " - Remove Any Object\n"
		+ "[b]Cannot:[/b]\n"
		+ " - Change Space Ownership\n"
		+ " - Publish"),
	400: tr("[b]Can:[/b]\n"
		+" - Enter Space\n"
		+" - Add Objects\n"
		+" - Modify Owned Objects\n"
		+" - Remove Owned Objects\n" +
		  "[b]Cannot:[/b]\n"
		+" - Remove Others’ Objects\n"
		+" - Modify Environment\n"
		+" - Change Space Ownership\n"
		+" - Publish"),
	100: tr("[b]Can:[/b]\n"
		+" - Enter Space\n" +
		  "[b]Cannot:[/b]\n"
		+" - Add Objects\n"
		+" - Modify Objects\n"
		+" - Remove Objects\n"
		+" - Modify Environment\n"
		+" - Change Space Ownership"),
	0: tr("[b]Cannot:[/b]\n"
		+" - Enter Space\n"
		+" - Add Objects\n"
		+" - Modify Objects\n"
		+" - Remove Objects\n"
		+" - Modify Environment\n"
		+" - Change Space Ownership"),
}

# Should be in sync with [mirror-server/src/option-sets/build-permissions.ts](https://github.com/the-mirror-megaverse/mirror-server/blob/dev/src/option-sets/build-permissions.ts)
var _public_roles: Dictionary = {
	"manager": tr("Manager"),
	"contributor": tr("Contributor"),
	"observer": tr("Observer"),
	"private": tr("Private"),
}

var _space: Dictionary

func _retrive_all_players_data():
	var users_of_space = _space.get("role", {}).get("users", {})
	var promises: Dictionary = {}
	for uid in users_of_space:
		promises[Net.user_client.get_user_profile(uid)] = users_of_space[uid]
	# wait for all to finish, this way all are run concurrent up to max capabilites
	for user_promise in promises:
		var user_data = await user_promise.wait_till_fulfilled()
		if user_promise.is_error():
			Notify.error("Error retriving user data", user_promise.get_error_message())
			continue
		var uid = user_data._id
		var title = user_data.displayName
		var role_level = int(promises[user_promise])
		_users_table.add_row({"id": uid.hash(), "user_id": uid, "user_icon" : "user", "user_name": title, "role_user": role_level, "permissions_text":  _permission_text.get(role_level, "")})


func populate(space: Dictionary) -> void:
	_space = space
	_load_public_permissions()
	_users_table.clear_table()
	var role: int = Util.get_role_for_user(space, Net.user_id)
	_search_field.visible = role >= Enums.ROLE.OWNER
	_loading_overlay_panel.show()
	await _retrive_all_players_data()
	_loading_overlay_panel.hide()


# Called when the node enters the scene tree for the first time.
func _ready():
	# The data mapping
	# This is used to extract the properties and reset the input row
	_users_table.default_data_mapping = {
		"user_icon": {
			"mapping": &"text"
		},
		"user_id": {
			"mapping": &"value",
			"default_value": ""
		},
		"user_name": {
			"mapping": &"text"
		},
		"role_user": {
			"mapping": &"value_id",
			"internal_event" : &"option_selected"
		},
		"permissions_text": {
			"mapping": &"text"
		},
		"remove_user": {
			"internal_event" : &"pressed"
		},
	}
	_users_table.table_event.connect(_table_button_pressed)

	var extra_roles = ProjectSettings.get_setting("mirror/extra_roles", {})
	_roles.merge(extra_roles, true)

	var extra_permission_text = ProjectSettings.get_setting("mirror/extra_permission_text", {})
	for key in extra_permission_text.keys():
		extra_permission_text[key] = tr(extra_permission_text[key])
	_permission_text.merge(extra_permission_text, true)

	_role_user.clear()
	for role in _roles:
		_role_user.add_item(_roles[role], role)


func _load_public_permissions():
	_public_permissions.clear()
	var new_id = 0
	for role in _public_roles:
		_public_permissions.add_item(_public_roles[role], new_id)
		var index = _public_permissions.get_item_index(new_id)
		_public_permissions.set_item_metadata(index, role)
		new_id += 1
		if _space.get("publicBuildPermissions") == role:
			_public_permissions.select(index)


func _on_search_field_text_changed(new_text):
	if new_text.length() < 2:
		return
	_user_search_timer.start()
	_filter_menu.hide()


func _position_search_popup() -> void:
	var pos := Vector2i(_search_field.global_position)
	var root: Window = get_tree().get_root()
	if get_window() != root:
		pos += get_window().position
	var main_viewport_rect_size := Vector2i(root.get_visible_rect().size)
	pos.y += _search_field.size.y
	_filter_menu.position = pos


func _on_user_search_timer_timeout():
	_search_loading_spinner.show()
	var query = _search_field.get_text()
	var promise: Promise = Net.user_client.search_users(query)
	var data = await promise.wait_till_fulfilled()
	_search_loading_spinner.hide()
	_filter_menu.clear()
	if promise.is_error():
		Notify.error("Search error", promise.get_error_message())
		return
	for user in data:
		var uid = user._id
		if _users_table.search_for_text_recursive(uid, "user_id", false):
			continue
		_filter_menu.add_filter_menu_item(user.get("displayName", "unknown"), user)
	_position_search_popup()
	_filter_menu.show()


func _on_filter_menu_item_selected(title, metadata):
	var space_id = _space._id
	var uid = metadata._id
	var role_level = 700
	_filter_menu.hide()
	_search_field.clear_text()
	var promise_update: Promise = Net.space_client.upate_user_role(space_id, uid, role_level)
	_loading_overlay_panel.show()
	await promise_update.wait_till_fulfilled()
	if promise_update.is_error():
		Notify.error("Updating permissions error", promise_update.get_error_message())
	var space_promise: Promise = Net.space_client.get_space(_space._id)
	var space = await space_promise.wait_till_fulfilled()
	_loading_overlay_panel.hide()
	if space_promise.is_error():
		Notify.error("Retrive users list error", space_promise.get_error_message())
		return
	populate(space)


func _table_button_pressed(id: int, column_name: String):
	var space_id = _space._id
	var row_data = _users_table.get_row_data(id)

	_loading_overlay_panel.show()
	if column_name == &"remove_user":
		var promise_update: Promise = Net.space_client.delete_user_role(space_id, row_data.user_id)
		await promise_update.wait_till_fulfilled()
		if promise_update.is_error():
			Notify.error("Removing permissions error", promise_update.get_error_message())
	if column_name == &"role_user":
		var role_level = row_data.role_user
		var promise_update: Promise = Net.space_client.upate_user_role(space_id, row_data.user_id, role_level)
		await promise_update.wait_till_fulfilled()
		if promise_update.is_error():
			Notify.error("Updating permissions error", promise_update.get_error_message())

	var space_promise: Promise = Net.space_client.get_space(_space._id)
	var space = await space_promise.wait_till_fulfilled()
	_loading_overlay_panel.hide()
	if space_promise.is_error():
		Notify.error("Retrive users list error", space_promise.get_error_message())
		return
	populate(space)


func _on_public_permissions_item_selected(index):
	var updated_space_data = {
		"publicBuildPermissions": _public_permissions.get_item_metadata(index)
	}
	var promise = Net.space_client.update_space(_space.get("_id"), updated_space_data)
	var space_data = await promise.wait_till_fulfilled()
	if promise.is_error():
		Notify.error(tr("Public Permissions Failure"), promise.get_error_message())
		_load_public_permissions()
		return
	Notify.success(tr("Public Permissions"), tr("Permisssions updated successfully."))
	_space = space_data
