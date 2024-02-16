@tool
## @meta-authors TODO
## @meta-version 2.2
## Data structure that holds the currently-known data at a given path (a.k.a. reference) in a Firebase Realtime Database.
## Can process both puts and patches into the data based on realtime events received from the service.

class_name FirebaseDatabaseStore extends Node

const _DELIMITER : String = "/"
const _ROOT : String = "_root"

## @default false
## Whether the store is in debug mode.
var debug : bool = false
var _data : Dictionary = { }


## @args path, payload
## Puts a new payload into this data store at the given path. Any existing values in this data store
## at the specified path will be completely erased.
func put(path : String, payload) -> void:
	_update_data(path, payload, false)

## @args path, payload
## Patches an update payload into this data store at the specified path.
## NOTE: When patching in updates to arrays, payload should contain the entire new array! Updating single elements/indexes of an array is not supported. Sometimes when manually mutating array data directly from the Firebase Realtime Database console, single-element patches will be sent out which can cause issues here.
func patch(path : String, payload) -> void:
	_update_data(path, payload, true)

## @args path, payload
## Deletes data at the reference point provided
## NOTE: This will delete without warning, so make sure the reference is pointed to the level you want and not the root or you will lose everything
func delete(path : String, payload) -> void:
	_update_data(path, payload, true)

## Returns a deep copy of this data store's payload.
func get_data() -> Dictionary:
	return _data[_ROOT].duplicate(true)

#
# Updates this data store by either putting or patching the provided payload into it at the given
# path. The provided payload can technically be any value.
#
func _update_data(path: String, payload, patch: bool) -> void:
	if debug:
		print("Updating data store (patch = %s) (%s = %s)..." % [patch, path, payload])

		#
		# Remove any leading separators.
		#
	path = path.lstrip(_DELIMITER)

		#
		# Traverse the path.
		#
	var dict = _data
	var keys = PackedStringArray([_ROOT])

	keys.append_array(path.split(_DELIMITER, false))

	var final_key_idx = (keys.size() - 1)
	var final_key = (keys[final_key_idx])

	keys.remove(final_key_idx)

	for key in keys:
		if !dict.has(key):
			dict[key] = { }

		dict = dict[key]

		#
		# Handle non-patch (a.k.a. put) mode and then update the destination value.
		#
	var new_type = typeof(payload)

	if !patch:
		dict.erase(final_key)

	if new_type == TYPE_NIL:
		dict.erase(final_key)
	elif new_type == TYPE_DICTIONARY:
		if !dict.has(final_key):
			dict[final_key] = { }

		_update_dictionary(dict[final_key], payload)
	else:
		dict[final_key] = payload

	if debug:
		print("...Data store updated (%s)." % _data)

#
# Helper method to "blit" changes in an update dictionary payload onto an original dictionary.
# Parameters are directly changed via reference.
#
func _update_dictionary(original_dict: Dictionary, update_payload: Dictionary) -> void:
	for key in update_payload.keys():
		var val_type = typeof(update_payload[key])

		if val_type == TYPE_NIL:
			original_dict.erase(key)
		elif val_type == TYPE_DICTIONARY:
			if !original_dict.has(key):
				original_dict[key] = { }

			_update_dictionary(original_dict[key], update_payload[key])
		else:
			original_dict[key] = update_payload[key]
