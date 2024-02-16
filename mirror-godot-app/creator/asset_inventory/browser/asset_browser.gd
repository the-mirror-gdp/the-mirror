class_name AssetBrowser
extends Control


signal selected_asset_slot_changed(asset_slot: AssetSlot, request_placing: bool)
signal request_show_asset_details_editor(asset_slot: AssetSlot)
signal request_edit_script_instance(script_instance: ScriptInstance)
signal request_script_asset_edit(asset_data: AssetData)

const _MAX_FILE_SIZE = 15 << 20 # 15 MiB

var _object_creation: Control = null
var _script_editor: Control = null
var _selected_slot: BaseAssetSlot
var _auto_deselect_on_drag_end: bool = false
var _is_setup: bool = false
var _last_upload_directory: String = ""

@onready var _viewport: Viewport = get_viewport()
@onready var _file_search: FileDialog:
	get:
		return GameUI.file_search

@onready var _sections := $VBoxContainer/Sections
@onready var _recents := _sections.get_node(^"Recents")
@onready var _upload_asset: Control = $VBoxContainer/UploadAsset
@onready var _show_upload_asset_button: CheckButton = $VBoxContainer/TopButtons/HBoxContainer/ShowUploadAssetButton

@onready var _details_container: Control = $VBoxContainer/Details
@onready var _details_name_label: Label = _details_container.get_node(^"AssetName")

@onready var _pck_uploads_enabled = ProjectSettings.get_setting("feature_flags/support_pck_uploads", false)


var _is_browser_expanded: bool = false:
	set(new_value):
		_is_browser_expanded = new_value
		get_viewport().gui_release_focus()


func setup(object_creation: Control, script_editor: Control) -> void:
	_object_creation = object_creation
	_script_editor = script_editor


func _ready() -> void:
	visibility_changed.connect(_on_visibility_changed)
	_viewport.files_dropped.connect(_on_files_dropped)
	_sections.setup(self)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		Cursors.set_cursor()
		if _auto_deselect_on_drag_end and _selected_slot and not _viewport.gui_is_dragging():
			_auto_deselect_on_drag_end = false
			if _selected_slot.asset_id == _object_creation.get_selected_asset_id():
				return
			_selected_slot.set_selected(false)
			_selected_slot = null


func _unhandled_input(input_event: InputEvent) -> void:
	if _is_browser_expanded and input_event.is_action_pressed(&"asset_upload"):
		_show_asset_upload_dialog()


func _on_show_upload_asset_button_toggled(button_pressed: bool) -> void:
	if button_pressed:
		_on_show_upload_asset_button_pressed()
	else:
		_on_cancel_upload_asset_pressed()


func _on_show_upload_asset_button_pressed() -> void:
#	_show_upload_asset_button.set_pressed_no_signal(true)
	_upload_asset.visible = true


func _on_cancel_upload_asset_pressed() -> void:
#	_show_upload_asset_button.set_pressed_no_signal(false)
	_show_upload_asset_button.set_pressed_no_signal(false)
	_upload_asset.visible = false


func _on_visibility_changed() -> void:
	if visible:
		setup_browser()


func get_selected_slot() -> Control:
	if not is_instance_valid(_selected_slot):
		return null
	return _selected_slot


func setup_browser() -> void:
	if _is_setup:
		return
	_is_setup = true
	# Need to wait a bit for the Control node size to propagate downwards.
	await get_tree().process_frame
	await get_tree().process_frame
	_sections.expand_first_section()


func set_selected_slot(slot: BaseAssetSlot, select_asset_id: bool = true) -> void:
	if slot != _selected_slot:
		if is_instance_valid(_selected_slot):
			_selected_slot.set_selected(false)
		if slot:
			slot.set_selected(true)
		_selected_slot = slot
	selected_asset_slot_changed.emit(slot, select_asset_id)
	if not select_asset_id:
		request_show_asset_details_editor.emit(slot)
	_set_details_container(slot)
	_auto_deselect_on_drag_end = not select_asset_id
	if select_asset_id and slot and slot is AssetSlot:
			_object_creation.set_selected_asset_id(slot.asset_id)
			var asset_data: AssetData = slot.asset_data
			_recents.track_recently_used_asset(asset_data)
			if asset_data.type == Enums.ASSET_TYPE.SCRIPT:
				request_script_asset_edit.emit(asset_data)
	else:
		_object_creation.set_selected_asset_id("")


