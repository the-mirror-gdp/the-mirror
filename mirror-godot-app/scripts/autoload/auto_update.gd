extends Node

const LOCAL_UPDATE_DIRECTORY = "user://auto_updater/"
const LOCAL_UPDATE_TEMP_DIRECTORY = "user://auto_updater/temp"

signal report_progress(progress: float, status: String)
signal game_ready()

var _last_bytes: int = 0
var _http_request: HTTPRequest
var _getting_binary: bool = false
var _server_version: String = ""
var _new_binary_name: String = ""
var _download_total_size: int = -1


func get_post_update() -> bool:
	return OS.get_cmdline_args().has("--post-update")


func setup() -> void:
	# if _is_editor_bypass():
	print("Disabled auto-updater - this is not a standalone binary")
	game_ready.emit()
	return

	if Util.current_platform_is_windows() and _win32_executable_procedure():
		print("---- auto updater - finished _win32_executable_procedure -----")
		return

	if get_post_update():
		print("----- auto updater blocked - app was just updated ------")
		print("Server version: ", _server_version)
		print("Current version: ", Util.get_version_string())
		game_ready.emit()
		return

	print("------------------------- Started auto updater -------------------------------")
	report_progress.emit(0, "Checking for update")
	# make request for version from server
	Net.version_client.request_errored.connect(_on_version_request_errored, CONNECT_ONE_SHOT)
	Net.version_client.version_received.connect(_on_version_received, CONNECT_ONE_SHOT)
	Net.version_client.get_client_version()


func _is_editor_bypass() -> bool:
	return OS.has_feature("editor")


func _process(_delta: float) -> void:
	_process_http_progress()


func _process_http_progress() -> void:
	if not _http_request or not _getting_binary:
		return
	var bytes_dl: int = _http_request.get_downloaded_bytes()
	if bytes_dl == _last_bytes or bytes_dl <= 0:
		return
	print(" downloaded: ", bytes_dl)
	_last_bytes = bytes_dl
	if _download_total_size == -1:
		push_error("Can't get body size")
		_download_total_size = _http_request.get_body_size()
		return
	var percent: float = float(bytes_dl) / float(_download_total_size) * 100.0
	print("Percent: ", percent, " bytes_dl:" , bytes_dl, " download total size: ", _download_total_size )
	report_progress.emit(percent, "Downloading update")


func _get_version_failed() -> void:
	print("Failed to update game client.")
	report_progress.emit(100, "Failed to check for update")
	_getting_binary = false
	game_ready.emit() # we should resume normal game and not block client


func _on_version_request_errored(_request: Dictionary) -> void:
	if Net.version_client.version_received.is_connected(_on_version_received):
		Net.version_client.version_received.disconnect(_on_version_received)
	if Net.version_client.version_manifest_received.is_connected(_on_version_manifest_received):
		Net.version_client.version_manifest_received.disconnect(_on_version_manifest_received)
	if Net.version_client.version_payload_received.is_connected(_on_version_payload_received):
		Net.version_client.version_manifest_received.disconnect(_on_version_payload_received)
	_get_version_failed()


func _on_version_received(version: String) -> void:
	_server_version = version
	if _server_version.is_empty():
		_get_version_failed()
		return
	var current_version_str = Util.get_version_string()
	print("Server Version: ", _server_version, "\tCurrent Version: ", current_version_str)
	if version == current_version_str:
		print("No updates")
		report_progress.emit(100, "No updates")
		game_ready.emit() # game is up to date
		return
	Net.version_client.version_manifest_received.connect(_on_version_manifest_received, CONNECT_ONE_SHOT)
	Net.version_client.get_version_manifest(version)


func _on_version_manifest_received(manifest: Dictionary) -> void:
	if not manifest.has_all(["packed_md5_hash", "file_download_size", "executable_name"]):
		_get_version_failed()
		return
	var version: String = manifest.get("version", "")
	var download_hash: String = manifest.get("packed_md5_hash", "")
	print("Valid download information found: ", manifest)
	report_progress.emit(0, "Downloading update")
	_download_total_size = int(manifest.get("file_download_size", 0))
	_new_binary_name = str(manifest.get("executable_name", ""))
	_try_create_update_directory()
	print("Download of file requested")
	_getting_binary = true
	var temporary_binary_filepath: String = "%s%s.tar.gz" % [LOCAL_UPDATE_DIRECTORY, Util.get_current_platform_name()]
	Net.version_client.version_payload_received.connect(_on_version_payload_received, CONNECT_ONE_SHOT)
	_http_request = Net.version_client.get_version_payload(version, download_hash, temporary_binary_filepath)


func _on_version_payload_received(_payload: PackedByteArray, expected_hash: String) -> void:
	var platform_name = Util.get_current_platform_name()
	var local_file_path: String = "%s%s.tar.gz" % [LOCAL_UPDATE_DIRECTORY, platform_name]
	print("File download result ready to be used: ", local_file_path, "\nWe expect the hash ", expected_hash)
	_getting_binary = false
	report_progress.emit(100, "Completed download... please wait - validating")
	if not Util.compare_hash(local_file_path, expected_hash):
		print("Invalid hash detected - file may be corrupt - redownload should be requested")
		_get_version_failed()
		return
	print("Hash matched the file")
	_extract_and_relaunch()


func _win32_executable_procedure() -> bool:
	# Purely optimisation
	if not OS.get_cmdline_args().has("--win32-remove-old-executable") and not OS.get_cmdline_args().has("--copy-executable"):
		print("exited win32_exec_proc due to no args to invoke it")
		return false

	print("Win32 executable procedure")

	var remove_path = Util.get_commandline_id_val("win32-remove-old-executable")
	if remove_path != "":
		print("Removing old executable at path: ", remove_path)
		DirAccess.remove_absolute(remove_path)
		return true

	# wont copy if the path is empty (i.e. if its disabled)
	return _win32_copy_and_run_executable(Util.get_commandline_id_val("copy-executable"))


