class_name DataStoreBase
extends Node


signal datastore_ready()

## DatsStoreBase is a class intended to make "globals" and "local" variables
## able to be stored on a class in a "generic" way where any object could store
## a property or node path property on an object.
## The implementations are in the classes that exend this one
## This could be used for saving the game status in the future as we could
## Use this for all space object properties in the future :)
## If an object has health this is useful because the "health" property
## in space object or player is completley uniform to access.
## So implementations like "DamageBase" can just read their respective DataStoreBase
## For the health variable.
## This also means the data store could be pre-cached in the client for loading and unloading objects.
## We could also add to_dictionary() and populate() functions here
## During the space object refactor we should implement this.

## NOTE: another useful thing is it could be used for mapping from "camelCase" to "camel_case"
## transparently from an implementation on the derived classes.

# We can only use this if it has been configured.
var _configured = false

# initialise the datastore
# global_key is the name of the variable in global variables
# object_key key is the store key for this object
# i.e. if this is a player it should have a key for the player
# that persists permanently
func configure(global_key: Variant, object_key, default_object_data) -> void:
	pass

# create and set
func set_value(key: Variant, value: Variant) -> void:
	return


func get_value(key: Variant, default_value: Variant) -> Variant:
	return null


func erase_value(key: Variant) -> bool:
	return false


func add_to_value(key: Variant, change: Variant, default_value: Variant) -> void:
	pass

