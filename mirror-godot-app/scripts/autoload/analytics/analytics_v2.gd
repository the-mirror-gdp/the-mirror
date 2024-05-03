extends MirrorHttpClient

enum {
TRACK_EVENT,
IDENTIFY
}


@onready var api_token = ProjectSettings.get_setting("mirror/mixpanel_api_key")

const _ANALYTICS_URL_TRACK = "https://api.mixpanel.com/track"

const _PRINT_ANALYTICS = false


## The primary method used to send an event from a client
func track_event_client(event_type: String, properties:={}) -> void:
	# Only track event if client, not server
	if Zone.is_host():
		print("Blocked sending AnalyticsV2 this is the server")
		return
	track_event(event_type, properties)


## The primary method used to send an event (warning: doesn't check for server)
func track_event(event_type: String, properties:={}) -> void:
	if _PRINT_ANALYTICS:
		print("AnalyticsV2 Track: %s, %s" % [event_type, str(properties)])
	# Create a new AnalyticsEvent
	var event = AnalyticsEvent.new()
	event.event_name = event_type
	event.user_id = Net.user_id
	properties.godotAppVersion = Util.get_version_string()
	event.properties = properties
	_send_track_event(event, properties)


## Send a single event to the Mixpanel Analytics service
func _send_track_event(event: AnalyticsEvent, properties := {}) -> void:
	var standard_properties = {
		"token": api_token,
		"distinct_id": event.user_id,
		"env": "open-source"
	}
	if not properties.is_empty():
		standard_properties.merge(properties)
	var data = {
		"event": event.event_name,
		"properties": standard_properties
	}

	var promise = self.post_request_ext(TRACK_EVENT, _ANALYTICS_URL_TRACK, data)
	var res = await promise.wait_till_fulfilled()
	if promise.is_error():
		print("Error sending track event: %s" % [res])
	else:
		if (res.has('json_result') and res.json_result.has('status')):
			var status = res.json_result.status
			# 0 is an error from Mixpanel *EVEN IF* it's 200 HTTP status
			if (status == 0):
				if (res.json_result.has('error')):
					print("Error sending track event: %s" % [res.json_result.error])
				else:
					print("Error sending track event: %s" % [res])
			#1 is success from Mixpanel
			if (status == 1):
				if _PRINT_ANALYTICS:
					print("Success sending track event: %s" % [res])
				return
