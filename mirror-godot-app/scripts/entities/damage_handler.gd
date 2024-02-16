class_name DamageHandler
extends Node

# `event_origin` is where the event came from, i.e. server, a space object, player.
# In the case it's a game object or player this will provide the ID for the object that did the damage.
# This is important for the authoritative server.
# ie on_death( Player, "jdkejij322" ) # id of attacker is provided

# target_object the action was performed on, amount of damage, did they die
# actual game state for gamemodes - i.e. use this for final score, respawn
signal death(target_object: Node, event_origin: String)
signal server_revive(target_object: Node, event_origin: String) # Only emitted on the server.
signal health_changed(target_object: Node, new_health: float, old_health: float, event_origin: String)

const SERVER_ORIGIN: String = "server"
const SCRIPT_ORIGIN: String = "scripting"

var _configured: bool = false
var _target_object: Node = null
var _health: float = 100.0
var _max_health: float = 100.0


func setup_damage_handler(target_object: Node, max_health: float = 100.0) -> void:
	_target_object = target_object
	_max_health = max_health
	_health = max_health
	_configured = true
	# Global event bus - we use this to pass the events to scripting globally
	death.connect(DamageMaster.death_event)
	server_revive.connect(DamageMaster.server_revive_event)
	health_changed.connect(DamageMaster.health_changed_event)


func get_health() -> float:
	return _health


@rpc("any_peer", "call_remote", "reliable")
func rpc_set_client_health(health: float, event_origin: String) -> void:
	assert(not Zone.is_host())
	set_local_var_health(health, event_origin)


func set_local_var_health(new_health: float, event_origin: String) -> void:
	assert(_target_object)
	var old_health: float = _health
	_health = new_health
	if _health <= 0.0:
		death.emit(_target_object, event_origin)
	health_changed.emit(_target_object, _health, old_health, event_origin)
	#print("set health: ", new_health, " current: ", _health,  " for node ", _target_object, "origin: ", Zone.get_instance_type())


func damage(damage_amount: float, damage_source_id: String) -> void:
	if _health == 0.0:
		return
	_apply_health_change(-damage_amount, damage_source_id)


func damage_ratio(damage_amount: float, damage_source_id: String) -> void:
	if _health == 0.0:
		return
	_apply_health_change(-damage_amount, damage_source_id)


func heal(heal_amount: float, damage_source_id: String) -> void:
	if _health == 0.0:
		return
	_apply_health_change(heal_amount, damage_source_id)


# client or server can call this safely
func _apply_health_change(health_change: float, damage_source_id: String) -> void:
	if not _configured or not is_instance_valid(_target_object):
		push_error("Health change recieved but object was not ready! ", _target_object)
		return
	assert(_health > 0.0, "Caller should check that the object is still alive first.")
	# It is safe to apply the health directly.
	# Ideally all damage events are really serverside!
	if Zone.is_host():
		_rpc_apply_server_health_change(health_change, damage_source_id)
	else:
		# If damage happens clientside we must ask the server to calculate
		# Or throw away the health change! The calculation must be done and
		# potentially thrown away. In certain cases like death we must call
		# a special RPC to handle this case.
		_rpc_apply_server_health_change.rpc_id(Zone.SERVER_PEER_ID, health_change, damage_source_id)


# Apply the health change to the object on the server.
# Pass the updated health amount event to the clients all the time.
# But never let the client directly write the health.
@rpc("any_peer", "call_remote", "reliable")
func _rpc_apply_server_health_change(health_change: float, damage_source_id: String) -> void:
	assert(Zone.is_host())
	if _health == 0.0:
		return
	# calculate and distribute new health value to clients overriding their local value
	var new_health: float = _health
	if health_change > 0.0:
		if _health >= _max_health:
			# If trying to heal while already over max health, this may be an
			# "overheal", which would use a special code path when it exists.
			# For this method, just do nothing in this case.
			return
		new_health = minf(_health + health_change, _max_health)
	else:
		# When the health change is negative, this is damage. Don't go below 0 health.
		new_health = maxf(_health + health_change, 0.0)
	server_set_health(new_health, damage_source_id) # will auto distribute to players


# Race Condition Prevention - Health / Death / Respawn
# Server sets health to 0
# Player dies and sends RPC for set health 100 immediately
# Client received health set to 100
# Client received health set to 0
# i.e. this prevents this happening in the wrong order
func server_revive_after_delay(revive_delay: float = 5.0) -> void:
	assert(Zone.is_host(), "Only the server is allowed to manage and reset health.")
	if _health == _max_health:
		return # we don't need to wait for respawn
	await get_tree().create_timer(revive_delay).timeout
	server_set_health(_max_health, SERVER_ORIGIN)
	server_revive.emit(_target_object, SERVER_ORIGIN)


# server_set_health - serverside event only
func server_set_health(health: float, event_origin: String) -> void:
	assert(Zone.is_host(), "Only the server is allowed to manage and set health.")
	# we are already on the server ergo no RPC required.
	set_local_var_health(health, event_origin)
	# distribute new health value to clients overriding their local value
	rpc_set_client_health.rpc(health, event_origin)
