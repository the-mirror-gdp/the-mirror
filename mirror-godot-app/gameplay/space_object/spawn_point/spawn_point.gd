extends Node
class_name SpawnPoint

# -1 is invalid
var team_id: int = -1 ### What we actually need


### The boilerplate
func serialize_to_dictionary(
	space_object_data: Dictionary,
	delta_dict: Dictionary) -> Dictionary:
	if team_id != -1:
		Util.apply_delta_to_dict(space_object_data, delta_dict, "spawnPointTeam",
			team_id)
	return delta_dict


func populate(space_object_data: Dictionary) -> void:
	team_id = space_object_data.get("spawnPointTeam", -1)


# should the space object create this on a sub node?
func should_populate():
	return has_meta("OMI_spawn_point")
