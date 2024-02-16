class_name ScriptBlockPrintBase
extends ScriptBlockSequenced


static func value_to_friendly_string(value: Variant) -> String:
	if value is Object:
		if not is_instance_valid(value):
			return "null <invalid instance>"
		elif value is SpaceObject:
			return value.get_space_object_name() + " <SpaceObject>"
		elif value is Player:
			return value.get_player_name() + " <Player>"
	return str(value)
