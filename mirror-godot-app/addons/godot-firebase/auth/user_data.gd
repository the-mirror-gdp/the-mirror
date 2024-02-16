@tool
## @meta-authors TODO
## @meta-version 2.3
## Authentication user data.
## Documentation TODO.

class_name FirebaseUserData extends RefCounted

var local_id : String = ""           # The uid of the current user.
var email : String = ""
var email_verified  # Whether or not the account's email has been verified.
var password_updated_at : float = 0  # The timestamp, in milliseconds, that the account password was last changed.
var last_login_at : float = 0        # The timestamp, in milliseconds, that the account last logged in at.
var created_at : float = 0           # The timestamp, in milliseconds, that the account was created at.
var provider_user_info : Array = []

var provider_id : String = ""
var display_name : String = ""
var photo_url : String = ""

func _init(p_userdata : Dictionary):
	local_id = p_userdata.get("localId", "")
	email = p_userdata.get("email", "")
	email_verified = p_userdata.get("emailVerified", false)
	last_login_at = p_userdata.get("lastLoginAt", 0).to_float()
	created_at = p_userdata.get("createdAt", 0).to_float()
	password_updated_at = p_userdata.get("passwordUpdatedAt", 0)
	display_name = p_userdata.get("displayName", "")
	provider_user_info = p_userdata.get("providerUserInfo", [])
	if not provider_user_info.is_empty():
		provider_id = provider_user_info[0].get("providerId", "")
		photo_url = provider_user_info[0].get("photoUrl", "")
		display_name = provider_user_info[0].get("displayName", "")

func as_text() -> String:
	return _to_string()

func _to_string() -> String:
	var txt = "local_id : %s\n" % local_id
	txt += "email : %s\n" % email
	txt += "last_login_at : %d\n" % last_login_at
	txt += "provider_id : %s\n" % provider_id
	txt += "display name : %s\n" % display_name
	return txt

func _to_dictionary() -> Dictionary:
	var dict = Dictionary()
	dict['local_id'] = local_id
	dict['email'] = email
	dict['email_verified'] = email_verified
	dict['last_login_at'] = last_login_at
	dict['created_at'] = created_at
	dict['password_updated_at'] = password_updated_at
	dict['display_name'] = display_name
	dict['provider_user_info'] = provider_user_info
	dict['photo_url'] = photo_url
	return dict
