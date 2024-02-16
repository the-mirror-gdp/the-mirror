@tool
## @meta-authors TODO
## @meta-authors TODO
## @meta-version 1.1
## The dynamic links API for Firebase
## Documentation TODO.

class_name FirebaseDynamicLinks extends Node

signal dynamic_link_generated(link_result)

const _AUTHORIZATION_HEADER : String = "Authorization: Bearer "
const _API_VERSION : String = "v1"

var request : int = -1

var _base_url : String = ""

var _config : Dictionary = {}

var _auth : Dictionary
var _request_list_node : HTTPRequest

var _headers : PackedStringArray = []

enum Requests {
	NONE = -1,
	GENERATE = 0
}


func _set_config(config_json : Dictionary) -> void:
	_config = config_json
	_request_list_node = HTTPRequest.new()
	_request_list_node.connect("request_completed", self._on_request_completed)
	add_child(_request_list_node)
	_check_emulating()


func _check_emulating() -> void :
	## Check emulating
	if not Firebase.emulating:
		_base_url = "https://firebasedynamiclinks.googleapis.com/v1/shortLinks?key=%s"
		_base_url %= _config.apiKey
	else:
		var port : String = _config.emulators.ports.dynamicLinks
		if port == "":
			Firebase._printerr("You are in 'emulated' mode, but the port for Dynamic Links has not been configured.")
		else:
			_base_url = "http://localhost:{port}/{version}/".format({ version = _API_VERSION, port = port })


var _link_request_body : Dictionary = {
	"dynamicLinkInfo": {
		"domainUriPrefix": "",
		"link": "",
		"androidInfo": {
			"androidPackageName": ""
		},
		"iosInfo": {
			"iosBundleId": ""
		}
		},
	"suffix": {
		"option": ""
	}
	}

## @args log_link, APN, IBI, is_unguessable
## This function is used to generate a dynamic link using the Firebase REST API
## It will return a JSON with the shortened link
func generate_dynamic_link(long_link : String, APN : String, IBI : String, is_unguessable : bool) -> void:
	request = Requests.GENERATE
	_link_request_body.dynamicLinkInfo.domainUriPrefix = _config.domainUriPrefix
	_link_request_body.dynamicLinkInfo.link = long_link
	_link_request_body.dynamicLinkInfo.androidInfo.androidPackageName = APN
	_link_request_body.dynamicLinkInfo.iosInfo.iosBundleId = IBI
	if is_unguessable:
		_link_request_body.suffix.option = "UNGUESSABLE"
	else:
		_link_request_body.suffix.option = "SHORT"
	_request_list_node.request(_base_url, _headers, HTTPClient.METHOD_POST, JSON.stringify(_link_request_body))

func _on_request_completed(result : int, response_code : int, headers : PackedStringArray, body : PackedByteArray) -> void:
	var json = JSON.new()
	if json.parse(body.get_string_from_utf8()) == OK:
		var result_body : Dictionary = json.get_data()
		emit_signal("dynamic_link_generated", result_body.shortLink)
		request = Requests.NONE

func _on_FirebaseAuth_login_succeeded(auth_result : Dictionary) -> void:
	_auth = auth_result

func _on_FirebaseAuth_token_refresh_succeeded(auth_result : Dictionary) -> void:
	_auth = auth_result

func _on_FirebaseAuth_logout() -> void:
	_auth = {}
