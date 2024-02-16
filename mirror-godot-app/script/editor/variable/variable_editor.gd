extends Panel


var _script_editor_holder: DraggableContainer
var _valid_globals = false
var _valid_nodes = false

@onready var _search = $VariableTable/TopBar/Search
@onready var _tables: Dictionary = {
	"globals": %GlobalVariables,
	"space_objects": %SpaceObjects
}
@onready var _instructions = $VBoxContainer/Instructions
# Dialogs
@onready var _variable_creation_dialog = $VariableCreationDialog
@onready var _variable_type_editor_dialog = $VariableTypeEditorDialog
@onready var _variable_value_editor_dialog = $VariableValueEditorDialog
var queued_update_timer: Timer


static func _remove_global_variable_keyed(key: String):
	Zone.script_network_sync.delete_global_variable(key)


static func _remove_node_variable_keyed(node: Node, key: String):
	Zone.script_network_sync.delete_variable_on_node_at_path(node.get_path(), key)


func create_new_variable(node_path: NodePath = ""):
	var role = Util.get_role_for_user(Zone.space, Net.user_id)
	if role >= Enums.ROLE.MANAGER:
		_variable_creation_dialog.open_creation_dialog(node_path)
	else:
		Notify.error("Space Variables Error", "You don't have permissions to add new variables.")


func search_for_text(value: String) -> void:
	# search every table for the data
	for table in _tables.values():
		table.search_for_text_recursive(value, "data")


func drag_data_override(row_id: int, source: Control, position: Vector2) -> Variant:
#	print("Row ID: ", row_id)
#	print("position: ", position)
#	print("Control: ", source)
	var table = source.get_meta("table")
	var preview = source.duplicate()
	# force the same width
	preview.custom_minimum_size = source.size
	source.set_drag_preview(preview)
	var variable_key = table.get_column_data(row_id, "data_key")
	var variable_value = table.get_column_data(row_id, "data_value")
#	print("variable key: ", variable_key, " data: ", variable_value)
	# NOTE: do not check variable_value == null otherwise the drag drop will break
	# sometimes null might be a value
	if variable_key == null:
		return {}
	if table == _tables.globals:
		return {
			"string_to_drop": variable_key,
			"value_to_set": variable_value,
			"drag_type": "dragged_global_variable"
		}

	# space_objects
	assert(table == _tables.space_objects)
	var space_object = table.get_column_data(row_id, "data_node")
	assert(space_object)
	var ret = {
		"drag_type": "dragged_node_variable",
		"string_to_drop": variable_key,
		"value_to_set": variable_value,
		"connect_to_space_object": space_object.get_name(),
	}
	return ret


func _ready() -> void:
	# do not allow this on server
	if Zone.is_host():
		return
	var mapping: Dictionary = {
		"data": {
			"mapping": "text",
			"default_value": "", # used for resetting the column to the default state
			"drag_data_override": drag_data_override
		},
		"data_type": {
			"mapping": "icon",
			"default_value": preload("res://script/editor/variable/icons/object.svg"),
			"internal_event" : "pressed"
		},
		"data_key": {
			"mapping": "text",
			"default_value": ""
		},
		"data_value": {
			"mapping": "value",
			"default_value": ""
		},
		"data_node": {
			"mapping": "value",
			"default_value": null
		},
		"edit_button": {
			# calls the table changed event with one nuance the signal has less arguments, requires two signals to be bound.
			"internal_event" : "pressed"
		},
		"remove_button": {
			# calls the table changed event with one nuance the signal has less arguments, requires two signals to be bound.
			"internal_event" : "pressed"
		}
	}
	for table in _tables.values():
		table.default_data_mapping = mapping
		table.table_event.connect(_table_button_pressed.bind(table))
	Zone.script_network_sync.global_variable_changed.connect(func(_var_name, _value): queue_update())
	Zone.script_network_sync.object_variable_changed.connect(func(_object, _var_name, _value): queue_update())
	Zone.client.disconnected.connect(_on_zone_disconnected)
	queued_update_timer = Timer.new()
	add_child(queued_update_timer)
	queued_update_timer.timeout.connect(update_vars)


func _on_zone_disconnected():
	for table in _tables:
		_tables[table].clear_table()


func queue_update():
	if queued_update_timer.is_stopped():
		queued_update_timer.start(1.0)


# Pressed has two arguments and signal bind is sensitive to argument count
# we take advantage of this and use this for button events
# for input fields in tables we use _table_data_changed, but notice
# they both use the same signal with different arg counts
func _table_button_pressed(id: int, column_name: String, table: Table):
	if table == _tables.globals:
		if column_name == "remove_button":
			var row_data = table.get_row_data(id)
			_remove_global_variable_keyed(row_data.data_key)
			table.remove_row(id)
		if column_name == "edit_button":
			var row_data = table.get_row_data(id)
			# note: data is just the displayed string
			# data_value is the actual "data" from the global
			# likewise for key.
			_variable_value_editor_dialog.edit_variable_value(row_data.data_key, row_data.data_value)
		if column_name == "data_type":
			var row_data = table.get_row_data(id)
			# note: data is just the displayed string
			# data_value is the actual "data" from the global
			# likewise for key.
			_variable_type_editor_dialog.edit_variable_type(row_data.data_key, row_data.data_value)
	elif table == _tables.space_objects:
		if column_name == "remove_button":
			var row_data = table.get_row_data(id)
			_remove_node_variable_keyed(row_data.data_node, row_data.data_key)
			table.remove_row(id)
		if column_name == "edit_button":
			var row_data = table.get_row_data(id)
			# note: data is just the displayed string
			# data_value is the actual "data" from the global
			# likewise for key.
			_variable_value_editor_dialog.edit_variable_value(row_data.data_key, row_data.data_value, row_data.data_node.get_path())
		if column_name == "data_type":
			var row_data = table.get_row_data(id)
			# note: data is just the displayed string
			# data_value is the actual "data" from the global
			# likewise for key.
			_variable_type_editor_dialog.edit_variable_type(row_data.data_key, row_data.data_value, row_data.data_node.get_path())


