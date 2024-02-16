extends FileDialog

const inner_panel_material = preload("res://ui/common/shaders/grey_blur.mat.tres")

func _process(delta: float) -> void:
	sort_by(_col_index, true)

var tree: Tree

func _ready() -> void:
	# _process should only run when visible
	set_process(self.visible)
	tree = TMNodeUtil.recursive_get_node_by_type(self, Tree)

	# Set selection per Row instead of per Cell
	# See https://github.com/the-mirror-megaverse/mirror-godot-app/pull/1551#issuecomment-1728721229
	#  for rational
	tree.select_mode = Tree.SelectMode.SELECT_ROW
	# This is because we can't directly:
	# tree.item_selected.connect(self._tree_selected)
	# To act similarly to cell_selected
	tree.item_selected.connect(func ():
		tree.cell_selected.emit()
	)

	# Make the title bar have uppercase title
	# ( This is the window title, not a label )
	self.title = self.title.to_upper()

	# Make the panel transparent
	var panel = self.get_child(0, true)
	panel.material = inner_panel_material

	var vbox = self.get_child(3,true)

	var vbox_file_name_hbox =  vbox.get_child(3, true)
	var file_label = vbox_file_name_hbox.get_child(0, true)
	file_label.hide()
	var file_line_edit = vbox_file_name_hbox.get_child(1, true)
	file_line_edit.hide()
	var file_extension = vbox_file_name_hbox.get_child(2, true)
	## TODO a bit more left and right margin
#	file_extension.add_theme_override("margin")
	var vbox_hbox = vbox.get_child(0, true)

	# Remove the "drive selection" when not on windows:
	var hbox_containing_os_favorite_folders = vbox_hbox.get_child(8)
	if not OS.has_feature("windows"):
		hbox_containing_os_favorite_folders.hide()

	hide_directory_and_files_label(vbox)

	fit_buttons_size_closer_to_figma_design(vbox_hbox)
	fix_refresh_and_hide_buttons(vbox_hbox)


	var bottom_bar_hbox = self.get_child(2, true)
	try_to_right_align_confirmation_buttons(bottom_bar_hbox)

	add_sortable_columns_to_file_listing()

	self.visibility_changed.connect(
		func ():
			if(self.visible):
				# WORKAROUND: So that we see the column_titles[2].text
				# We only need it for the 2 last columns for some reasons
				sort_by(2)
				sort_by(1)
			set_process(self.visible)
	)



func try_to_right_align_confirmation_buttons(bottom_bar_hbox):
	var spacer_0 = bottom_bar_hbox.get_child(0, true)
	var button0 = bottom_bar_hbox.get_child(1, true)
	var spacer_1 = bottom_bar_hbox.get_child(2, true)
	var button1 = bottom_bar_hbox.get_child(3, true)
	var spacer_2 = bottom_bar_hbox.get_child(4, true)

	spacer_0.size_flags_stretch_ratio = 8
	spacer_1.size_flags_stretch_ratio = 0.5
	spacer_2.size_flags_stretch_ratio = 0.5

	button0.custom_minimum_size = Vector2(89, 37)
	button1.custom_minimum_size = Vector2(89, 37)


func fit_buttons_size_closer_to_figma_design(vbox_hbox):
	var button_go_back    = vbox_hbox.get_child(0)
	var button_go_forward = vbox_hbox.get_child(1)
	var button_go_up      = vbox_hbox.get_child(2)
	var button_refresh = vbox_hbox.get_child(6)
	var button_show_files = vbox_hbox.get_child(7)
	var button_arr = [button_go_back, button_go_forward, button_go_up, button_refresh, button_show_files]
	for button in button_arr:
		button.custom_minimum_size = Vector2(32, 32)
		button.expand_icon = true
	button_refresh.custom_minimum_size = Vector2(24, 24)
	button_show_files.custom_minimum_size = Vector2(24, 24)
	## NOTE We have a StyleBoxEmpty on hover in the file_search_theme.tres
	##   It adds some margins so that the icon get bigger on hover too


func _refresh_same_sorting():
	var old_col_index = _col_index
	var keep_current_ordering = true
	sort_by(old_col_index, keep_current_ordering)


