extends HBoxContainer
class_name Table

## How to use this
# This exports all the custom columns you must override or null depending on your use case.
# This supports immutable and mutable table types.
# 1. provide your own add_data_row - this is a simple list of the column's
# 2. (optionally) provide the add_data_row, if you don't provide it, you must set it to null
# 3. if you didn't provide the add data row it will make the table readonly, like for score or
# friends where it might need custom UI.
# 4. Allow user to enter the data manually or inject it using our method add_row_with_data
# TODO: implement add_row_with_data (will do this when I work on the friends UI)
signal table_event(id, column_name)
signal table_data_changed(id, column_name, value)
signal table_added_row(id)
signal table_removed_row(id)

# The data mapping
# This is used to extract the properties and reset the input row
# An example is provided with the correct columns for teams
@onready var default_data_mapping: Dictionary = {}

# Dictionary of table data
# A Dictionary of Arrays containting controls.
# 0 is row 0, which could contain 3 controls
# 1 is row 1, which also contains 3 controls
# please, do not assume that the dictionary id in this table will exist
# This solution increments the ID to prevent mismatching ID's.

# TODO: make utility for shorthanding has_node and returning the row...?

# Why are these @onready's so complex?
# Some of the older tables rely on the old paths. Updating them in a short period was non trivial.
# Everything below has a LEGACY and a NEW layout method.
# Old tables will need to be updated once to the new streamlined format but I don't have time to do this.
# So the old tables use the old paths and the new tables use the very simple shortened paths.
# A template is provided so that there is no confusion about this under ui/components.
@onready var table_data: Dictionary = {}
# This should never be null, but should support redirecting to the legacy mapping.
# In our next release the longer paths will be removed.
@onready var table = $table if has_node("table") else $MarginContainer/Scrollbar/VBoxContainer/table
# The table headers
# This should never be null.
@onready var add_table_header = $table_header if has_node("table_header") else $MarginContainer/Scrollbar/VBoxContainer/table_header
# Add data row is optional maybe the data is not changable by the user
# Since it's optional it can safely return null. Yes I know the line is super long
@onready var add_data_row = $add_data_row if has_node("add_data_row") else $MarginContainer/Scrollbar/VBoxContainer/add_data_row if has_node("MarginContainer/Scrollbar/VBoxContainer/add_data_row") else null
@onready var insertion_row_id = -1 # row id for the insertion data row
# The actual row the user views
@onready var new_row = $new_row if has_node("new_row") else $MarginContainer/Scrollbar/VBoxContainer/new_row
# Do not deincrement this - it is used for stable ID's on the row's.
@onready var _unique_row_id: int = 0

func _ready():
	assert(table)
	assert(new_row)
	_internal_clear_table()
	_setup_table_header()


# Get row directly from the table data
func _internal_get_row(row_id: int): # type must not be included for null's
	return table_data.get(row_id, Array())


# returns all table row's with valid elements
func get_rows() -> Array:
	var row_ids : Array
	for row in table_data.values():
		# we only need to check the first element
		# a row is simply a list of controls
		var control = row.front() if row.size() > 0 else null
		if not control:
			continue
		var external_id = control.get_meta("external_id") if control.has_meta("external_id") else null
		if external_id == null:
			continue
		if external_id == -1:
			assert(false)
		if not row_ids.has(external_id):
			row_ids.push_back(external_id)
	return row_ids


# Exernal ID's are supplied as "id" these are not the same internal row id we use
# We could have an extra dummy row in the table with no external ID for example.
func get_row(row_id: int) -> Array:
	for row in table_data.values():
		# we only need to check the first element
		# a row is simply a list of controls
		var control = row.front() if row.size() > 0 else null
		if control and control.has_meta("external_id") and control.get_meta("external_id", null) == row_id:
			return row
	return Array()


# Get the column by row id and column name
func get_column(row_id: int, column_name: String) -> Variant:
	var row = get_row(row_id)
	for column in row:
		if column.get_meta("column_name") == column_name:
			return column
	return null


# Exernal ID's are supplied as "id" these are not the same internal row id we use
# We could have an extra dummy row in the table with no external ID for example.
func find_row_internal_id(external_row_id: int) -> int:
	for row in table_data.values():
		# we only need to check the first element
		# a row is simply a list of controls
		var control = row.front() if row.size() > 0 else null
		if is_instance_valid(control) and control.has_meta("external_id") and control.get_meta("external_id") == external_row_id: # ensure the external id matches
			return control.get_meta("internal_id") # return the correct row id
	return -1


func remove_row(id: int, use_signal: bool = true) -> bool:
	var internal_id = find_row_internal_id(id)
	if internal_id != -1:
		_internal_remove_row(internal_id, use_signal)
		return true
	return false


func apply_row_data(id: int, data: Dictionary):
	var internal_id = find_row_internal_id(id)
	_internal_apply_row_data(internal_id, data)


