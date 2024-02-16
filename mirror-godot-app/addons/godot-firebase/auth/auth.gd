@tool
## @meta-authors TODO
## @meta-version 2.5
## The authentication API for Firebase.
## Documentation TODO.

class_name FirebaseAuth extends HTTPRequest

const _API_VERSION : String = "v1"

# Emitted for each Auth request issued.
# `result_code` -> Either `1` if auth succeeded or `error_code` if unsuccessful auth request
# `result_content` -> Either `auth_result` if auth succeeded or `error_message` if unsuccessful auth request
signal auth_request(result_code, result_content)

signal signup_succeeded(auth_result)
signal login_succeeded(auth_result)
signal login_failed(code, message)
signal signup_failed(code, message)
signal userdata_received(userdata)
signal token_exchanged(successful)
signal token_refresh_succeeded(auth_result)
signal logged_out()

const RESPONSE_SIGNUP : String   = "identitytoolkit#SignupNewUserResponse"
const RESPONSE_SIGNIN : String   = "identitytoolkit#VerifyPasswordResponse"
const RESPONSE_ASSERTION : String  = "identitytoolkit#VerifyAssertionResponse"
const RESPONSE_USERDATA : String = "identitytoolkit#GetAccountInfoResponse"
const RESPONSE_CUSTOM_TOKEN : String = "identitytoolkit#VerifyCustomTokenResponse"

var _base_url : String = ""
var _refresh_request_base_url = ""
var _signup_request_url : String = "accounts:signUp?key=%s"
var _signin_with_oauth_request_url : String = "accounts:signInWithIdp?key=%s"
var _signin_request_url : String = "accounts:signInWithPassword?key=%s"
var _signin_custom_token_url : String = "accounts:signInWithCustomToken?key=%s"
var _userdata_request_url : String = "accounts:lookup?key=%s"
var _oobcode_request_url : String = "accounts:sendOobCode?key=%s"
var _delete_account_request_url : String = "accounts:delete?key=%s"
var _update_account_request_url : String = "accounts:update?key=%s"

var _refresh_request_url : String = "/v1/token?key=%s"
var _google_auth_request_url : String = "https://accounts.google.com/o/oauth2/v2/auth?"
var _google_token_request_url : String = "https://oauth2.googleapis.com/token?"

var _config : Dictionary = {}
var auth : Dictionary = {}
var _needs_refresh : bool = false
var is_busy : bool = false


var tcp_server : TCPServer = TCPServer.new()
var tcp_timer : Timer = Timer.new()
var tcp_timeout : float = 0.5

var _headers : PackedStringArray = [
	"Accept: application/json",
	"Content-Type: application/json"
]

var requesting : int = -1

enum Requests {
	NONE = -1,
	EXCHANGE_TOKEN=0,
	LOGIN_WITH_OAUTH=1,
}


var auth_request_type : int = -1

enum Auth_Type {
	LOGIN_EP=0,
	LOGIN_ANON=1,
	LOGIN_CT=2,
	LOGIN_OAUTH=3,
	SIGNUP_EP=4,
	NONE = -1,
}


var _login_request_body : Dictionary = {
	"email":"",
	"password":"",
	"returnSecureToken": true,
}

var _post_body : String = "id_token=[GOOGLE_ID_TOKEN]&providerId=[PROVIDER_ID]"
var _request_uri : String = "[REQUEST_URI]"

var _oauth_login_request_body : Dictionary = {
	"postBody":"",
	"requestUri":"",
	"returnIdpCredential":true,
	"returnSecureToken":true
}

var _anonymous_login_request_body : Dictionary = {
	"returnSecureToken":true
}

var _refresh_request_body : Dictionary = {
	"grant_type":"refresh_token",
	"refresh_token":"",
}

var _custom_token_body : Dictionary = {
	"token":"",
	"returnSecureToken":true
}

var _password_reset_body : Dictionary = {
	"requestType":"password_reset",
	"email":"",
}


var _change_email_body : Dictionary = {
	"idToken":"",
	"email":"",
	"returnSecureToken": true,
}


var _change_password_body : Dictionary = {
	"idToken":"",
	"password":"",
	"returnSecureToken": true,
}


var _account_verification_body : Dictionary = {
	"requestType":"verify_email",
	"idToken":"",
}


var _update_profile_body : Dictionary = {
	"idToken":"",
	"displayName":"",
	"photoUrl":"",
	"deleteAttribute":"",
	"returnSecureToken":true
}

var _google_auth_body : Dictionary = {
	"scope":"email openid profile",
	"response_type":"code",
	"redirect_uri":"",
	"client_id":"[CLIENT_ID]"
}

