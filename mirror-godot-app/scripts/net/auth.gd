class_name MirrorAuth
extends MirrorHttpClient

enum {
	POST_AUTH_USER_CREATE,
	POST_CHECK_LOGIN_CODE
}


func create_account_if_missing() -> Promise:
	return self.post_request(POST_AUTH_USER_CREATE, "/auth/auth-user-create", {})


func check_login_code(login_code: String) -> Promise:
	return self.post_request(
		POST_CHECK_LOGIN_CODE,
		"/login-code/check-login-code?loginCode=" + login_code,
		{}
	)


func _promise_fulfill_successful(request: Dictionary, promise: Promise) -> void:
	var parsed_result = request.get("json_result")
	if parsed_result == null:
		push_error("MirrorAuth request succeeded but parsed result is null. %s" % str(request))
		promise.set_error("MirrorAuth request succeeded but parsed result is null. %s" % str(request))
		return
	promise.set_result(parsed_result)