func add_row(data: Dictionary) -> void:
	var internal_row_id = _internal_add_row(table, new_row, data.id)
	#print("adding row: ", Zone.get_instance_type())
	# map the row data to the godot data
	_internal_apply_row_data(internal_row_id, data)


func update_or_add_row(data: Dictionary) -> void:
	var internal_row_id = find_row_internal_id(data.get("id"))
	if internal_row_id == -1:
		internal_row_id = _internal_add_row(table, new_row, data.id)
	# map the row data to the godot data
	_internal_apply_row_data(internal_row_id, data)


# We could use internal ID's here but not much reason to.
func search_for_text_recursive(search_text: String, column_name: String, hide_not_matching: bool = true) -> bool:
	var any_visible_data: bool = false
	for row_id in get_rows():
		# return the row dictionary and the row controls (column's)
		var row_data = get_row_data(row_id)
		var row_column = get_row(row_id)
		# search for the data, if the string is empty just set everything to visible
		var data_visible: bool = row_data.get(column_name, "").findn(search_text) > -1 or search_text.is_empty()
		for column in row_column:
			# only make the column visible when the column is not a hidden editor node
			# a hidden editor node could be a hidden scrollbar on a rich text label
			if hide_not_matching:
				column.visible = data_visible and column.get_meta("default_visibility_state")
			any_visible_data = any_visible_data or data_visible
	return any_visible_data


# This writes a row to a table from the template provided by the function call
# The intent is to duplicate from a known good portion of data
# This can be used for example for friends as well as teams.
func _internal_add_row(table: GridContainer, new_row: Control, external_row_id: int = -1) -> int:
	var row_elements : Array = []
	# Copies the row into the table, preserves children,
	# and applies metadata to the children so they are aware of their row info
	for item in new_row.get_children():
		var column_item = item.duplicate(DUPLICATE_SIGNALS|DUPLICATE_SCRIPTS)
		table.add_child(column_item)
		for child in column_item.find_children("*", "Control", true, false):
			child.set_meta("column_name", child.name)
			child.set_meta("internal_id", _unique_row_id)
			child.set_meta("default_visibility_state", child.visible)
			# see comment below at other usage of "table" for more info
			child.set_meta("table", self)
			if external_row_id != -1:
				child.set_meta("external_id", external_row_id)
			row_elements.push_back(child)
		column_item.set_meta("default_visibility_state", item.visible)
		column_item.set_meta("column_name", item.name)
		column_item.set_meta("internal_id", _unique_row_id)
		# reference to the table
		# important for dragging & input events with multiple tables
		column_item.set_meta("table", self)
		if external_row_id != -1:
			column_item.set_meta("external_id", external_row_id)
		row_elements.push_back(column_item)
	table_data[_unique_row_id] = row_elements
	_unique_row_id += 1
	return _unique_row_id - 1


# This writes the table header row to the table and might add a "add data row"
# In the case you want your table to be written to by the user you must
# provide an add data row, or alternaitvely call the _generic_add_to_table func.
func _setup_table_header():
	_internal_add_row(table, add_table_header)
	# it is optional
	if add_data_row:
		insertion_row_id = _internal_add_row(table, add_data_row)


# Clear the external table data
# not the important control rows though!
func clear_table():
	var erase_row_ids = []
	for row_id in table_data.keys():
		var row = table_data[row_id]
		for column in row:
			if not column.has_meta("external_id"):
				continue
			if column.get_meta("external_id") == -1:
				continue
			if not erase_row_ids.has(row_id):
				erase_row_ids.push_back(row_id)
			column.get_parent().remove_child(column)
			column.queue_free()
	for id in erase_row_ids:
		table_data.erase(id)


# Clear the internal table elements
# Note: won't actually 'delete' internal references
func _internal_clear_table():
	for item in table.get_children():
		table.remove_child(item)
		item.queue_free()


# Remove the row by the stable row ID
# Note the row ID is a unique id not a ID that will deincrement
# This allows the UI to handle the elements efficiently and remove them without
# Re-ordering an array, and it also is the easiest in terms of the Godot UI.
# We use set_meta internally to provide this ID. You could add your own ID.
# Perhaps for mapping back to the DTO in the backend.
func _internal_remove_row(row_id: int, use_signal: bool = true):
	var external_id: int = -1
	var erase_objects: Array = []
	if not table_data.has(row_id):
		return
	var row_reference: Array = table_data.get(row_id, Array())
	for column in row_reference:
		if is_instance_valid(column):
			if external_id == -1:
				external_id = column.get_meta("external_id")
			column.get_parent().remove_child(column)
			column.queue_free()
	table_data.erase(row_id)
	if use_signal:
		table_removed_row.emit(external_id)


func set_row_external_id(row_id: int, external_id: int):
	var values = {}
	var columns = _internal_get_row(row_id)
	for column in columns:
		column.set_meta("external_id", external_id)
	return values