func edit_slot_asset(slot: AssetSlot, select_asset: bool = false) -> void:
	# Selecting an asset without placement will show the asset details editor.
	set_selected_slot(slot, select_asset)
	var asset_data: AssetData = slot.asset_data
	# When selecting a script asset, ensure the script editor
	# is not opened to a different script asset.
	if asset_data.type == Enums.ASSET_TYPE.SCRIPT:
		if not _script_editor.is_editing_script_id(asset_data.asset_id):
			request_script_asset_edit.emit(null)


func edit_slot_script_asset(slot: AssetSlot) -> void:
	set_selected_slot(slot, true)
	var asset_data: AssetData = slot.asset_data
	assert(asset_data.type == Enums.ASSET_TYPE.SCRIPT)
	request_script_asset_edit.emit(asset_data)


func use_slot_asset(slot: AssetSlot) -> void:
	var asset_data: AssetData = slot.asset_data
	match asset_data.type:
		Enums.ASSET_TYPE.MAP:
			Zone.Scene.update_heightmap(asset_data)
		Enums.ASSET_TYPE.SCRIPT:
			request_script_asset_edit.emit(asset_data)
		_:
			return
	request_show_asset_details_editor.emit(null)


func asset_slot_activated(asset_slot: BaseAssetSlot, select_asset_id: bool) -> void:
	if asset_slot is AssetSlot:
		edit_slot_asset(asset_slot, select_asset_id)


func track_recently_used_space_script(script_instance: ScriptInstance) -> void:
	if script_instance.is_script_asset:
		return
	_recents.track_recently_used_space_script(script_instance)


func _set_details_container(slot: BaseAssetSlot) -> void:
	_details_name_label.text = slot.get_asset_name() if slot else ""


func set_selected_asset_id(asset_id: String) -> void:
	if asset_id.is_empty():
		Cursors.set_cursor()
	if _selected_slot:
		if _selected_slot is AssetSlot:
			if _selected_slot.asset_id == asset_id:
				return
		_selected_slot.set_selected(false)
		_selected_slot = null
		_set_details_container(null)


func _on_script_editor_editing_script_instance(script_instance: ScriptInstance) -> void:
	if is_instance_valid(_selected_slot):
		if _selected_slot is AssetSlot:
			var asset_data: AssetData = _selected_slot.asset_data
			if asset_data.type == Enums.ASSET_TYPE.SCRIPT:
				set_selected_slot(null)
		elif _selected_slot is RecentScriptEntitySlot:
			if _selected_slot.recent_script_instance != script_instance:
				set_selected_slot(null)


func _show_asset_upload_dialog() -> void:
	var supported_formats: PackedStringArray = ["*.glb, *.gltf, *.pck, *.obj, *.wav, *.png, *.jpg, *.jpeg, *.webp, *.exr, *.mp3; Supported Files"]
	if not _file_search.file_selected.is_connected(_on_file_search_file_selected):
		_file_search.file_selected.connect(_on_file_search_file_selected)
	_file_search.filters = supported_formats
	# Workaround for button layout in the FileDialog
	await get_tree().process_frame
	# Show the _file_search
	_file_search.popup_centered()

	if _last_upload_directory.is_empty():
		_file_search.current_dir = OS.get_user_data_dir()
		_file_search.current_path = OS.get_user_data_dir() + "/Asset/"
	else:
		_file_search.current_dir = _last_upload_directory
		_file_search.current_path = "%s/" % _last_upload_directory


func on_asset_deleted(reset_sections: bool = true) -> void:
	_selected_slot = null
	selected_asset_slot_changed.emit(null, false)
	if reset_sections:
		_sections.reset_sections()


func set_expanded(value: bool) -> void:
	# Calls its setter and emit change signal:
	_is_browser_expanded = value


func _on_file_search_file_selected(path: String) -> void:
	create_asset_from_url(path)


func _on_files_dropped(paths: PackedStringArray) -> void:
	if paths.size() > 1:
		Notify.error("File Upload Error", "Cannot upload multiple files at this time.")
		return
	create_asset_from_url(paths[0])


