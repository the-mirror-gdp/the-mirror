extends Control

const _UV_SCALING: float = 0.1

@export var tab_material_icon: Texture2D
@export var tab_general_icon: Texture2D
@export var tab_other_icon: Texture2D

@onready var _heightmap_texture = %HeightmapTexture
@onready var _map_dropdown = %MapDropdown
@onready var _map_precision_dropdown = %MapPrecisionDropdown
@onready var _height_scale_slider = %HeightScaleSlider
@onready var _flat_material = %FlatMaterial
@onready var _uv_flat_slider = %UVFlatSlider
@onready var _cliff_material = %CliffMaterial
@onready var _uv_cliff_slider =%UVCliffSlider
@onready var _layer_offset_slider = %LayerOffsetSlider
@onready var _flat_cliff_ratio_slider = %FlatCliffRatioSlider
@onready var _asset_name_line_edit = %AssetNameLineEdit
@onready var _debounce_height_timer: Timer = $HeightDebounceTimer
@onready var _asset_save_debounce_timer: Timer = $AssetSaveDebounceTimer
@onready var _create_button = $VBoxContainer/InstanceButtons/CreateButton
@onready var _duplicate_button = $VBoxContainer/InstanceButtons/DuplicateButton
@onready var _label_user_no_privileges = $VBoxContainer/LabelUserNoPrivileges
@onready var _flat_color = %FlatColor
@onready var _cliff_color = %CliffColor
@onready var _colormap_texture = %ColormapTexture
@onready var _colormap_strength = %ColormapStrength
@onready var _tab_container: TabContainer = $VBoxContainer/TabContainer
@onready var _tab_general = $VBoxContainer/TabContainer/General
@onready var _tab_materials = $VBoxContainer/TabContainer/Materials
@onready var _tab_other = $VBoxContainer/TabContainer/Other
@onready var _no_map_selected = $VBoxContainer/NoMapSelected
@onready var _audio_stream_player_tab_changed = $AudioStreamPlayerTabChanged


@onready var _MAP_PRECISION_ARRAY = [
	{"text": tr("0.25 m"), "value": 4},
	{"text": tr("0.5 m"), "value": 2},
	{"text": tr("1.0 m"), "value": 1},
	{"text": tr("2.0 m"), "value": 0.5},
	{"text": tr("4.0 m"), "value": 0.25},
]

var _map_tool: Node
var _material_window: Node


func _setup_tabs_icons():
	var general_idx = _tab_container.get_tab_idx_from_control(_tab_general)
	var material_idx = _tab_container.get_tab_idx_from_control(_tab_materials)
	var other_idx = _tab_container.get_tab_idx_from_control(_tab_other)
	_tab_container.set_tab_icon(general_idx, tab_general_icon)
	_tab_container.set_tab_icon(material_idx, tab_material_icon)
	_tab_container.set_tab_icon(other_idx, tab_other_icon)


func _populate_map_size_array():
	for i in range(6,13):
		_map_dropdown.add_item(str(pow(2, i)))


func _populate_map_precision_array():
	for data in _MAP_PRECISION_ARRAY:
		_map_precision_dropdown.add_item(data.text)


func setup(creator_ui: CreatorUI) -> void:
	_setup_tabs_icons()
	_map_tool = creator_ui.map_tool
	_material_window = creator_ui.material_window
	creator_ui.scene_hierarchy.selection_changed.connect(_on_object_selection_changed)
	_populate_map_size_array()
	_populate_map_precision_array()
	_map_dropdown.reset_value = 3
	_map_dropdown.current_value = _map_dropdown.reset_value
	_map_precision_dropdown.reset_value = 2
	_map_precision_dropdown.current_value = _map_precision_dropdown.reset_value
	_map_tool.map_node_changed.connect(_populate_panel_data)
	_enable_panels(false, false)


## TODO: This is super ugly workaround
func emit_map_mode_toggle() -> void:
	var map_event = InputEventAction.new()
	map_event.action = &"map_mode_toggle"
	map_event.pressed = true
	Input.parse_input_event(map_event)


func _is_valid_build_node():
	return is_instance_valid(_map_tool) and is_instance_valid(_map_tool.get_build_node())


func _on_create_button_pressed():
	var space_role: Enums.ROLE = Util.get_role_for_user(Zone.space, Net.user_id)
	if space_role < Enums.ROLE.CONTRIBUTOR:
		Notify.error("Creating Map Error", "You do not have permission to edit this space")
		return
	_create_button.disabled = true
	_save_to_asset("", "", true)
	var asset_data = await Net.asset_client.asset_created
	assert(asset_data.get("assetType") == Enums.ASSET_TYPE.MAP)
	var asset_data_map = AssetDataMap.new()
	asset_data_map.populate(asset_data)
	# This will trigger new space object creation
	# And selected asset will change
	Zone.Scene.update_heightmap(asset_data_map)
	_create_button.disabled = false
	_populate_panel_data()