var _google_token_body : Dictionary = {
	"code":"",
	"client_id":"",
	"client_secret":"",
	"redirect_uri":"",
	"grant_type":"authorization_code"
}

func _ready() -> void:
	tcp_timer.wait_time = tcp_timeout
	tcp_timer.connect("timeout", Callable(self, "_tcp_stream_timer"))


# Sets the configuration needed for the plugin to talk to Firebase
# These settings come from the firebase.gd script automatically
func _set_config(config_json : Dictionary) -> void:
	_config = config_json
	_signup_request_url %= _config.apiKey
	_signin_request_url %= _config.apiKey
	_signin_custom_token_url %= _config.apiKey
	_signin_with_oauth_request_url %= _config.apiKey
	_userdata_request_url %= _config.apiKey
	_refresh_request_url %= _config.apiKey
	_oobcode_request_url %= _config.apiKey
	_delete_account_request_url %= _config.apiKey
	_update_account_request_url %= _config.apiKey

	connect("request_completed", Callable(self, "_on_FirebaseAuth_request_completed"))
	_check_emulating()


func _check_emulating() -> void :
	## Check emulating
	if not Firebase.emulating:
		_base_url = "https://identitytoolkit.googleapis.com/{version}/".format({ version = _API_VERSION })
		_refresh_request_base_url = "https://securetoken.googleapis.com"
	else:
		var port : String = _config.emulators.ports.authentication
		if port == "":
			Firebase._printerr("You are in 'emulated' mode, but the port for Authentication has not been configured.")
		else:
			_base_url = "http://localhost:{port}/identitytoolkit.googleapis.com/{version}/".format({ version = _API_VERSION ,port = port })
			_refresh_request_base_url = "http://localhost:{port}/securetoken.googleapis.com".format({port = port})


# Function is used to check if the auth script is ready to process a request. Returns true if it is not currently processing
# If false it will print an error
func _is_ready() -> bool:
	if is_busy:
		Firebase._printerr("Firebase Auth is currently busy and cannot process this request")
		return false
	else:
		return true


# Synchronous call to check if any user is already logged in.
func is_logged_in() -> bool:
	return auth != null and auth.has("idtoken")

# Synchronous call to get the uid of the current user
func get_jwt() -> String:
	if auth.has('idtoken'):
		return auth.idtoken
	return ""


# Called with Firebase.Auth.signup_with_email_and_password(email, password)
# You must pass in the email and password to this function for it to work correctly
func signup_with_email_and_password(email : String, password : String) -> void:
	if _is_ready():
		is_busy = true
		_login_request_body.email = email
		_login_request_body.password = password
		auth_request_type = Auth_Type.SIGNUP_EP
		var json = JSON.new()
		request(_base_url + _signup_request_url, _headers, HTTPClient.METHOD_POST, JSON.stringify(_login_request_body))


# Called with Firebase.Auth.anonymous_login()
# A successful request is indicated by a 200 OK HTTP status code.
# The response contains the Firebase ID token and refresh token associated with the anonymous user.
# The 'mail' field will be empty since no email is linked to an anonymous user
func login_anonymous() -> void:
	if _is_ready():
		is_busy = true
		auth_request_type = Auth_Type.LOGIN_ANON
		var json = JSON.new()
		request(_base_url + _signup_request_url, _headers, HTTPClient.METHOD_POST, JSON.stringify(_anonymous_login_request_body))


# Called with Firebase.Auth.login_with_email_and_password(email, password)
# You must pass in the email and password to this function for it to work correctly
# If the login fails it will return an error code through the function _on_FirebaseAuth_request_completed
func login_with_email_and_password(email : String, password : String) -> void:
	if _is_ready():
		is_busy = true
		_login_request_body.email = email
		_login_request_body.password = password
		auth_request_type = Auth_Type.LOGIN_EP
		var json = JSON.new()
		request(_base_url + _signin_request_url, _headers, HTTPClient.METHOD_POST, JSON.stringify(_login_request_body))

# Login with a custom valid token
# The token needs to be generated using an external service/function
func login_with_custom_token(token : String) -> void:
	if _is_ready():
		is_busy = true
		_custom_token_body.token = token
		auth_request_type = Auth_Type.LOGIN_CT
		var json = JSON.new()
		request(_base_url + _signin_custom_token_url, _headers, HTTPClient.METHOD_POST, JSON.stringify(_custom_token_body))

# Open a web page in browser redirecting to Google oAuth2 page for the current project
# Once given user's authorization, a token will be generated.
# NOTE** with this method, the authorization process will be copy-pasted

