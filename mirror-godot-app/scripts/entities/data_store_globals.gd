class_name DataStoreGlobalVariable
extends DataStoreBase


# This is an abstraction to hide the object id and the global key when you need to set a value
# which can be stored on an object for scripting etc
# This class lets us make a datastore for an object using a unique key which persists
# for the lifetime of the object key, rather than the individual object
# i.e. player can have players.player_id = { some data goes here }
# i.e. some space object could have an inventory now!

# the space variable key
var _global_key: String = ""
var _object_key: Variant = null

# initialise the datastore
# global_key is the name of the variable in global variables
# object_key key is the store key for this object
# i.e. if this is a player it should have a key for the player
# that persists permanently
func configure(global_key: Variant, object_key = null, default_object_data = null) -> void:
	if not set_datastore_key(global_key, object_key):
		push_error("Data store is missing it's intended key")
		return
	# do not run this on the clients
	if not Zone.is_host():
		return
	# we provide the object default data here
	Zone.script_network_sync.global_variable_changed.connect(global_variables_changed)
	# create the default data when the datastore is configured, should it not already exist
	if get_datastore() == null:
		set_datastore(default_object_data)


func global_variables_changed(variable_name: String, variable_value: Variant):
	# wait for our global key for our datastore to be made available during connection
	# to the server.
	if variable_name == _global_key:
		datastore_ready.emit()


func set_datastore_key(global_key: Variant, object_key: Variant) -> bool:
	if global_key == "" or object_key == null:
		push_error("invalid datastore configuration")
		return false
	# should this be string name?
	_global_key = global_key
	_object_key = object_key
	_configured = true
	return true


func wait_for_datastore() -> void:
	if (get_datastore() == null and _configured and is_instance_valid(self)):
		await datastore_ready


# returns null if the store is deleted
func get_datastore() -> Variant:
	if not _configured:
		return null
	if not Zone.script_network_sync.has_global_variable(_global_key):
		return null
	var global = Zone.script_network_sync.get_global_variable(_global_key)
	return global.get(_object_key, null)


func set_datastore(value: Dictionary) -> void:
	if not Zone.is_host() or not _configured:
		return

	var data_storage = Zone.script_network_sync.get_global_variable(_global_key)

	if data_storage == null:
		data_storage = {}

	var data_store = data_storage.get(_object_key, null)
	data_storage[_object_key] = value

	# apply the value to the globals
	# globals[_global_key][_object_key] = value
	# print("data store set: ", data_storage)
	Zone.script_network_sync.set_global_variable(_global_key, data_storage.duplicate(true))


# create and set
func set_value(key: Variant, value: Variant) -> void:
	var datastore = get_datastore()
	if datastore == null:
		datastore = {}
	datastore[key] = value
	# we must call this each time the state changes
	set_datastore(datastore)


func get_value(key: Variant, default_value: Variant) -> Variant:
	var datastore = get_datastore()
	if datastore:
		return datastore.get(key, default_value)
	return default_value


func erase_value(key: Variant) -> bool:
	var datastore = get_datastore()
	if datastore and datastore.has(key):
		return datastore.erase(key)
	return false

func add_to_value(key: Variant, change: Variant, default_value: Variant) -> void:
	var current_value: Variant = get_value(key, default_value)
	set_value(key, current_value + change)


# remove
func remove_value(key: Variant) -> void:
	var datastore = get_datastore()
	if not datastore:
		return # already gone ;)
	datastore.remove(key)
	# we must call this each time the state changes
	set_datastore(datastore)
