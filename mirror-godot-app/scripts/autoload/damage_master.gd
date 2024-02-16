extends Node

# This class is just a wrapper for all object damage events.
# The intent is to use these as a global event bus for damage.
# While also allowing the programmer to use the local methods too if they choose to.

# NOTE: copy these directly from `damage_handler.gd` all the signals there
# should be in this file too!
signal death(target_object: Node, event_origin: String)
signal server_revive(target_object: Node, event_origin: String) # Only emitted on the server.
signal health_changed(target_object: Node, new_health: float, old_health: float, event_origin: String)

func death_event(target_object: Node, event_origin: String):
	death.emit(target_object, event_origin)


func server_revive_event(target_object: Node, event_origin: String):
	server_revive.emit(target_object, event_origin)


func health_changed_event(target_object: Node, new_health: float, old_health: float, event_origin: String):
	health_changed.emit(target_object, new_health, old_health, event_origin)