func get_google_auth(redirect_uri : String = "urn:ietf:wg:oauth:2.0:oob", client_id : String = _config.clientId) -> void:
	var url_endpoint : String = _google_auth_request_url
	_google_auth_body.redirect_uri = redirect_uri


func get_google_auth_manual() -> void:
	var url_endpoint : String = _google_auth_request_url
	_google_auth_body.redirect_uri = "urn:ietf:wg:oauth:2.0:oob"
	for key in _google_auth_body.keys():
		url_endpoint+=key+"="+_google_auth_body[key]+"&"
	url_endpoint = url_endpoint.replace("[CLIENT_ID]&", _config.clientId)
	OS.shell_open(url_endpoint)

# Exchange the authorization oAuth2 code obtained from browser with a proper access id_token
func exchange_google_token(google_token : String, redirect_uri : String = "urn:ietf:wg:oauth:2.0:oob") -> void:
	if _is_ready():
		is_busy = true
		_google_token_body.code = google_token
		_google_token_body.client_id = _config.clientId
		_google_token_body.client_secret = _config.clientSecret
		_google_token_body.redirect_uri = redirect_uri
		requesting = Requests.EXCHANGE_TOKEN
		var json = JSON.new()
		request(_google_token_request_url, _headers, HTTPClient.METHOD_POST, JSON.stringify(_google_token_body))


func get_google_auth_redirect(redirect_uri : String, listen_to_port : int) -> void:
	var url_endpoint : String = _google_auth_request_url
	_google_auth_body.redirect_uri = redirect_uri
	for key in _google_auth_body.keys():
		url_endpoint+=key+"="+_google_auth_body[key]+"&"
	url_endpoint = url_endpoint.replace("[CLIENT_ID]&", _config.clientId)
	OS.shell_open(url_endpoint)
	await get_tree().create_timer(1).timeout
	add_child(tcp_timer)
	tcp_timer.start()
	tcp_server.listen(listen_to_port, "::")


# Open a web page in browser redirecting to Google oAuth2 page for the current project
# Once given user's authorization, a token will be generated.
# NOTE** the generated token will be automatically captured and a login request will be made if the token is correct
func get_google_auth_localhost(port : int = 49152):
	get_google_auth_redirect("http://localhost:%s/" % port, port)


# A timer used to listen through TCP on the redirect uri of the request
func _tcp_stream_timer() -> void:
	var peer : StreamPeer = tcp_server.take_connection()
	if peer != null:
		var raw_result : String = peer.get_utf8_string(100)
		if raw_result != "" and raw_result.begins_with("GET"):
			var token : String = raw_result.rsplit("=")[1].rstrip("&scope")
			tcp_server.stop()
			peer.disconnect_from_host()
			tcp_timer.stop()
			remove_child(tcp_timer)
			login_with_oauth(token, _google_auth_body.redirect_uri)


# Login with Google oAuth2.
# A token is automatically obtained using an authorization code using @get_google_auth()
# @provider_id and @request_uri can be changed
func login_with_oauth(_google_token: String, request_uri : String = "urn:ietf:wg:oauth:2.0:oob", provider_id : String = "google.com") -> void:
	var google_token : String = _google_token.uri_decode()
	_exchange_google_token(google_token, request_uri)
	var is_successful : bool = await self.token_exchanged
	if is_successful and _is_ready():
		is_busy = true
		_oauth_login_request_body.postBody = _post_body.replace("[GOOGLE_ID_TOKEN]", auth.idtoken).replace("[PROVIDER_ID]", provider_id)
		_oauth_login_request_body.requestUri = _request_uri.replace("[REQUEST_URI]", request_uri if request_uri != "urn:ietf:wg:oauth:2.0:oob" else "http://localhost")
		requesting = Requests.LOGIN_WITH_OAUTH
		auth_request_type = Auth_Type.LOGIN_OAUTH
		var json = JSON.new()
		request(_base_url + _signin_with_oauth_request_url, _headers, HTTPClient.METHOD_POST, json.stringify(_oauth_login_request_body))


# Exchange the authorization oAuth2 code obtained from browser with a proper access id_token
func _exchange_google_token(google_token : String, redirect_uri : String = "urn:ietf:wg:oauth:2.0:oob") -> void:
	if _is_ready():
		is_busy = true
		_google_token_body.code = google_token
		_google_token_body.redirect_uri = redirect_uri
		_google_token_body.client_id = _config.clientId
		_google_token_body.client_secret = _config.clientSecret
		requesting = Requests.EXCHANGE_TOKEN
		var json = JSON.new()
		request(_google_token_request_url, _headers, HTTPClient.METHOD_POST, JSON.stringify(_google_token_body))


