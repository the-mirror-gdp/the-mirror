class_name ZoneFinder
extends MirrorHttpClient

enum {
	GET_ZONE,
	JOIN_BUILD_SERVER,
	JOIN_PLAY_SERVER,
	JOIN_PLAY_SERVER_BY_ZONE_ID,
	GET_PUBLISHED_SPACES,
}

var ready_zones : Array = [] # this will be removed shortly

func get_zone(zone_id) -> Promise:
	return self.get_request(GET_ZONE, "/zone/%s" % zone_id)


func join_build_server(space_id: String) -> Promise:
	return self.get_request(JOIN_BUILD_SERVER, "/zone/join-build-server/%s" % space_id)


func join_play_server(space_id: String) -> Promise:
	return self.get_request(JOIN_PLAY_SERVER, "/zone/join-play-server/space/%s" % space_id)


func join_play_server_by_zone_id(zone_id: String) -> Promise:
	return self.get_request(JOIN_PLAY_SERVER_BY_ZONE_ID, "/zone/join-play-server/zone/%s" % zone_id)


func get_published_spaces() -> Promise:
	return self.get_request(GET_PUBLISHED_SPACES, "/space/get-published-spaces/")


## Signal routes a successful request to the appropriate complete method.
func _promise_fulfill_successful(request: Dictionary, promise: Promise) -> void:
	var http_response_code = request["code"]
	if not request["json_parse_success"]:
		var error_str = "ZoneFinder invalid json_parse_success data, expected flag with json data"
		promise.set_error(error_str)
		push_error(error_str)
		return
	if http_response_code >= 300:
		var error_str = "ZoneFinder error code %d" % http_response_code
		push_error(error_str)
		promise.set_error(error_str)
		return
	var response = request["json_result"]
	promise.set_result(response)
