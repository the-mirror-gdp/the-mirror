################################### R E A D M E ##################################
# Small standalone scene designed to provide ui that allows to pack tscn in pck
# Just run it by pressing F6 in the editor, choose tscn which you want to pack and destination directory
# where .pck containing that tscn should be created.
extends MarginContainer


const PCK_TARGET_DIRECTORY_PATH = "res://addons/mirror_internal/PckPackerTool/"

@onready var choose_file_dialog: FileDialog = get_node("ChooseFileDialog")
@onready var choose_directory_dialog: FileDialog = get_node("ChooseDirectoryDialog")
@onready var choose_pck_2_send_dialog: FileDialog = get_node("ChoosePckFileDialog")
@onready var file_label: Label = get_node("VBoxContainer/ChooseFile/ChoosenFileText")
@onready var directory_label: Label = get_node("VBoxContainer/ChooseDirectory/ChoosenDirText")
@onready var selected_pck_label: Label = get_node("VBoxContainer/HBoxContainer/SelectedPck")
@onready var unpacked_instances: Node3D = get_node("unpackedInstances")

var selected_file_path: String = ""
var selected_directory_path: String = ""
var selected_pck_to_send: String = ""


func _ready() -> void:
	choose_directory_dialog.current_dir = PCK_TARGET_DIRECTORY_PATH


######
## Scene chooose
func _on_choose_file_btn_pressed() -> void:
	choose_file_dialog.popup_centered_ratio()
	selected_file_path = await choose_file_dialog.file_selected
	file_label.set_text(selected_file_path)


######
## Directory chooose
func _on_choose_dir_btn_pressed() -> void:
	choose_directory_dialog.popup_centered_ratio()
	selected_directory_path = await choose_directory_dialog.dir_selected
	directory_label.set_text(selected_directory_path)


######
## Pack
func _on_pack_pressed() -> void:
	var filepath_name = selected_file_path.get_file().replace(selected_file_path.get_extension(), "")
	var target_pck_filepath = selected_directory_path + "/" + filepath_name + "pck"
	ScenePacker.pack_scene_to_pck_file(selected_file_path, target_pck_filepath)


######
## Pck for sending
func _on_test_unpack_choose_btn_pressed() -> void:
	choose_pck_2_send_dialog.popup_centered_ratio()
	selected_pck_to_send = await choose_pck_2_send_dialog.file_selected
	selected_pck_label.set_text(selected_pck_to_send)


func _on_unpack_pressed() -> void:
	for child in unpacked_instances.get_children():
		child.queue_free()

	print("Unpadking pck file: ", selected_pck_to_send)
	var node = ScenePacker.get_unpacked_pck_as_node(selected_pck_to_send)
	print("If no errors above we are good (there might be some warnings, it's safe to ignore them as for now)")

	# will work ok for dumb pck, for ones with scripts we might encounter errors related for example
	# to wrong script parsing (assuming some script is attached to the scene from pck)
	unpacked_instances.add_child(node)
