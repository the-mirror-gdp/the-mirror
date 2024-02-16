class_name GDScriptInstance
extends ScriptInstance


## Serializes a Dictionary of only valid JSON types for saving to the database.
## For example, we represent `Vector3(1, 2, 3)` as a JSON array of size 3 `[1, 2, 3]`.
func serialize_to_json() -> Dictionary:
	var ret: Dictionary = super()
	ret["type"] = "GDScript"
	# Keep the Dictionary keys sorted since they are sorted on the DB side,
	# and we want what we serialize here to be identical to what get saved.
	ret.sort()
	return ret


func can_execute() -> bool:
	if not super():
		return false
	# For security reasons, only the server may execute custom GDScript code.
	return Zone.is_host()