# Function used to logout of the system, this will also remove the local encrypted auth file if there is one
func logout() -> void:
	auth = {}
	remove_auth()
	emit_signal("logged_out")


# Function is called when requesting a manual token refresh
func manual_token_refresh(auth_data):
	auth = auth_data
	var refresh_token = null
	auth = get_clean_keys(auth)
	if auth.has("refreshtoken"):
		refresh_token = auth.refreshtoken
	elif auth.has("refresh_token"):
		refresh_token = auth.refresh_token
	_needs_refresh = true
	_refresh_request_body.refresh_token = refresh_token
	var json = JSON.new()
	request(_refresh_request_base_url + _refresh_request_url, _headers, HTTPClient.METHOD_POST, JSON.stringify(_refresh_request_body))


# This function is called whenever there is an authentication request to Firebase
# On an error, this function with emit the signal 'login_failed' and print the error to the console
func _on_FirebaseAuth_request_completed(result : int, response_code : int, headers : PackedStringArray, body : PackedByteArray) -> void:
	is_busy = false
	var res
	if response_code == 0:
		# Mocked error results to trigger the correct signal.
		# Can occur if there is no internet connection, or the service is down,
		# in which case there is no json_body (and thus parsing would fail).
		res = {"error": {
			"code": "Connection error",
			"message": "Error connecting to auth service"}}
	else:
		var bod = body.get_string_from_utf8()
		var json = JSON.new()
		if json.parse(bod) == OK:
			res = json.get_data()
		else:
			Firebase._printerr("Error while parsing auth body json")
			emit_signal("auth_request", ERR_PARSE_ERROR, "Error while parsing auth body json")
			return

	if response_code == HTTPClient.RESPONSE_OK:
		if not res.has("kind"):
			auth = get_clean_keys(res)
			match requesting:
				Requests.EXCHANGE_TOKEN:
					emit_signal("token_exchanged", true)
			begin_refresh_countdown()
			# Refresh token countdown
			emit_signal("auth_request", 1, auth)
		else:
			match res.kind:
				RESPONSE_SIGNUP:
					auth = get_clean_keys(res)
					emit_signal("signup_succeeded", auth)
					begin_refresh_countdown()
				RESPONSE_SIGNIN, RESPONSE_ASSERTION, RESPONSE_CUSTOM_TOKEN:
					auth = get_clean_keys(res)
					emit_signal("login_succeeded", auth)
					begin_refresh_countdown()
				RESPONSE_USERDATA:
					var userdata = FirebaseUserData.new(res.users[0])
					emit_signal("userdata_received", userdata)
			emit_signal("auth_request", 1, auth)
	else:
		# error message would be INVALID_EMAIL, EMAIL_NOT_FOUND, INVALID_PASSWORD, USER_DISABLED or WEAK_PASSWORD
		if requesting == Requests.EXCHANGE_TOKEN:
			emit_signal("token_exchanged", false)
			emit_signal("login_failed", res.error, res.error_description)
			emit_signal("auth_request", res.error, res.error_description)
		else:
			var sig = "signup_failed" if auth_request_type == Auth_Type.SIGNUP_EP else "login_failed"
			emit_signal(sig, res.error.code, res.error.message)
			emit_signal("auth_request", res.error.code, res.error.message)
	requesting = Requests.NONE
	auth_request_type = Auth_Type.NONE


# Function used to save the auth data provided by Firebase into an encrypted file
# Note this does not work in HTML5 or UWP
func save_auth(auth: Dictionary) -> void:
	var encrypted_file = FileAccess.open_encrypted_with_pass("user://user.auth", FileAccess.WRITE, _config.apiKey)
	if encrypted_file == null:
		Firebase._printerr("Error Opening File.")
	else:
		encrypted_file.store_line(JSON.stringify(auth))
		encrypted_file.flush()


# Function used to load the auth data file that has been stored locally
# Note this does not work in HTML5 or UWP
func load_auth() -> void:
	var encrypted_file = FileAccess.open_encrypted_with_pass("user://user.auth", FileAccess.READ, _config.apiKey)
	if encrypted_file == null:
		Firebase._printerr("Error Opening Firebase Auth File.")
		emit_signal("auth_request", ERR_FILE_CANT_OPEN, "Error Opening Firebase Auth File.")
	else:
		var json: JSON = JSON.new()
		json.parse(encrypted_file.get_line())
		var encrypted_file_data = json.get_data()
		manual_token_refresh(encrypted_file_data)