func _on_heightmap_texture_value_changed(new_value):
	if not _is_valid_build_node():
		return
	if _map_tool.get_build_node().asset_heightmap_image_id == new_value:
		return
	_map_tool.get_build_node().set_heightmap_asset_id(new_value)
	_update_asset()


func _on_height_scale_slider_value_changed(new_value):
	if not _is_valid_build_node():
		return
	# This is intensive operation that regenerates collider. Execute in moderation
	if not _debounce_height_timer.is_stopped():
		return
	_debounce_height_timer.start()
	await _debounce_height_timer.timeout
	if is_equal_approx(_map_tool.get_build_node().max_height, _height_scale_slider.current_value):
		return
	_map_tool.get_build_node().max_height = _height_scale_slider.current_value
	_update_asset()


func _on_flat_material_value_changed(new_value):
	if not _is_valid_build_node():
		return
	if _map_tool.get_build_node().asset_material_flat_id == new_value[1]:
		return
	_map_tool.get_build_node().set_flat_material_asset_id(new_value[1])
	_update_asset()


func _on_cliff_material_value_changed(new_value):
	if not _is_valid_build_node():
		return
	if _map_tool.get_build_node().asset_material_cliff_id == new_value[1]:
		return
	_map_tool.get_build_node().set_cliff_material_asset_id(new_value[1])
	_update_asset()


func _on_map_dropdown_value_changed(new_index):
	if not _is_valid_build_node():
		return
	if _map_tool.get_build_node().map_size == int(_map_dropdown.values[new_index]):
		return
	_map_tool.get_build_node().map_size = int(_map_dropdown.values[new_index])
	_update_asset()


func _enable_panels(enabled: bool, can_duplicate: bool) -> void:
	var nodes = [
			_heightmap_texture,
			_map_dropdown,
			_map_precision_dropdown,
			_height_scale_slider,
			_flat_material,
			_uv_flat_slider,
			_cliff_material,
			_uv_cliff_slider,
			_layer_offset_slider,
			_flat_cliff_ratio_slider,
			_asset_name_line_edit,
			_cliff_color,
			_flat_color,
			_colormap_texture,
			_colormap_strength,
	]
	for node in nodes:
		node.enabled = enabled
	_duplicate_button.disabled = not can_duplicate


func _is_user_allowed_to_edit_asset(asset_data: AssetData):
	var asset_role = {"role": asset_data.role}
	var asset_user_role: Enums.ROLE = Util.get_role_for_user(asset_role, Net.user_id)
	return asset_user_role >= Enums.ROLE.CONTRIBUTOR


func _is_user_allowed_to_edit_space():
	var space_role: Enums.ROLE = Util.get_role_for_user(Zone.space, Net.user_id)
	return space_role >= Enums.ROLE.CONTRIBUTOR


func _populate_panel_data():
	if _map_tool.get_build_node() == null:
		return
	_enable_panels(false, false)
	var heightmap = _map_tool.get_build_node()
	_heightmap_texture.current_value = heightmap.asset_heightmap_image_id
	for i in range(6,13):
		if pow(2, i) == heightmap.map_size:
			_map_dropdown.current_value = i - 6

	for i in len(_MAP_PRECISION_ARRAY):
		if is_equal_approx(_map_tool.get_build_node().precision, _MAP_PRECISION_ARRAY[i].value):
			_map_precision_dropdown.current_value = i

	_height_scale_slider.current_value = heightmap.max_height
	_flat_material.current_value = [Enums.MATERIAL_TYPE.ASSET ,heightmap.asset_material_flat_id]
	_cliff_material.current_value = [Enums.MATERIAL_TYPE.ASSET ,heightmap.asset_material_cliff_id]
	_uv_flat_slider.current_value = heightmap.uv_flat_scale / _UV_SCALING
	_uv_cliff_slider.current_value = heightmap.uv_cliff_scale / _UV_SCALING
	_layer_offset_slider.current_value = heightmap.layer_offset
	_flat_cliff_ratio_slider.current_value = heightmap.flat_cliff_ratio
	_asset_name_line_edit.current_value = heightmap.asset_data.asset_name
	_flat_color.current_value = heightmap.flat_color
	_cliff_color.current_value = heightmap.cliff_color
	_colormap_texture.current_value = heightmap.asset_colormap_image_id
	_colormap_strength.current_value = heightmap.colormap_strength
	_height_scale_slider.refresh()
	_uv_flat_slider.refresh()
	_uv_cliff_slider.refresh()
	_colormap_strength.refresh()
	_flat_cliff_ratio_slider.refresh()
	_colormap_strength.refresh()
	var edit_allowed = _is_user_allowed_to_edit_asset(heightmap.asset_data)
	var duplicate_allowed = _is_user_allowed_to_edit_space()
	_enable_panels(edit_allowed, duplicate_allowed)
	_label_user_no_privileges.visible = not edit_allowed