# TODO MAYBE find how to use internal icons of the editor binary, if that helps later
var open_eye_icon  = preload("res://ui/art/internal_godot_icons/GuiVisibilityVisible.svg")
var closed_eye_icon = preload("res://ui/art/internal_godot_icons/GuiVisibilityHidden.svg")
func fix_refresh_and_hide_buttons(vbox_hbox):
	var button_refresh: Button = vbox_hbox.get_child(6)
	button_refresh.pressed.connect(_refresh_same_sorting)

	var button_show_files = vbox_hbox.get_child(7)
	button_show_files.pressed.connect(
		func swap_icon_on_button_toggle():
			if button_show_files.toggle_mode and button_show_files.button_pressed:
				## Here should be the "closed_eye_icon" as when we click, we want to hide
				## The same way that the arrow move us when we click,
				##   or the refresh button refreshes on click
				button_show_files.icon = closed_eye_icon
			else:
				button_show_files.icon = open_eye_icon

			## We need to wait for the showing of the hidden files before sorting
			await get_tree().process_frame
			_refresh_same_sorting()
	)


func hide_directory_and_files_label(vbox):
	var dir_label = vbox.get_child(1, true)
	dir_label.hide()


var col_names = [tr("File Name"), tr("Modified Timestamp"), tr("Size")]
func add_sortable_columns_to_file_listing() -> void:
	tree.column_titles_visible = true
	tree.set_column_title(0, tr(col_names[0]))
	tree.set_column_title(1, tr(col_names[1]))
	tree.set_column_title(2, tr(col_names[2]))
	tree.columns = 3
	# Only the Name column should be expanding much
	tree.set_column_expand_ratio(0, 4)
	tree.set_column_expand_ratio(1, 1)
	tree.set_column_expand_ratio(2, 1)


	tree.column_title_clicked.connect(_on_column_title_clicked)

#	await get_tree().process_frame
#	tree.column_title_clicked.emit(1, 0)

var _col_index = 1
var want_ascending_order := true


func sort_by(col_index: int, keep_current_ordering:= false) -> void:
	var root = tree.get_root()
	var child = root.get_first_child()

	if not keep_current_ordering:
		if col_index == _col_index:
			want_ascending_order = not want_ascending_order
		else:
			want_ascending_order = false
	elif child != null:
		var date = child.get_text(1)
		if not date.is_empty():
			# It was already refreshed and sorted
			return

	# This resets the previous col_index to be without the (arrows)
	tree.set_column_title(self._col_index, col_names[self._col_index])
	self._col_index = col_index
	var arrow =  tr("🡇") if want_ascending_order else tr("🡅")
	tree.set_column_title(self._col_index, "%s  %s" % [col_names[self._col_index], arrow])


	## \"Cut and paste\" all rows
	var old_tree_items_rows = []
	while(child != null):
		var name = child.get_text(0)
		var path = current_dir.path_join(name)
		var date = child.get_text(1)
		if date.is_empty():
			date = Time.get_datetime_string_from_unix_time(FileAccess.get_modified_time(path))
		var size: Variant = child.get_metadata(2)
		if size == null:
			# check if it is a file
			if FileAccess.file_exists(path):
				var file = FileAccess.open(path, FileAccess.READ)
				size = str(file.get_length())
			else:
				size = " "
		var icon = child.get_icon(0)
		var metadata = child.get_metadata(0)
		old_tree_items_rows.append([name, date, size, icon, metadata])
		var old_child = child
		child = child.get_next_visible(false)
		old_child.free()

	## Sort the rows
	old_tree_items_rows.sort_custom(func (a, b):
		if (want_ascending_order):
			return  a[col_index].naturalcasecmp_to(b[col_index]) < 0
		else:
			return  a[col_index].naturalcasecmp_to(b[col_index]) > 0
	)

	## Re-place the rows into TreeItems
	for row in old_tree_items_rows:
		child = tree.create_item(root)
		child.set_text(0, str(row[0]))
		child.set_text(1, str(row[1]))
		child.set_text(2, b_to_kb(int(row[2])))
		child.set_tooltip_text(2, "%s bytes" % str(row[2]))
		child.set_metadata(2, str(row[2]))
		child.set_icon(0, row[3])
		child.set_metadata(0, row[4])

		# Center our date and size columns
		child.set_text_alignment(1, HORIZONTAL_ALIGNMENT_CENTER)
		child.set_text_alignment(2, HORIZONTAL_ALIGNMENT_RIGHT)

func b_to_kb(byte_count: int) -> String:
	if byte_count == 0:
		return "-"
	elif byte_count < 10 ** 6:
		return "%.1f kB" % (float(byte_count) / (10 ** 3))
	else:
		return "%.1f MB" % (float(byte_count) / (10 ** 6))


func _on_column_title_clicked(column: int, _mouse_button_index: int) -> void:
	sort_by(column)