# Function used to remove the local encrypted auth file
func remove_auth() -> void:
	if FileAccess.file_exists("user://user.auth"):
		DirAccess.remove_absolute("user://user.auth")
	else:
		Firebase._printerr("No encrypted auth file exists")


# Function to check if there is an encrypted auth data file
# If there is, the game will load it and refresh the token
func check_auth_file() -> bool:
	if FileAccess.file_exists("user://user.auth"):
		# Will ensure "auth_request" emitted
		load_auth()
		return true
	Firebase._printerr("Encrypted Firebase Auth file does not exist")
	emit_signal("auth_request", ERR_DOES_NOT_EXIST, "Encrypted Firebase Auth file does not exist")
	return false


# Function used to change the email account for the currently logged in user
func change_user_email(email: String) -> void:
	if _is_ready():
		is_busy = true
		_change_email_body.email = email
		_change_email_body.idToken = auth.idtoken
		request(_base_url + _update_account_request_url, _headers, HTTPClient.METHOD_POST, JSON.stringify(_change_email_body))


# Function used to change the password for the currently logged in user
func change_user_password(password : String) -> void:
	if _is_ready():
		is_busy = true
		_change_password_body.password = password
		_change_password_body.idToken = auth.idtoken
		request(_base_url + _update_account_request_url, _headers, HTTPClient.METHOD_POST, JSON.stringify(_change_password_body))


# User Profile handlers
func update_account(idToken : String, displayName : String, photoUrl : String, deleteAttribute : PackedStringArray, returnSecureToken : bool) -> void:
	if _is_ready():
		is_busy = true
		_update_profile_body.idToken = idToken
		_update_profile_body.displayName = displayName
		_update_profile_body.photoUrl = photoUrl
		_update_profile_body.deleteAttribute = deleteAttribute
		_update_profile_body.returnSecureToken = returnSecureToken
		request(_base_url + _update_account_request_url, _headers, HTTPClient.METHOD_POST, JSON.stringify(_update_profile_body))


# Function to send a account verification email
func send_account_verification_email() -> void:
	if _is_ready():
		is_busy = true
		_account_verification_body.idToken = auth.idtoken
		request(_base_url + _oobcode_request_url, _headers, HTTPClient.METHOD_POST, JSON.stringify(_account_verification_body))


# Function used to reset the password for a user who has forgotten in.
# This will send the users account an email with a password reset link
func send_password_reset_email(email : String) -> void:
	if _is_ready():
		is_busy = true
		_password_reset_body.email = email
		request(_base_url + _oobcode_request_url, _headers, HTTPClient.METHOD_POST, JSON.stringify(_password_reset_body))


# Function called to get all
func get_user_data() -> void:
	if _is_ready():
		is_busy = true
		if not is_logged_in():
			print_debug("Not logged in")
			is_busy = false
			return

		request(_base_url + _userdata_request_url, _headers, HTTPClient.METHOD_POST, JSON.stringify({"idToken":auth.idtoken}))


# Function used to delete the account of the currently authenticated user
func delete_user_account() -> void:
	if _is_ready():
		is_busy = true
		request(_base_url + _delete_account_request_url, _headers, HTTPClient.METHOD_POST, JSON.stringify({"idToken":auth.idtoken}))


# Function is called when a new token is issued to a user. The function will yield until the token has expired, and then request a new one.
func begin_refresh_countdown() -> void:
	var refresh_token = null
	var expires_in = 1000
	auth = get_clean_keys(auth)
	if auth.has("refreshtoken"):
		refresh_token = auth.refreshtoken
		expires_in = auth.expiresin
	elif auth.has("refresh_token"):
		refresh_token = auth.refresh_token
		expires_in = auth.expires_in
	if auth.has("userid"):
		auth["localid"] = auth.userid
	_needs_refresh = true
	emit_signal("token_refresh_succeeded", auth)
	await get_tree().create_timer(str(expires_in).to_float()).timeout
	_refresh_request_body.refresh_token = refresh_token
	request(_refresh_request_base_url + _refresh_request_url, _headers, HTTPClient.METHOD_POST, JSON.stringify(_refresh_request_body))


# This function is used to make all keys lowercase
# This is only used to cut down on processing errors from Firebase
# This is due to Google have inconsistencies in the API that we are trying to fix
func get_clean_keys(auth_result : Dictionary) -> Dictionary:
	var cleaned = {}
	for key in auth_result.keys():
		cleaned[key.replace("_", "").to_lower()] = auth_result[key]
	return cleaned


func cancel_login_request() -> void:
	is_busy = false
	cancel_request()
