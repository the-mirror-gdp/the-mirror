# URL handler - App Protocol
# Deeplinking
extends Node


signal join_zone_requested(zone_id: String)
signal join_space_requested(space_id: String)
signal join_beta_requested()
signal join_as_guest(space_id: String)
signal join_authed_space(access_token: String, refresh_token: String, space_id: String)

const _JOIN_ZONE_CMD: String = "zone"
const _JOIN_AS_GUEST: String = "guest"
const _JOIN_SPACE_CMD: String = "space"
const _JOIN_AUTHED_SPACE_CMD: String = "join-session"
const _HARDCODED_BETA_KEY: String = "beta"

var _cached_deeplinks = []
var _deeplink_thread: Thread
var _deeplink_mutex: Mutex
var _deeplink_exit_mutex: Mutex
var _deeplink_thread_exit: bool = false


func _process(_delta: float) -> void:
	if _cached_deeplinks.size() == 0:
		return
	for deeplink in _cached_deeplinks:
		var url = String(deeplink) # ensure to deep copy string from thread data
		print("Processing deeplink: ", url)
		get_window().request_attention()
		# neither of these work for making the app focus the window to the top on the OS
		#get_window().grab_focus()
		#get_window().move_to_foreground()
		var url_data: Variant = _extract_command(url)
		if url_data and url_data is Dictionary:
			var command = url_data.command
			# NOTE: they're deliberately left as a string as encoding might be added later
			# but we're not adding an array type here for now
			var args: Array = url_data.args
			if not Net.is_logged_in() and command != _JOIN_AUTHED_SPACE_CMD:
				Notify.warning("Sign In", "You must sign in to use the link provided, once you sign in I will open the link.")
				GameUI.login_ui.login_succeeded.connect(func(): _handle_deeplink_url(url), CONNECT_ONE_SHOT)
			else:
				_process_command(command, args)
	_deeplink_mutex.lock()
	_cached_deeplinks.clear()
	_deeplink_mutex.unlock()


func setup():
	AppProtocol.start_protocol_handling()
	AppProtocol.on_url_received.connect(_handle_deeplink_url)
	_deeplink_thread = Thread.new()
	_deeplink_mutex = Mutex.new()
	_deeplink_exit_mutex = Mutex.new()
	_deeplink_thread.start(_thread_update)
	print_verbose("Deeplinking has been enabled")
	# this value only happens if we launch with a deeplink argument on booting the client
	# the rest is passed over IPCClient and IPCServer in AppProtocol in godot-soft-fork
	var deeplink_command = Util.get_commandline_id_val("uri")
	if not deeplink_command.is_empty():
		print_verbose("deeplink_value: ", deeplink_command)
		_handle_deeplink_url(deeplink_command)

	Zone.deeplinking_started.emit()
	Zone.deeplink_ready = true


func has_join_command_with_auth():
	return Util.get_commandline_id_val("uri").contains(_JOIN_AUTHED_SPACE_CMD)


func _thread_update() -> void:
	while true:
		_deeplink_exit_mutex.lock()
		if _deeplink_thread_exit:
			break
		_deeplink_exit_mutex.unlock()
		# print("Deeplink update time: ", Time.get_unix_time_from_system())
		AppProtocol.poll_server()
		OS.delay_msec(5) # we delay the poll on the thread so that it will never max a core on our system


func _exit_tree():
	# thread was never started
	if _deeplink_exit_mutex == null:
		return
	_deeplink_exit_mutex.lock()
	_deeplink_thread_exit = true
	_deeplink_exit_mutex.unlock()
	_deeplink_thread.wait_to_finish()


func _extract_command(url: String) -> Variant:
# split themirror and the <command> section.
	var split_hostname = url.split("//")
	if split_hostname.size() != 2:
		printerr("URL was empty so doing nothing")
		return
	# We are using the format for now
	# themirror://<command>/<id>
	var split_commands = split_hostname[1].trim_suffix("/").split("/")
	if split_commands.size() >= 2:
		var command: String = split_commands[0]
		var args = split_commands.slice(1, split_commands.size())
		return {"command": command, "args": args}
	else:
		push_error("Failed to get command in correct format")
		push_error("split_commands", split_commands)
		return null


# threaded so that the URL is always processed in most cases
# future: we may add an increased delay to startup to ensure message from IPC comes to the client
# this would solve link spamming opening some clients
func _handle_deeplink_url(url: String) -> void:
	_deeplink_mutex.lock()
	# print("Adding deeplink to thread data stack: ", url)
	_cached_deeplinks.push_back(url)
	_deeplink_mutex.unlock()


func _process_command(command: String, args: Array) -> void:
	print_verbose("Processing command: ", command, " args: ", args)
	match command:
		_JOIN_ZONE_CMD: join_zone_requested.emit(args[0])
		_JOIN_SPACE_CMD: join_space_requested.emit(args[0])
		_JOIN_AS_GUEST: join_as_guest.emit(args[0])
		_JOIN_AUTHED_SPACE_CMD:
			if args.size() != 3:
				printerr("invalid argument count: ", args.size())
				push_error("Deeplink doesn't contain the correct info")
				return
			var access_token: String = args[0]
			var refresh_token: String = args[1]
			var space_id: String = args[2]
			print_verbose("access token: ", access_token)
			print_verbose("refresh token: ", refresh_token)
			print_verbose("space id: ", space_id)
			join_authed_space.emit(access_token, refresh_token, space_id)
		_: Notify.error("Invalid link", "Command is not registered in this version of the application")
