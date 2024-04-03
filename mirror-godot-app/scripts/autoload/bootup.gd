# Boot scene and bootup script are loaded and
# only executed when app is started.
class_name Game
extends Node

static var popups = []

func _start_client():
	DisplayServer.window_set_title(ProjectSettings.get_setting("application/config/window_name", "The Mirror"))
	Cursors.setup()
	if ProjectSettings.get_setting("feature_flags/disable_login", false):
		LoginService.setup_deeplink_login(get_tree())
	else:
		GameUI.login_ui.start_login_ui()
		GameUI.login_ui.show()
	Deeplinking.setup()
	await Zone.wait_till_notifications_ready()
	await Zone.wait_till_deeplink_ready()
	var notification_ui = Notify.get_notifications_ui()
	var is_closable = ProjectSettings.get_setting("mirror/critical_app_error/is_closable", true)


	Zone.client.join_server_start.connect(func():
		for popup in popups:
			if not is_instance_valid(popup):
				continue
			popup.hide()
			var parent = popup.get_parent()
			parent.remove_child(popup)
			popup.queue_free()
		popups.clear())

	print("------------------------- Checking for update -------------------------------")
	# make request for version from server
	Net.version_client.get_client_version()
	var version = await Net.version_client.version_received
	if ProjectSettings.get_setting("feature_flags/check_version_on_start") == true and version != Util.get_version_string():
		critical_error(Client.JOINER_ERRORS.VERSION_MISMATCH, "Your client is out of date, please update it to %s from %s" % [version, Util.get_version_string()] )
		return
	if ProjectSettings.get_setting("feature_flags/disable_login", false) and not Zone.client.is_client_connected_to_server():
		var title = ProjectSettings.get_setting("mirror/disable_login/notify/title",
			"Please open The Mirror web app"
		)
		var description = ProjectSettings.get_setting("mirror/disable_login/notify/description",
			"Please click this link below to open your browser \n[url]https://in.themirror.space/[/url]\n"
		)
		popups.append(notification_ui.notify(
			title, description,
			null, true, false
		))


static func critical_error(error: Client.JOINER_ERRORS, description) -> void:
	var contextual_errors = ProjectSettings.get_setting("feature_flags/show_error_solution", true)
	var error_solution = Zone.client.get_error_solution(error)
	var error_status: String = Client.JOINER_ERRORS.keys()[error]
	var error_name = error_status.replace("_", " ")
	var notification_ui = Notify.get_notifications_ui()

	var is_closable = ProjectSettings.get_setting("mirror/critical_app_error/is_closable", true)
	if contextual_errors:
		push_error("Criticial Error: ", error_name, ", ", description, " solution: ", error_solution)
		var popup = notification_ui.notify(
			str(error_name),
			description + "\n\n" + error_solution,
			null, true, is_closable
		)
		popups.append(popup)
		return

	var error_string = ProjectSettings.get_setting("mirror/critical_app_error/error_string", "")
	push_error("Critical Error: ", error_name, error_string)
	var popup = notification_ui.notify(
		str(error_name),
		description +
		(error_string % str(error_status) if error_string.contains("%s") else error_string),
		null, true, is_closable
	)
	popups.append(popup)


## This GLTF stuff can be anywhere as long as it runs when the game starts.
func _setup_gltf() -> void:
	var ext = GLTFDocumentExtensionMirrorModelPrimitive.new()
	GLTFDocument.register_gltf_document_extension(ext)
	ext = GLTFDocumentExtensionMirrorEquipable.new()
	GLTFDocument.register_gltf_document_extension(ext)
	ext = GLTFDocumentExtensionOMISeat.new()
	GLTFDocument.register_gltf_document_extension(ext)
	ext = GLTFDocumentExtensionOMISpawnPoint.new()
	GLTFDocument.register_gltf_document_extension(ext)
	ext = GLTFDocumentExtensionOMIPhysicsJoint.new()
	GLTFDocument.register_gltf_document_extension(ext)
	ext = GLTFDocumentExtensionOMIVehicle.new()
	GLTFDocument.register_gltf_document_extension(ext)
	ext = GLTFDocumentExtensionVRMNodeConstraint.new()
	GLTFDocument.register_gltf_document_extension(ext)


func _complete_bootup():
	Zone.bootup_completed = true
	Zone.completed_booting.emit()


func _ready() -> void:
	_setup_gltf()
	if await _auto_start_server():
		_complete_bootup()
		return
	_start_client()
	_complete_bootup()


func _auto_start_server() -> bool:
	if Util.is_host_commandline() or Util.is_headless_server():
		return await _start_server()
	return false


func _start_server() -> bool:
	await LoginService.server_login_if_required(get_tree())
	if Zone.start_server():
		DisplayServer.window_set_title("The Mirror Dedicated Server")
		_setup_server_window()
		Zone.change_to_space_scene()
		var properties = {}
		properties.cpu_info = OS.get_processor_name()
		properties.cpu_cores = OS.get_processor_count()
		Analytics.track_event(AnalyticsEvent.TYPE.SERVER_STARTUP, properties)
		return true
	return false


func _setup_server_window():
	var use_server_camera = ProjectSettings.get_setting("mirror/use_server_camera")
	if use_server_camera:
		DisplayServer.window_set_size(Vector2(400, 250))
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
		DisplayServer.window_set_size(Vector2(100, 60))
