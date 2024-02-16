@tool
## @meta-authors Kyle Szklenski
## @meta-version 2.5
## The Firebase Godot API.
## This singleton gives you access to your Firebase project and its capabilities. Using this requires you to fill out some Firebase configuration settings. It currently comes with four modules.
## 	- [code]Auth[/code]: Manages user authentication (logging and out, etc...)
## 	- [code]Database[/code]: A NonSQL realtime database for managing data in JSON structures.
## 	- [code]Firestore[/code]: Similar to Database, but stores data in collections and documents, among other things.
## 	- [code]Storage[/code]: Gives access to Cloud Storage; perfect for storing files like images and other assets.
##
## @tutorial https://github.com/GodotNuts/GodotFirebase/wiki
extends Node

const _ENVIRONMENT_VARIABLES : String = "firebase/environment_variables"
const _EMULATORS_PORTS : String = "firebase/emulators/ports"

## @type FirebaseAuth
## The Firebase Authentication API.
@onready var Auth : FirebaseAuth = $Auth

## @type FirebaseFirestore
## The Firebase Firestore API.
#@onready var Firestore = $Firestore

## @type FirebaseDatabase
## The Firebase Realtime Database API.
#@onready var Database : FirebaseDatabase = $Database

## @type FirebaseStorage
## The Firebase Storage API.
#@onready var Storage = $Storage

## @type FirebaseDynamicLinks
## The Firebase Dynamic Links API.
@onready var DynamicLinks : FirebaseDynamicLinks = $DynamicLinks

## @type FirebaseFunctions
## The Firebase Cloud Functions API
@onready var Functions : FirebaseFunctions = $Functions

@export var emulating : bool = false

# Configuration used by all files in this project
# These values can be found in your Firebase Project
# See the README on Github for how to access
var _config : Dictionary = {
	"apiKey": "",
	"authDomain": "",
	"databaseURL": "",
	"projectId": "",
	"storageBucket": "",
	"messagingSenderId": "",
	"appId": "",
	"measurementId": "",
	"clientId": "",
	"clientSecret" : "",
	"domainUriPrefix" : "",
	"functionsGeoZone" : "",
	"cacheLocation":"user://.firebase_cache",
	"workarounds":{
		"database_connection_closed_issue": false, # fixes https://github.com/firebase/firebase-tools/issues/3329
	}
}

func _ready() -> void:
	_load_config()


func set_emulated(emulating : bool = true) -> void:
	self.emulating = emulating
	_check_emulating()

func _check_emulating() -> void:
	if emulating:
		print("[Firebase] You are now in 'emulated' mode: the services you are using will try to connect to your local emulators, if available.")
	for module in get_children():
		if module.has_method("_check_emulating"):
			module._check_emulating()

func _load_config() -> void:
	if _config.apiKey != "" and _config.authDomain != "":
		pass
	else:
		for key in _config.keys():
			var value: Variant = ProjectSettings.get_setting('%s/%s' % [_ENVIRONMENT_VARIABLES, key])
			_config[key] = value

	_setup_modules()

func _setup_modules() -> void:
	for module in get_children():
		if not module.has_method('_set_config'):
			return
		module._set_config(_config)
		if not module.has_method("_on_FirebaseAuth_login_succeeded"):
			continue
		Auth.connect("login_succeeded", module._on_FirebaseAuth_login_succeeded)
		Auth.connect("signup_succeeded", module._on_FirebaseAuth_login_succeeded)
		Auth.connect("token_refresh_succeeded", module._on_FirebaseAuth_token_refresh_succeeded)
		Auth.connect("logged_out", module._on_FirebaseAuth_logout)


# -------------

func _printerr(error : String) -> void:
	printerr("[Firebase Error] >> "+error)

func _print(msg : String) -> void:
	print("[Firebase] >> "+msg)