func toggle_variable_editor() -> void:
	if visible:
		hide()
	else:
		show()
		GameUI.grab_input_lock(self)
		_search.grab_focus()
		_search.select_all()


func close_variable_editor() -> void:
	hide()


func _get_icon_from_variable_type(variable_type: int) -> Texture2D:
	match variable_type:
		TYPE_BOOL:
			return preload("icons/bool.svg")
		TYPE_INT:
			return preload("icons/int.svg")
		TYPE_FLOAT:
			return preload("icons/float.svg")
		TYPE_STRING:
			return preload("icons/string.svg")
		TYPE_VECTOR2:
			return preload("icons/vector2.svg")
		TYPE_VECTOR3:
			return preload("icons/vector3.svg")
		TYPE_COLOR:
			return preload("icons/color.svg")
		TYPE_OBJECT:
			return preload("icons/object.svg")
		TYPE_DICTIONARY:
			return preload("icons/dictionary.svg")
		TYPE_ARRAY:
			return preload("icons/array.svg")
	return preload("icons/any_variant.svg")

var cache_node_vars_hash: int = -1
var cache_global_vars_hash: int = -1


func update_vars():
	if not Zone.client.is_client_connected_to_server():
		visible = false
		return
	var global_vars_hash: int = Zone.script_network_sync._global_variables.hash()
	var node_vars_hash: int = Zone.script_network_sync.get_all_node_paths_with_variables().hash()
	if global_vars_hash == cache_global_vars_hash and node_vars_hash == cache_node_vars_hash:
		return
	cache_global_vars_hash = global_vars_hash
	cache_node_vars_hash = node_vars_hash
	# refresh data
	_setup_global_variables()
	_setup_node_variables()


func clean_node_name(name: StringName) -> StringName:
	return name.replace(".glb", "").replace(".gltf", "").replace(".obj", "")


func _setup_node_variables():
	var valid_ids: Array[int] = []
	var all_node_paths_with_variables: Array = Zone.script_network_sync.get_all_node_paths_with_variables()
	all_node_paths_with_variables.sort()
	for node_path_untyped in all_node_paths_with_variables:
		var node_path: NodePath = node_path_untyped
		var node_path_count: int = node_path.get_name_count()
		var node: Node = get_node(node_path)
		if not is_instance_valid(node):
			continue
		var node_name: StringName = clean_node_name(node.space_object_name) if node is SpaceObject else node.get_name()
		# Now that we know which TreeItem is our parent, set up variables.
		var variables = Zone.script_network_sync.get_variables_on_node_at_path(node_path)
		# data should be in this format
		# {
		# "variable_name" : value
		# }
		var data_formatted = {}
		for variable_name in variables:
			var data = variables[variable_name]
			data_formatted[variable_name] = data
			var json = JSON.stringify(data_formatted, "\t", true, true)
			var key = String(node_path)
			# TODO: regex remove the bb code from the global variable
			var data_to_render: String = "\"[b]" + node_name + "[/b]\" : " + str(json)
			var hash_id: int = key.hash()
			var icon: Texture2D = _get_icon_from_variable_type(typeof(data))
			if not icon:
				push_error("invalid data type icon")
				continue
			_tables.space_objects.update_or_add_row({
				"id": hash_id,
				"data": data_to_render,
				"data_key": variable_name,
				"data_value": data,
				"data_type": icon,
				"data_node": node
			})
			valid_ids.push_back(hash_id)
	for row_id in _tables.space_objects.get_rows().duplicate():
		if valid_ids.has(row_id):
			continue
		_tables.space_objects.remove_row(row_id)


func _setup_global_variables():
	var valid_ids: Array[int] = []
	var global_variables: Dictionary = Zone.script_network_sync._global_variables
	for key in global_variables.keys():
		var global_variable = global_variables[key]
		# TODO: regex remove the bb code from the global variable
		var data_to_render: String = "\"[b]" + key + "[/b]\" : " + JSON.stringify(global_variable, "\t", true, true)
		if key == "SpaceObjects":
			continue # hide it for now
		var hash_id: int = key.hash()
		var icon: Texture2D = _get_icon_from_variable_type(typeof(global_variable))
		if not icon:
			push_error("invalid data type icon")
			continue
		_tables.globals.update_or_add_row({
			"id": hash_id,
			"data": data_to_render,
			"data_key": key,
			"data_value": global_variable,
			"data_type": icon
		})
		valid_ids.push_back(hash_id)
	for row_id in _tables.globals.get_rows().duplicate():
		if valid_ids.has(row_id):
			continue
		_tables.globals.remove_row(row_id)