func get_column_data(row_id: int, column_name: String) -> Variant:
	# we use get_row to use the external id explicitly
	var columns = get_row(row_id)
	for column in columns:
		var input_column = column.get_meta("column_name")
		if column_name != input_column:
			continue # skip it we don't have a match
		# skip the elements which aren't mapped to data
		if not default_data_mapping.has(column_name):
			continue
		var column_data = default_data_mapping[column_name]
		if not column_data.has("mapping"):
			continue
		var property_path = column_data.mapping
		var value = column[property_path]
		return value
	return null


func get_row_data(row_id: int) -> Variant:
	var values = {}
	# we use get_row to use the external id explicitly
	var columns = get_row(row_id)
	for column in columns:
		var column_name = column.get_meta("column_name")
		# write the id key once to ensure stable id's
		if not values.has("id"):
			values["id"] = column.get_meta("external_id")
		# skip the elements which aren't mapped to data
		if not default_data_mapping.has(column_name):
			continue
		var column_data = default_data_mapping[column_name]
		if not column_data.has("mapping"):
			continue
		var property_path = column_data.mapping
		var value = column[property_path]
		values[column_name] = value
	return values


# Add button on the UI is part of an ADD row button.
# This is a generic table element that can be re-used, if you don't need it.
# Then simply remove the add_data_row export variable contents.
func on_add_button_pressed():
	var new_row_id = _internal_add_row(table, new_row) # this is ok
	# TODO: internal row
	if add_data_row and insertion_row_id != -1:
		_copy_input_to_new_destination(insertion_row_id, new_row_id, true)
		_internal_apply_row_data(new_row_id, {})
	table_added_row.emit(new_row_id)


# Get the row column by column name
func get_row_column_by_name(row, column_name):
	if row == null:
		push_error("failed to get row by name")
		return null
	for column in row:
		if column.get_meta("column_name") == column_name:
			return column
	return null


# for handling signals with a single parameter value
# arguments are re-ordered due to how bind() works.
# .bind(will bind from left to right, meaning extra bound args go on the right hand side)
func _internal_value_changed(value, row_id, column_name):
	var row = _internal_get_row(row_id) # get the external ID
	var column = get_row_column_by_name(row, column_name)
	table_data_changed.emit(column.get_meta("external_id"), column_name, value)


# for handling signals without value
func _internal_event(row_id, column_name):
	var row = _internal_get_row(row_id) # get the external ID
	var column = get_row_column_by_name(row, column_name)
	table_event.emit(column.get_meta("external_id"), column_name)


func _internal_apply_row_data(row_id: int, row_info: Dictionary):
	var row = _internal_get_row(row_id)
	if row == Array() || row.size() == 0:
		return
	# for each control in the row
	for idx in range(row.size()):
		var column = row[idx]
		var column_name = column.get_meta("column_name")
		# skip the elements which aren't mapped to data
		if not default_data_mapping.has(column_name):
			continue
		# retrieve the mapping for this UI item mapping
		var mapping = default_data_mapping[column_name]
		# apply the data mapping from the insertion
		if row_info.has(column_name):
			var property_path = mapping.mapping
			column[property_path] = row_info[column_name]
		# now apply the signal to the control elementw
		if mapping.has("value_changed_signal"):
			var signal_to_bind = _internal_value_changed.bind(row_id, column_name)
			if not column.is_connected(mapping["value_changed_signal"], signal_to_bind):
				column.connect(mapping["value_changed_signal"], signal_to_bind)
		if mapping.has("internal_event"):
			var signal_to_bind = _internal_event.bind(row_id, column_name)
			if not column.is_connected(mapping["internal_event"], signal_to_bind):
				column.connect(mapping["internal_event"], signal_to_bind)
		# We have named this drag_data_override to avoid conflicts with implementations of this
		# It means an implementer would not accidentally use the reserved name _get_drag_data
		# Which has a special meaning in the engine.
		if column is UniversalDragDrop and mapping.has("drag_data_override") and column["get_drag_data"] != mapping["drag_data_override"]:
			column["get_drag_data"] = mapping["drag_data_override"]


func _copy_input_to_new_destination(src: int, dest: int, reset_input: bool = false) -> void:
	var source_row = _internal_get_row(src)
	var destination_row = _internal_get_row(dest)
	if source_row == Array() or destination_row == Array():
		return

	if source_row.size() == 0 or destination_row.size() == 0:
		return

	var min_range : int = min(source_row.size(), destination_row.size())
	for idx in range(min_range):
		var src_column = source_row[idx]
		var dest_column = destination_row[idx]
		# Check the default data mapping to ensure we have a mapping for it
		# We use this to ignore the remove button for the row.
		if not default_data_mapping.has(src_column.name):
			continue

		var property_path = default_data_mapping[src_column.name].mapping
		dest_column[property_path] = src_column[property_path]

		# used when you want the original to reset to the default value
		if reset_input:
			src_column[property_path] = default_data_mapping[src_column.name].default_value