func create_asset_from_url(path: String, forced_type: String = "", asset_data_ext: Dictionary = {}) -> Promise:
	_last_upload_directory = path.get_base_dir()
	var res_promise = Promise.new()
	var file = FileAccess.open(path, FileAccess.READ)
	var file_size = file.get_length()
	file = null
	if file_size >= _MAX_FILE_SIZE:
		Notify.error("File Upload Error", "Cannot upload file with a size greater than 15 MiB")
		res_promise.set_error("Cannot upload file with a size greater than 15 MiB")
		return res_promise

	var file_name: String = path.get_file()
	var file_ext: String = file_name.get_extension()
	var asset_name: String = file_name.replace(".%s" % file_ext, "")
	if asset_name.is_empty():
		asset_name = "New Asset"
	asset_name = "%s (%s)" % [asset_name, file_ext.to_upper()]

	var asset_type = ""
	if not forced_type.is_empty():
		asset_type = forced_type
	elif Util.path_is_model(file_name):
		asset_type = Enums.ASSET_TYPE.MESH
	elif Util.path_is_audio(file_name):
		asset_type = Enums.ASSET_TYPE.AUDIO
	elif Util.path_is_image(file_name):
		asset_type = Enums.ASSET_TYPE.IMAGE
	elif Util.path_is_scene(file_name) and _pck_uploads_enabled:
		# TODO: Add support for diferent PCK types not compatible with meshes
		#   Might need to add pre-processing of the file to grab the type of the root node
		asset_type = Enums.ASSET_TYPE.MESH
	else:
		print("Invalid file selected")
		res_promise.set_error("Invalid file selected")
		return res_promise

	var asset_data_req: Dictionary = {
		"name": asset_name,
		"assetType": asset_type,
	}
	asset_data_req.merge(asset_data_ext)
	Analytics.track_event_client(AnalyticsEvent.TYPE.UPLOAD_ASSET)
	var promise = Net.asset_client.create_asset(asset_data_req)
	var asset_data  = await promise.wait_till_fulfilled()
	if promise.is_error():
		Notify.error("Failed To Create Asset", promise.get_error_message())
		res_promise.set_error(promise.get_error_message())
		return res_promise
	_sections.reset_sections()
	var mime_type: String = ""
	var file_data: PackedByteArray
	match file_ext:
		"gltf":
			mime_type = "model/gltf-binary"
			file_data = TMFileUtil.convert_gltf_files_to_glb_data(path)
		"glb":
			mime_type = "model/gltf-binary"
			file_data = TMFileUtil.load_file_bytes(path)
		"pck":
			mime_type = "application/scene-binary"
			var unpack_result = ScenePacker.get_unpacked_pck_as_node(path)
			if not is_instance_valid(unpack_result):
				printerr("AssetBrowser: cannot send: ", path, " file seems to be corrupted")
				res_promise.set_error("%s file seems to be corrupted" % path)
				return res_promise
			unpack_result.queue_free()
			file_data = TMFileUtil.load_file_bytes(path)
		"webp":
			mime_type = "image/webp"
			file_data = TMFileUtil.get_webp_data_at_path(path)
		"png":
			mime_type = "image/webp"
			file_data = TMFileUtil.get_webp_data_at_path(path)
		"jpg":
			mime_type = "image/webp"
			file_data = TMFileUtil.get_webp_data_at_path(path)
		"jpeg":
			mime_type = "image/webp"
			file_data = TMFileUtil.get_webp_data_at_path(path)
		"exr":
			mime_type = "image/x-exr"
			file_data = TMFileUtil.get_exr_data_at_path(path)
		"obj":
			mime_type = "model/gltf-binary"
			file_data = Util.convert_obj_to_glb_data(path)
		"wav":
			mime_type = "audio/wav"
			file_data = TMFileUtil.load_file_bytes(path)
		"mp3":
			mime_type = "audio/mpeg"
			file_data = TMFileUtil.load_file_bytes(path)
	if mime_type.is_empty() or file_data.is_empty():
		res_promise.set_error("Mime or file data empty")
		return res_promise
	var promise_upload = Net.asset_client.upload_file_public(asset_data.get("_id"), file_data, mime_type)
	var asset_data_file = await promise_upload.wait_till_fulfilled()
	if promise_upload.is_error():
		Notify.error(tr("File Upload Error"), promise_upload.get_error_message())
	else:
		Notify.success(tr("File Upload Complete"), asset_data_file["name"] + " successfully uploaded!")
	res_promise.set_result(asset_data_file)
	return res_promise


func _on_close_button_pressed() -> void:
	_object_creation.toggle_browser_expanded()


func _on_recents_request_edit_script_instance(script_instance: ScriptInstance) -> void:
	request_edit_script_instance.emit(script_instance)
	track_recently_used_space_script(script_instance)
