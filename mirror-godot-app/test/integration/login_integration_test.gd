class_name LoginIntegrationTest
extends BaseIntegrationTest


## Logs into firebase with the integration account.
func login_firebase() -> void:
	if not Net.user_id.is_empty() and not Firebase.Auth.get_jwt().is_empty():
		test_passed("Already logged in to Firebase!")
		return
	var integration_test_user = ProjectSettings.get_setting("mirror/integration_test_acct")
	Firebase.Auth.login_failed.connect(_on_firebase_login_failed)
	Firebase.Auth.login_succeeded.connect(_on_firebase_login_succeeded, CONNECT_ONE_SHOT)
	Firebase.Auth.login_with_email_and_password(integration_test_user["email"], integration_test_user["password"])


## Called when firebase login succeeds.
func _on_firebase_login_succeeded(auth_result: Dictionary) -> void:
	Firebase.Auth.login_failed.disconnect(_on_firebase_login_failed)
	Net.login_success(auth_result["localid"], auth_result["idtoken"])
	test_passed(auth_result["localid"])


## Called when firebase login fails.
func _on_firebase_login_failed(_code: int, _message: String) -> void:
	Firebase.Auth.login_failed.disconnect(_on_firebase_login_failed)
	Firebase.Auth.login_succeeded.disconnect(_on_firebase_login_succeeded)