func _win32_copy_and_run_executable(new_binary_path: String) -> bool:
	if new_binary_path.is_empty():
		print("Invalid path supplied to executable cannot be empty")
		push_error("Invalid path supplied to executable cannot be empty")
		return false
	var current_binary_path = Util.get_current_executable_path()
	print("Copying executable from ", current_binary_path, " to ", new_binary_path)
	# copy current executable to the original folder
	var err = DirAccess.copy_absolute(current_binary_path, new_binary_path)
	if err == OK:
		var args = OS.get_cmdline_args()
		args.append("--post-update")
		var pid = OS.create_process(new_binary_path, args)
		if pid == -1:
			print("_win32_copy_and_run_executable, Failed to create game instance for executable: ", new_binary_path)
			push_error("_win32_copy_and_run_executable, Failed to create game instance for executable: ", new_binary_path)
			return false
		print("Successfully ran new executable - this process will now close")
		get_tree().quit(0)
		return true
	print("failed to copy absolute executable win32 [critical error]")
	push_error("failed to copy absolute executable win32 [critical error]")
	return false


# windows can't unlink executables so requires code to use a temp directory and then copy back to the OG location.
func _win32_execute_and_move(temp_binary_path: String, new_binary_path: String) -> bool:
	print("Begin windows execute and move...")
	var args = OS.get_cmdline_args()
	var platform_executable = temp_binary_path
	# we don't do GUI in the copy phase
	args.append("--headless")
	# we execute a copy of the binary and open it in the correct location
	args.append("--copy-executable")
	args.append(new_binary_path)

	var pid = OS.create_process(platform_executable, args)
	if pid == -1:
		# TODO revert executable
		push_error("Failed to create game instance for executable: ", platform_executable)
		print("Failed to create game instance for executable: ", platform_executable)
		return false
	return true


func _extract_download_windows(local_file_path: String) -> bool:
	var output = []
	var global_path = ProjectSettings.globalize_path(local_file_path)
	#var _executable_name = OS.get_executable_path().get_file()
	var original_executable_fullpath = OS.get_executable_path()
	var original_executable_filename = original_executable_fullpath.get_file()
	var windows_temp_folder = ProjectSettings.globalize_path(LOCAL_UPDATE_TEMP_DIRECTORY)
	# Extract the game to the temp folder first and run it.
	if not DirAccess.dir_exists_absolute(windows_temp_folder):
		print("Created folder for the temp executable")
		DirAccess.make_dir_absolute(windows_temp_folder)

	print("running tar extraction 2.0")
	print("tar -xf ", global_path, " -C ", windows_temp_folder )
	var err = OS.execute("tar", ["-xf", global_path, "-C", windows_temp_folder], output, true)
	if err != OK:
		print("Failed to extract tar archive error: ", err, ", output: ", output)
		return false
	var executable_directory = original_executable_fullpath.get_base_dir()
	var new_binary_path = "%s/%s" % [executable_directory, _new_binary_name]
	var temporary_binary_path = "%s/%s" % [windows_temp_folder, _new_binary_name]
	print("Attempting to execute and move the executable: ", temporary_binary_path, ". destination: " + new_binary_path)
	return _win32_execute_and_move(temporary_binary_path, new_binary_path)


func _extract_download_unix(temporary_binary_filepath: String, cached_executable_path: String) -> bool:
	var output = []
	var global_path = ProjectSettings.globalize_path(temporary_binary_filepath)
	print("tar -xf ", global_path, " --overwrite -C %s" % cached_executable_path.get_base_dir())
	# overwrite, we must unlink too! executables can't be copied otherwise
	var err = OS.execute("tar", ["-xf", global_path, "--unlink-first", "-C", cached_executable_path.get_base_dir()], output, true)
	if err:
		print("Failed to extract tar archive error: ", err, ", output: ", output)
	return err == OK


func _extract_download(temporary_binary_filepath: String, cached_executable_path: String) -> bool:
	if Util.current_platform_is_windows():
		return _extract_download_windows(temporary_binary_filepath)
	return _extract_download_unix(temporary_binary_filepath, cached_executable_path)


func _extract_and_relaunch() -> void:
	report_progress.emit(100, "Extracting game update")
	_getting_binary = false
	var temporary_binary_filepath: String = "%s%s.tar.gz" % [LOCAL_UPDATE_DIRECTORY, Util.get_current_platform_name()]
	var os_cached_executable_path = OS.get_executable_path()
	var cached_executable_path = Util.get_current_executable_path()
	var did_extract_file = _extract_download(temporary_binary_filepath, cached_executable_path)
	if not did_extract_file:
		push_error("Failed to extract game client update")
		print("Failed to update game")
		## TODO REVERT
		_get_version_failed()
		return
	# Relaunch the game on unix. Game will already be executed automatically on win32.
	if not Util.current_platform_is_windows():
		var args = OS.get_cmdline_args()
		var platform_executable = cached_executable_path
		args.append("--post-update")
		if Util.current_platform_is_mac():
			platform_executable = os_cached_executable_path
		var pid = OS.create_process(platform_executable, args)
		if pid == -1:
			# TODO revert executable
			print("Failed to create game instance for executable: ", platform_executable)
			push_error("Failed to create game instance for executable: ", platform_executable)
	report_progress.emit(100, "Rebooting game")
	print("===== Rebooting game =====")
	get_tree().quit(0)


func _try_create_update_directory() -> void:
	if not DirAccess.open(LOCAL_UPDATE_DIRECTORY):
		DirAccess.make_dir_absolute(LOCAL_UPDATE_DIRECTORY)