func _is_editing_a_map() -> bool:
	return _heightmap_texture.enabled


func _on_object_selection_changed(selected_nodes: Array[Node]) -> void:
	var old_map = _map_tool.get_build_node()
	if is_instance_valid(old_map):
		Util.safe_signal_disconnect(old_map.map_loaded, _populate_panel_data)
	if selected_nodes.size() != 1:
		# Ingore if we selected multiple nodes
		_enable_panels(false, false)
		_no_map_selected.visible = true
		_tab_container.visible = false
		return
	var selected_node = selected_nodes[0]
	if selected_node is SpaceObject and selected_node.asset_type == Enums.ASSET_TYPE.MAP:
		var map = selected_node.get_heightmap_or_null()
		if not map:
			printerr("Internal bug: Selected map is invalid")
			return
		_map_tool.change_build_node(map)
		Util.safe_signal_connect(map.map_loaded, _populate_panel_data)
		_no_map_selected.visible = false
		_tab_container.visible = true
		if not GameUI.instance.creator_ui.is_edit_mode(Enums.EDIT_MODE.Map):
			emit_map_mode_toggle()
		return
	_no_map_selected.visible = true
	_tab_container.visible = false
	# This will exit map edit mode
	if GameUI.instance.creator_ui.is_edit_mode(Enums.EDIT_MODE.Map):
		emit_map_mode_toggle()
	_enable_panels(false, false)


func _on_map_precision_dropdown_value_changed(new_index):
	if not _is_valid_build_node():
		return
	if new_index < 0 or new_index >= _MAP_PRECISION_ARRAY.size():
		return
	var precision = _MAP_PRECISION_ARRAY[new_index].value
	if _map_tool.get_build_node().precision == precision:
		return
	_map_tool.get_build_node().precision = precision
	_update_asset()


func _on_uv_flat_slider_value_changed(new_value):
	if not _is_valid_build_node():
		return
	if is_equal_approx(_map_tool.get_build_node().uv_flat_scale, new_value * _UV_SCALING):
		return
	# multipler is set by experimentation to fit most textures in db
	_map_tool.get_build_node().uv_flat_scale = new_value * _UV_SCALING
	_update_asset()


func _on_uv_cliff_slider_value_changed(new_value):
	if not _is_valid_build_node():
		return
	if is_equal_approx(_map_tool.get_build_node().uv_cliff_scale, new_value * _UV_SCALING):
		return
	# multipler is set by experimentation to fit most textures in db
	_map_tool.get_build_node().uv_cliff_scale = new_value * _UV_SCALING
	_update_asset()


func _on_layer_offset_value_changed(new_value):
	if not _is_valid_build_node():
		return
	if is_equal_approx(_map_tool.get_build_node().layer_offset, new_value):
		return
	_map_tool.get_build_node().layer_offset = new_value
	_update_asset()


func _on_flat_cliff_ratio_slider_value_changed(new_value):
	if not _is_valid_build_node():
		return
	if is_equal_approx(_map_tool.get_build_node().flat_cliff_ratio, new_value):
		return
	_map_tool.get_build_node().flat_cliff_ratio = new_value
	_update_asset()


func _generate_asset_name():
	var hm_json := Net.asset_client.get_asset_json(_heightmap_texture.current_value)
	return "%s %s" % [hm_json.get("name", "Map"), Time.get_datetime_string_from_system()]


func _update_asset():
	if not _is_valid_build_node() or not _is_editing_a_map():
		return
	#if not _asset_save_debounce_timer.is_stopped():
	#	return
	_asset_save_debounce_timer.start()




func _on_asset_save_debounce_timer_timeout():
	var asset_id = _map_tool.get_build_node().asset_data.asset_id
	var asset_name = _map_tool.get_build_node().asset_data.asset_name
	if asset_id.is_empty():
		print("Error: Trying to update an asset that doesn't have an ID!")
		return
	_save_to_asset(asset_id, asset_name)


