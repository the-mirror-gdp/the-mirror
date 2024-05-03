extends Node


signal analytics_send_event_successful
signal analytics_send_event_failed
signal analytics_send_batch_successful
signal analytics_send_batch_failed

var api_key = "" # set via settings

const _ANALYTICS_URL_CAPTURE = "https://app.posthog.com/capture/"
const _ANALYTICS_URL_BATCH = "https://app.posthog.com/batch/"

const _PRINT_ANALYTICS = false

var _http_capture: HTTPRequest # The main capture client will have a LOT of calls, so keeping it separate to avoid issues (e.g. the identify call was getting lost in the mix of batching event calls)
var _http_batch: HTTPRequest # We check for running batches on the _http for events, so creating a 2nd. This may not be the best implementation though.

var request_queue_capture = []
var request_queue_batch = []

const ANONYMOUS_USER_ID = "anonymous" # I _think_ it's best to keep this string as "anonymous" but I'm not sure if this can distinguish one anon user from another on a different PC, and we'd def want that. https://posthog.com/docs/integrate/identifying-users

const API_KEY_KEY = "api_key"
const EVENT_KEY = "event"
const TIMESTAMP_KEY = "timestamp"
const DISTINCT_ID_KEY = "distinct_id"
const PROPERTIES_KEY = "properties"
const BATCH_KEY = "batch"

var single_event_body = {
	API_KEY_KEY: api_key,
	EVENT_KEY: "",
	PROPERTIES_KEY: {DISTINCT_ID_KEY: ANONYMOUS_USER_ID},
	TIMESTAMP_KEY: null,
}

var batch_event_body = {
	API_KEY_KEY: api_key,
	BATCH_KEY: []
}


## The primary method used to send an event from a client
func track_event_client(event_type: String, properties := {}) -> void:
	# Only track event if client, not server
	if Zone.is_host():
		print("Blocked sending analytics this is the server")
		return
	track_event(event_type, properties)


## The primary method used to send an event from a client
func track_event(event_type: String, properties := {}) -> void:
	# V2 Analytics call. This v1 class is deprecated
	AnalyticsV2.track_event(event_type, properties)

	if _PRINT_ANALYTICS:
		print("Analytics Track: %s, %s" % [event_type, str(properties)])
	# Create a new AnalyticsEvent
	var event = AnalyticsEvent.new()
	event.event_name = event_type
	event.user_id = Net.user_id
	properties.godotAppVersion = Util.get_version_string()
	event.properties = properties
	_send_event(event)


func identify_user_email(user_id: String, email: String) -> void:
	# JSON shape: https://posthog.com/docs/api/post-only-endpoints#identify
	var data = {
		API_KEY_KEY: api_key,
		DISTINCT_ID_KEY: user_id,
		"$set": {
			"email": email
			},
		"event": "$identify"
	}
	print("Analytics (Client) Identify Email: user_id: %s, email: %s" % [user_id, email])
	# TODO: We should probably have a similar request_queue setup for the batch URL
	_http_batch.request(_ANALYTICS_URL_BATCH, PackedStringArray([]), HTTPClient.METHOD_POST, JSON.stringify(data))


## Send a single event to the Analytics (Posthog) service
func _send_event(event: AnalyticsEvent) -> void:
	var dupe = _get_formatted_single_event(event)

	if _http_capture.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		assert(dupe.api_key != "" && dupe.api_key != null)
		_http_capture.request(_ANALYTICS_URL_CAPTURE, PackedStringArray([]), HTTPClient.METHOD_POST, JSON.stringify(dupe))
	else:
		request_queue_capture.push_back({EVENT_KEY: event})


func _ready() -> void:
	api_key = ProjectSettings.get_setting("mirror/posthog_api_key")
	_http_capture = HTTPRequest.new()
	_http_capture.use_threads = true
	_http_batch = HTTPRequest.new()
	add_child(_http_capture)
	add_child(_http_batch)
	_http_capture.request_completed.connect(_on_capture_request_complete)
	_http_batch.request_completed.connect(_on_batch_request_complete)


func _get_formatted_single_event(event: AnalyticsEvent) -> Dictionary:
	var dupe = single_event_body.duplicate(true)
	dupe[API_KEY_KEY] = api_key
	dupe[EVENT_KEY] = event.event_name
	# Add the additional properties passed in
	dupe[PROPERTIES_KEY] = event.properties
	# if user_id is truthy, then use it, otherwise use anonymous user ID
	dupe[PROPERTIES_KEY][DISTINCT_ID_KEY] = event.user_id if event.user_id else ANONYMOUS_USER_ID

	if not event.timestamp != null:
		dupe.erase(TIMESTAMP_KEY)

	return dupe


func _on_capture_request_complete(_result, response_code, _headers, _body) -> void:
	if response_code == HTTPClient.RESPONSE_OK:
		analytics_send_event_successful.emit()
	else:
		analytics_send_event_failed.emit()

	if request_queue_capture.size() > 0:
		var request = request_queue_capture[0]
		var event = request[EVENT_KEY]
		_send_event(event)
		request_queue_capture.remove_at(0)


func _on_batch_request_complete(_result, response_code, _headers, _body) -> void:
	if response_code == HTTPClient.RESPONSE_OK:
		analytics_send_batch_successful.emit()
	else:
		analytics_send_batch_failed.emit()

	# TODO we should probably add a request queue here too for batch events
