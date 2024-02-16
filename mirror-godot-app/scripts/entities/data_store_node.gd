class_name DataStoreNode
extends DataStoreBase

var data_store_node: Object = null

# This is a proxy to guarantee consumers of the DataStoreBase can always set properties correctly.
# It must call the set_property_on_node function

# We only need the configure call to set the node in use.
func configure(global_key: Variant, _not_used_key = null, _not_used_defaults = null) -> void:
	if not global_key:
		push_error("invalid data store node")
		return
	data_store_node = global_key
	_configured = true

# create and set
func set_value(key: Variant, value: Variant) -> void:
	Zone.script_network_sync.set_variable_on_node_at_path(data_store_node.get_path(), key, value)


func get_value(key: Variant, default_value: Variant) -> Variant:
	var value = data_store_node.get(key)
	return value if value != null else default_value


func erase_value(key: Variant) -> bool:
	if not data_store_node:
		return false
	Zone.script_network_sync.delete_variable_on_node_at_path(data_store_node.get_path(), key)
	return true


func add_to_value(key: Variant, change: Variant, default_value: Variant) -> void:
	var current_value: Variant = get_value(key, default_value)
	set_value(key, current_value + change)