func _save_to_asset(asset_id: String = "", asset_name: String = "", empty: bool = false):
	var name = _generate_asset_name() if asset_name.is_empty() else asset_name
	var asset_data: Dictionary = {
		"name": name,
		"mapName": name,
		"assetType": "MAP",
		"__t": "MapAsset",
		"thumbnail": "" # this will force a preview regeneration
	}
	if not empty:
		asset_data.merge({
			"mapSize": int(_map_dropdown.values[_map_dropdown.current_value]),
			"mapPrecision": _MAP_PRECISION_ARRAY[_map_precision_dropdown.current_value].value,
			"heightScale": _height_scale_slider.current_value,
			"layerOffset": _layer_offset_slider.current_value,
			"flatUVScale": _uv_flat_slider.current_value * _UV_SCALING,
			"cliffUVScale": _uv_cliff_slider.current_value * _UV_SCALING,
			"flatCliffRatio": _flat_cliff_ratio_slider.current_value,
			"flatColor": Serialization.color_to_array(_flat_color.current_value),
			"cliffColor": Serialization.color_to_array(_cliff_color.current_value),
			"colormapStrength": _colormap_strength.current_value
		})
		if not _heightmap_texture.current_value.is_empty():
			asset_data["heightmapAssetId"] =  _heightmap_texture.current_value
		if not _flat_material.current_value.is_empty() and not _flat_material.current_value[1].is_empty():
			asset_data["flatMaterialAssetId"] = _flat_material.current_value[1]
		if not _cliff_material.current_value.is_empty() and not _cliff_material.current_value[1].is_empty():
			asset_data["cliffMaterialAssetId"] = _cliff_material.current_value[1]
		if not _colormap_texture.current_value.is_empty():
			asset_data["colormapAssetId"] = _colormap_texture.current_value
	else:
		asset_data.merge({
			"mapSize": int(_map_dropdown.values[_map_dropdown.reset_value]),
			"mapPrecision": _MAP_PRECISION_ARRAY[_map_precision_dropdown.reset_value].value,
			"heightScale": _height_scale_slider.reset_value,
			"layerOffset": _layer_offset_slider.reset_value,
			"flatUVScale": _uv_flat_slider.reset_value * _UV_SCALING,
			"cliffUVScale": _uv_cliff_slider.reset_value * _UV_SCALING,
			"flatCliffRatio": _flat_cliff_ratio_slider.reset_value,
			"flatColor": Serialization.color_to_array(_flat_color.reset_value),
			"cliffColor": Serialization.color_to_array(_cliff_color.reset_value),
			"colormapStrength": _colormap_strength.reset_value
		})

	Analytics.track_event_client(AnalyticsEvent.TYPE.UPLOAD_ASSET)
	var promise: Promise
	if asset_id.is_empty():
		promise = Net.asset_client.create_asset(asset_data)
	else:
		promise = Net.asset_client.update_asset(asset_id, asset_data)
	await promise.wait_till_fulfilled()
	if promise.is_error():
		print("Error:", promise.get_error_message())
		Notify.error(tr("Map Error Update"), promise.get_error_message())
		return
	if _is_valid_build_node():
		_map_tool.get_build_node().asset_data._generate_preview_texture()
		await _map_tool.get_build_node().asset_data.preview_generated
	Net.request_synchronization_of_asset(asset_id)
	return promise.get_result()




func _on_asset_name_value_changed(new_value):
	if not _is_valid_build_node():
		return
	if _map_tool.get_build_node().asset_data.asset_name == new_value:
		return
	_map_tool.get_build_node().asset_data.asset_name = new_value
	_update_asset()


func _on_flat_color_value_changed(new_value):
	if not _is_valid_build_node():
		return
	if _map_tool.get_build_node().flat_color.is_equal_approx(new_value):
		return
	_map_tool.get_build_node().flat_color = new_value
	_update_asset()


func _on_cliff_color_value_changed(new_value):
	if not _is_valid_build_node():
		return
	if _map_tool.get_build_node().cliff_color.is_equal_approx(new_value):
		return
	_map_tool.get_build_node().cliff_color = new_value
	_update_asset()


func _on_colormap_texture_value_changed(new_value):
	if not _is_valid_build_node():
		return
	if _map_tool.get_build_node().asset_colormap_image_id == new_value:
		return
	_map_tool.get_build_node().set_colormap_asset_id(new_value)
	_update_asset()


func _on_colormap_strength_value_changed(new_value):
	if not _is_valid_build_node():
		return
	if is_equal_approx(_map_tool.get_build_node().colormap_strength, new_value):
		return
	_map_tool.get_build_node().colormap_strength = new_value
	_update_asset()


func _on_duplicate_button_pressed():
	_duplicate_button.disabled = true
	var asset_data = await _save_to_asset()
	var asset_data_map = AssetDataMap.new()
	asset_data_map.populate(asset_data)
	# This will trigger new space object creation
	# And selected asset will change
	Zone.Scene.update_heightmap(asset_data_map)
	_duplicate_button.disabled = false
	_populate_panel_data()
	Notify.info("Map", "Map was duplicated to users assets library")


func _on_tab_container_tab_changed(tab):
	_audio_stream_player_tab_changed.play()
