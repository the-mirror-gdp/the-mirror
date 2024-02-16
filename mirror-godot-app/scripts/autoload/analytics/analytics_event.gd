class_name AnalyticsEvent
extends Resource


# The name of the event you want to record
@export var event_name: String
# The user's ID
@export var user_id: String
# Screen the user is on
@export var screen: String
# The properties to record
@export var properties: Dictionary

# Optional timestamp; if not supplied, it is supplied by the server
@export var timestamp: String

# This is an enum, but we want it to use strings and not integers
# TODO needs analytics.gd implementation
class SCREEN:
	const LOGIN = "LOGIN"
	const MAIN_MENU = "MAIN_MENU"


# This is an enum, but we want it to use strings and not integers
class TYPE:
	# Session heartbeat
	const SESSION_HEARTBEAT = "GDC_SESSION_HEARTBEAT"
	const GAME_SERVER_HEARTBEAT = "GAME_SERVER_HEARTBEAT"
	# Login
	const LOGIN_UI_READY = "GDC_LOGIN_UI_READY"
	const LOGIN_USER_SUCCESS = "GDC_LOGIN_USER_SUCCESS"
	const LOGIN_USER_FAIL = "GDC_LOGIN_USER_FAIL"
	const LOGIN_GOOGLE_PRESSED = "GDC_LOGIN_GOOGLE_PRESSED"
	const LOGIN_FACEBOOK_PRESSED = "GDC_LOGIN_FACEBOOK_PRESSED"
	const LOGIN_DISCORD_PRESSED = "GDC_LOGIN_DISCORD_PRESSED"
	const LOGIN_UI_SIGN_IN_PRESSED = "GDC_LOGIN_UI_SIGN_IN_PRESSED"
	const LOGIN_UI_CANCEL_BUTTON_PRESSED = "GDC_LOGIN_UI_CANCEL_BUTTON_PRESSED"
	## Redirect to any of our in.themirror.space/
	## The specific url will be part of the event properties as *_url
	const LOGIN_UI_SIGN_UP_HERE_PRESSED = "GDC_LOGIN_UI_SIGN_UP_HERE_PRESSED"
	const LOGIN_UI_FORGOT_PASSWORD_PRESSED = "GDC_LOGIN_UI_FORGOT_PASSWORD_PRESSED"
	const LOGOUT_SUCCESS = "GDC_LOGOUT_SUCCESS"

	# Main Menu
	const MAIN_MENU_UI_READY = "GDC_MAIN_MENU_UI_READY"
	const MAIN_MENU_PAGE_CHANGE = "GDC_MAIN_MENU_PAGE_CHANGE"
	const MAIN_MENU_SUBPAGE_CHANGE = "GDC_MAIN_MENU_SUBPAGE_CHANGE"
	const MAIN_MENU_WINDOW_MINIMIZE_PRESSED = "GDC_MAIN_MENU_WINDOW_MINIMIZE_PRESSED"
	const MAIN_MENU_WINDOW_CLOSE_PRESSED = "GDC_MAIN_MENU_WINDOW_CLOSE_PRESSED"

	# Joining a space
	const SPACE_JOIN_ATTEMPT = "GDC_SPACE_JOIN_ATTEMPT"
	const SPACE_JOIN_ATTEMPT_FAIL = "GDC_SPACE_JOIN_ATTEMPT_FAIL"
	const SPACE_JOIN_ATTEMPT_SUCCESS = "GDC_SPACE_JOIN_ATTEMPT_SUCCESS"

	# CPU info
	const CLIENT_STARTUP = "GDC_CLIENT_STARTUP" # has GPU / CPU info
	const SERVER_STARTUP = "GDC_SERVER_STARTUP" # has CPU info

	# Gameplay
	const OBJECT_PLACED = "GDC_OBJECT_PLACED"
	const UPLOAD_ASSET = "GDC_UPLOAD_ASSET"
	const MODIFY_SPACE_OBJECT_PROPERTY = "GDC_MODIFY_SPACE_OBJECT_PROPERTY"
	const SEARCH_ASSET = "GDC_SEARCH_ASSET"
	const PREVIEW_MODE_START = "GDC_PREVIEW_MODE_CLICKED"
	const PREVIEW_MODE_ENTERED = "GDC_PREVIEW_ENTERED"
	const PREVIEW_MODE_EXITED = "GDC_PREVIEW_EXITED"
	const SPACE_PUBLISHED = "GDC_SPACE_PUBLISHED"
	const SPACE_UNPUBLISHED = "GDC_SPACE_UNPUBLISHED"

