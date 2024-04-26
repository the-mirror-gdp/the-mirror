extends MirrorHttpClient

signal analytics_send_event_successful
signal analytics_send_event_failed
signal analytics_send_batch_successful
signal analytics_send_batch_failed

enum {
TRACK_EVENT,
IDENTIFY
}

var api_token = "" # set via settings

const _ANALYTICS_URL_TRACK = "https://api.mixpanel.com/track"
const _ANALYTICS_URL_IDENTIFY = "https://api.mixpanel.com/engage#profile-set"

const _PRINT_ANALYTICS = false

var _http_track: HTTPRequest # The main capture client will have a LOT of calls, so keeping it separate to avoid issues (e.g. the identify call was getting lost in the mix of batching event calls)
var _http_identify: HTTPRequest

var request_queue_capture = []
var request_queue_batch = []

const EVENT_KEY = "event"
const BATCH_KEY = "batch"

# var single_event_body = {
# 	API_KEY_KEY: api_token,
# 	EVENT_KEY: "",
# 	PROPERTIES_KEY: {DISTINCT_ID_KEY: ANONYMOUS_USER_ID},
# 	TIMESTAMP_KEY: null,
# }
var single_event_body = {
		"event": "",
		"properties": {
			"token": "",
			"time": "",
			"distinct_id": ""
		}
}

	#var data = {
		#"event": "",
		#"properties": {
			#"token": api_token,
			#"time": time,
			#"distinct_id": user_id
		#}

## The primary method used to send an event from a client
func track_event_client(event_type: String, properties:={}) -> void:
	# Only track event if client, not server
	if Zone.is_host():
		print("Blocked sending AnalyticsV2 this is the server")
		return
	track_event(event_type, properties)

## The primary method used to send an event from a client
func track_event(event_type: String, properties:={}) -> void:
	if _PRINT_ANALYTICS:
		print("AnalyticsV2 Track: %s, %s" % [event_type, str(properties)])
	# Create a new AnalyticsEvent
	var event = AnalyticsEvent.new()
	event.event_name = event_type
	event.user_id = Net.user_id
	properties.godotAppVersion = Util.get_version_string()
	event.properties = properties
	_send_track_event(event)

func identify(user_id: String, email: String) -> void:
	# JSON shape: https://developer.mixpanel.com/reference/track-event
	var time = Time.get_unix_time_from_system()
	#var data = {
		#"token": api_token,
		#"distinct_id": user_id
	#}
	#var data = { "verbose":1, "data": {"verbose":1, "event": "testevent2", "token":"c5e82051367277731c1b1cf0d46d9d57P","time":1714086211243,"$distinct_id":"6373dd777cc7fc7cdc82da81", "$set": { "$email": "jared+TESTREMOVE2@themirror.space"}}}
	#var data = 'verbose=1'
	var dataTrack = 'data={"event": "testevent2", "properties":{ "token":"c5e82051367277731c1b1cf0d46d9d57P","time":1714086211243,"distinct_id":"6373dd777cc7fc7cdc82da81"}}&verbose=1'
	var dataIdentify = [
	{
		"$token": "3a6c8ecd90b361c2024d064d5769bc08",
		"$distinct_id": "6373dd777cc7fc7cdc82da81",
		"$set": {
			"$email": "jared+TESTREMOVE2@themirror.space"
		}
	}
	]
	print("AnalyticsV2 (Client) Identify Email: user_id: %s, email: %s" % [user_id, email])
	# TODO: We should probably have a similar request_queue setup for the batch URL
	# _http_identify.request(_ANALYTICS_URL_IDENTIFY,  PackedStringArray(["Accept: text/plain", "Content-Type: application/json", "Host: api.mixpanel.com"]), HTTPClient.METHOD_POST, JSON.stringify(dataIdentify))
	# temp
	# _http_track.request(_ANALYTICS_URL_TRACK,  PackedStringArray(["accept: */*", "content-type: application/x-www-form-urlencoded"]), HTTPClient.METHOD_POST,dataTrack)
	track_event_client('test10promise')

## Send a single event to the Mixpanel Analytics service
func _send_track_event(event: AnalyticsEvent) -> void:
	var data = {
	 "event": event.event_name,
	 "properties":
	 {
	  "token": api_token,
		"distinct_id": event.user_id
		}
	}
	var promise = self.post_request_ext(TRACK_EVENT, _ANALYTICS_URL_TRACK, data)
	var res = await promise.wait_till_fulfilled()
	if promise.is_error():
		print("Error sending track event: %s" % [res])
		analytics_send_event_failed.emit()
	else:

		if (res.has('json_result') and res.json_result.has('status')):
			var status = res.json_result.status
			# 0 is an error from Mixpanel *EVEN IF* it's 200 HTTP status
			if (status == 0):
				if (res.json_result.has('error')):
					print("Error sending track event: %s" % [res.json_result.error])
				else:
					print("Error sending track event: %s" % [res])
				analytics_send_event_failed.emit()
			#1 is success from Mixpanel
			if (status == 1):
				print("Success sending track event: %s" % [res])
				analytics_send_event_successful.emit()
	# working save
	#	var data = 'data={"event": "testevent2", "properties":{ "token":"c5e82051367277731c1b1cf0d46d9d57P","time":1714086211243,"distinct_id":"6373dd777cc7fc7cdc82da81"}}&verbose=1'

	# Commenting out old batch queue logic; can reimplement post-promises
	# var dupe = _get_formatted_single_event(event)

	# if _http_track.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
	# 	assert(dupe.api_token != "" && dupe.api_token != null)
	# 	_http_track.request(_ANALYTICS_URL_TRACK,  PackedStringArray(["accept: */*", "content-type: application/x-www-form-urlencoded"]), HTTPClient.METHOD_POST, JSON.stringify(dupe))
	# else:
	# 	request_queue_capture.push_back({EVENT_KEY: event})

func _ready() -> void:
	api_token = ProjectSettings.get_setting("mirror/mixpanel_api_token")
	# _http_track = HTTPRequest.new()
	# _http_track.use_threads = true
	_http_identify = HTTPRequest.new()
	_http_identify.accept_gzip = false
	# add_child(_http_track)
	add_child(_http_identify)
	# _http_track.request_completed.connect(_on_track_request_complete)
	_http_identify.request_completed.connect(_on_identify_request_complete)

func _get_formatted_single_event(event: AnalyticsEvent) -> Dictionary:
	var dupe = single_event_body.duplicate(true)
	dupe["event"] = event.event_name
	dupe["properties"]["token"] = api_token
	dupe["properties"]["time"] = event.timestamp
	# if user_id is truthy, then use it, otherwise use anonymous user ID
	dupe["properties"]["distinct_id"] = event.user_id if event.user_id else ""

	return dupe

# func _on_track_request_complete(_result, response_code, _headers, _body) -> void:
# 	var test = _body.get_string_from_utf8()
# 	if response_code == HTTPClient.RESPONSE_OK:
# 		analytics_send_event_successful.emit()
# 	else:
# 		analytics_send_event_failed.emit()

# 	if request_queue_capture.size() > 0:
# 		var request = request_queue_capture[0]
# 		var event = request[EVENT_KEY]
# 		_send_track_event(event)
# 		request_queue_capture.remove_at(0)

func _on_identify_request_complete(_result, response_code, _headers, _body) -> void:
	if response_code == HTTPClient.RESPONSE_OK:
		analytics_send_batch_successful.emit()
	else:
		analytics_send_batch_failed.emit()

	# TODO we should probably add a request queue here too for batch events
