extends Container

const _MAX_FILE_SIZE = 5 << 20 # 5 MiB

signal publish_space_request()

@export var _empty_cover_texture: Texture2D
@export var _loading_overlay_panel: Node

@onready var _space_name_line_edit = %SpaceNameLineEdit
@onready var _descritpion_text_edit = %DescritpionTextEdit
@onready var _max_players_spin_box = %MaxPlayersSpinBox
@onready var _delete_space_confirmation_dialog = $DeleteSpaceConfirmationDialog
@onready var _file_search: FileDialog = $FileSearch
@onready var _cover_space_image = %CoverSpaceImage
@onready var _upload_images = [%ImageButton0, %ImagesContainer/ImageButton1,
		%ImagesContainer/ImageButton2, %ImagesContainer/ImageButton3,
		%ImagesContainer/ImageButton4]
@onready var _publish_button = $HBoxContainer/PublishButton

var _space: Dictionary
var _last_upload_directory: String = ""
var _images_to_upload_queue: Dictionary = {}


func _ready():
	_publish_button.visible = false
	for image_index in _upload_images.size():
		_upload_images[image_index].pressed.connect(_on_upload_button_pressed.bind(image_index))


func _on_visibility_changed():
	# As we are instantiate Edit Space Settings Page in few places we need
	# to reconnect all signals on visiblity change
	if visible:
		_images_to_upload_queue = {}
		for i in range(_upload_images.size()):
			if _space.has("images") and not _space.images.is_empty() and i < _space.images.size():
				if _space.images[i] != null:
					_upload_images[i].set_image_from_url(_space.images[i])
					continue
			_upload_images[i].set_image(_empty_cover_texture)


func populate(space: Dictionary) -> void:
	_space = space
	_space_name_line_edit.text = space.get("name", "")
	_descritpion_text_edit.text = space.get("description", "")
	_max_players_spin_box.set_value_no_signal(space.get("maxUsers", 32))
	var role: int = Util.get_role_for_user(space, Net.user_id)
	_publish_button.visible = role >= Enums.ROLE.OWNER


func _preprocess_tags_description(desc: String) -> Array:
	var words = desc.replace("\n", " ").split(" ", false)
	var space_tags = []
	for word in words:
		if word.lstrip(" ").begins_with("#"):
			space_tags.append(word.right(-1))
	return space_tags


func _on_save_button_pressed():
	if _space.get("_id") == null:
		return
	var tags = _preprocess_tags_description(_descritpion_text_edit.text)
	var updated_space_data: Dictionary = {
		"name": _space_name_line_edit.text,
		"description": _descritpion_text_edit.text,
		"maxUsers": _max_players_spin_box.value
	}

	if _images_to_upload_queue.size() > 0:
		_loading_overlay_panel.show()

	var promise = Net.space_client.update_space(_space.get("_id"), updated_space_data)
	await promise.wait_till_fulfilled()
	if promise.is_error():
		Notify.error(tr("Space Update Failure"), promise.get_error_message())
		return

	var tag_dict = {
			"tagType": "search",
			"tags": tags
	}
	promise = Net.space_client.update_space_tags(_space.get("_id"), tag_dict)
	await promise.wait_till_fulfilled()
	if promise.is_error():
		Notify.error(tr("Space Update Failure"), promise.get_error_message())
		return

	Notify.success(tr("Space Update"), tr("Space updated successfully."))

	for image_index in _images_to_upload_queue:
		_upload_image(_images_to_upload_queue[image_index], image_index)



func _on_delete_button_pressed():
	_delete_space_confirmation_dialog.popup_centered()


func _on_delete_space_confirmation_dialog_confirmed():
	if _space.get("_id") == null:
		return
	var promise = Net.space_client.delete_space(_space.get("_id"))
	_loading_overlay_panel.show()
	await promise.wait_till_fulfilled()
	_loading_overlay_panel.hide()
	if promise.is_error():
		Notify.error(tr("Space Deletion Failed"), promise.get_error_message())
	else:
		GameUI.main_menu_ui.cleanup_history()
		GameUI.main_menu_ui.show_default_subpage()
		Notify.success(tr("Space Deleted"), tr("Space deleted successfully."))


func _show_image_upload_dialog(image_index:= 0) -> void:
	var supported_formats: PackedStringArray = ["*.png, *.jpg, *.jpeg, *.webp; Supported Files"]
	_file_search.filters = supported_formats
	# Clear any previous signal connection, we  want to bind correct image index
	Util.safe_signal_disconnect(_file_search.file_selected, _on_file_search_file_selected)
	_file_search.file_selected.connect(_on_file_search_file_selected.bind(image_index))
	_file_search.show()
	if _last_upload_directory.is_empty():
		_file_search.current_dir = OS.get_user_data_dir()
		_file_search.current_path = OS.get_user_data_dir() + "/Asset/"
	else:
		_file_search.current_dir = _last_upload_directory
		_file_search.current_path = "%s/" % _last_upload_directory


func _on_upload_button_pressed(image_index := 0):
	_show_image_upload_dialog(image_index)


func _validate_image(path: String) -> bool:
	var file = FileAccess.open(path, FileAccess.READ)
	var file_size = file.get_length()
	if file_size >= _MAX_FILE_SIZE:
		Notify.error("Image Error", "Cannot upload file with a size greater than 5 MiB")
		return false

	var file_name: String = path.get_file()
	if not Util.path_is_image(file_name):
		print("Invalid file selected")
		return false
	return true


func _on_file_search_file_selected(path: String, image_index := 0) -> void:
	if not _validate_image(path):
		return
	var file_data = Util.get_webp_data_at_path(path)
	if file_data.is_empty():
		return
	#show preview
	var tex = Util.convert_webp_bytes_to_texture(file_data)
	if not tex is Texture2D:
		Notify.error("Image Error", "Invalid image data")
		return
	_upload_images[image_index].set_image(tex)
	_images_to_upload_queue[image_index] = path
	_last_upload_directory = path.get_base_dir()


func _upload_image(path: String, image_index = 0) -> void:
	if not _validate_image(path):
		return
	var file_data = Util.get_webp_data_at_path(path)
	if file_data.is_empty():
		return
	var promise = Net.space_client.update_image_space(_space.get("_id"), image_index, file_data)
	promise.connect_func_to_fulfill(_on_space_image_updated.bind(promise, image_index))


func _on_space_image_updated(promise: Promise, image_index: int):
	if promise.is_error():
		Notify.error("Error on File Upload", promise.get_error_message())
	_images_to_upload_queue.erase(image_index)
	if _images_to_upload_queue.is_empty():
		_loading_overlay_panel.hide()
		Notify.success("File Upload", "Space image(s) uploaded")


func _on_cancel_button_pressed():
	GameUI.main_menu_ui.history_go_back()


func _on_publish_button_pressed():
	publish_space_request.emit()
