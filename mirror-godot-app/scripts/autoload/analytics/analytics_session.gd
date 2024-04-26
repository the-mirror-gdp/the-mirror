extends Timer

# Note: the whole session heartbeat method can be removed with analyticsv2, so this class is deprecated. Apr 25 2024

# Time interval for calling the method.
const INTERVAL = 10.0

var last_active_timestamp: int = update_last_active_timestamp()
var seconds_since_activity: int:
	get: return current_timestamp() - last_active_timestamp


func _ready() -> void:
	# Initialize timer settings and begin.
	set_wait_time(INTERVAL)
	set_one_shot(false)
	autostart = true
	timeout.connect(_ping_session)
	start()


func _input(_input_event: InputEvent) -> void:
	update_last_active_timestamp()


func update_last_active_timestamp() -> int:
	last_active_timestamp = current_timestamp()
	return last_active_timestamp


func current_timestamp() -> int:
	return int(floor(Time.get_unix_time_from_system()))


func get_current_role_of_user_on_space() -> StringName:
	# We use Zone.space instead of current_zone.space,
	#  because Zone.space is the only one with a list of user roles/permissions
	var role_enum_value: int = Util.get_role_for_user(Zone.space, Net.user_id)
	return Enums.as_string(Enums.ROLE, role_enum_value)


func _ping_session() -> void:
	# Get the current timestamp in seconds and round down
	var timestamp = int(floor(Time.get_unix_time_from_system()))
	var properties = {
		"timestamp" : timestamp,
	}
	# We call this many times so that if is now in one place to edit
	var properties_try_set_key = func (dest_key, src_dict, src_key) -> void:
		if src_dict and src_dict.has(src_key):
			properties[dest_key] = src_dict["_id"]

	var event
	if Zone.is_host():
		event = AnalyticsEvent.TYPE.GAME_SERVER_HEARTBEAT
		properties_try_set_key.call("spaceId", Zone.space, "_id")
		properties_try_set_key.call("spaceVersionId", Zone.space, "spaceVersion")
	else:
		event = AnalyticsEvent.TYPE.SESSION_HEARTBEAT
		properties.lastActiveTimestamp = last_active_timestamp
		properties.secondsSinceActivity = seconds_since_activity
		properties.AppMode = AppState.get_current_app_mode_as_string()

		var current_zone = Zone.client.current_zone
		var space = Zone.space


		# This if should only be true when connected to a zone godot server
		# TODO: Make Zone.space and Zone.client.current_zone reset when we quit a space
		#  Because, for now, we need to check manually that we are still connected to a space instead
		if AppState.is_user_currently_connected_to_a_space():
			# TODO: Find how to properly get space_version_id
			properties_try_set_key.call("spaceVersionId", Zone.client.current_zone, "spaceVersionId")

			properties_try_set_key.call("spaceId", Zone.space, "_id")
			# We use current_zone.space as a fallback of Zone.space, because Zone.space is not always correctly set
			if not properties.has("spaceId"):
				properties_try_set_key.call("spaceId", Zone.client.current_zone, "space")
		properties.userRole = get_current_role_of_user_on_space()
	# Note: the whole session heartbeat method can be removed with analyticsv2, so this class is deprecated
	Analytics.track_event(event, properties)
