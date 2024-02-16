extends GutTest


var _SPACE_OBJECT = load("res://gameplay/space_object/space_object.tscn")
var _SCALED_MODEL = load("res://gameplay/space_object/scaled_model.gd")
var _CLIENT = load("res://scripts/autoload/zone/client.gd")

var _copy_peer_client

const _SPACE_OBJECT_DATA: Dictionary = {
	"name": "Test object",
	"asset": "FakeAssetID",
	"castShadows": true,
	"visibleFrom": 6.0,
	"visibleTo": 20.0,
	"visibleFromMargin": 4.0,
	"visibleToMargin": 3.0,
	"asset_data": {} # This is simpler as we do not need to stub Net.asset_client class
}

func before_all():
	_copy_peer_client = Zone.client


func after_all():
	Zone.client = _copy_peer_client


func _setup_space_object(so_data: Dictionary) -> SpaceObject:
	var stubbed_so = double(_SPACE_OBJECT).instantiate()
	stubbed_so._test_harness = true
	# Fake data_store _configured to avoid call
	stubbed_so.data_store = DataStoreNode.new()
	stubbed_so.data_store._configured = true

	var sm = Node3D.new()
	sm.set_script(_SCALED_MODEL)
	stubbed_so.scaled_model = sm

	stub(stubbed_so, '_ready_safe').to_call_super()
	stub(stubbed_so, '_load_asset').to_do_nothing()
	stub(stubbed_so, '_populate_asset_data').to_do_nothing()
	stub(stubbed_so, 'populate').to_call_super()
	stub(stubbed_so, 'apply_from_dictionary').to_call_super()
	stub(stubbed_so, '_apply_transform_from_dictionary').to_do_nothing()
	stub(stubbed_so, 'populate_all_properties').to_call_super()
	stub(stubbed_so, '_set_and_convert_to_property').to_call_super()
	stub(stubbed_so, '_convert_to_property').to_call_super()

	stub(stubbed_so, 'serialize_extra_nodes').to_return([])
	stub(stubbed_so, 'serialize_script_instances').to_return([])
	stub(stubbed_so, 'get_model_scale').to_return(Vector3.ZERO)
	stub(stubbed_so, 'get_model_offset').to_return(Vector3.ZERO)
	stubbed_so.selection_label = Label3D.new()

	sm.setup_initial(stubbed_so) # done in _ready_safe but avoid stubbing
	stubbed_so.populate(so_data)
	var test_object = MeshInstance3D.new()
	sm.setup_model(test_object) # done in _setup_node_object but avoiding stubbing
	test_object.queue_free()
	assert_called(stubbed_so, '_ready_safe')
	assert_called(stubbed_so, '_load_asset')
	assert_called(stubbed_so, 'apply_from_dictionary')
	assert_called(stubbed_so, 'populate_all_properties')
	return stubbed_so


func test_creating_space_object():
	var stubbed_so = _setup_space_object(_SPACE_OBJECT_DATA)
	# Check visibility values on space_object meshes
	var sm_mi_node: MeshInstance3D = stubbed_so.scaled_model.get_model_root_node()
	assert_eq(sm_mi_node.visibility_range_begin, _SPACE_OBJECT_DATA["visibleFrom"])
	assert_eq(sm_mi_node.visibility_range_end, _SPACE_OBJECT_DATA["visibleTo"])
	assert_eq(sm_mi_node.visibility_range_begin_margin, _SPACE_OBJECT_DATA["visibleFromMargin"])
	assert_eq(sm_mi_node.visibility_range_end_margin, _SPACE_OBJECT_DATA["visibleToMargin"])
	assert_eq(sm_mi_node.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_ON)

	stubbed_so.scaled_model.queue_free()
	stubbed_so.queue_free()


func test_shift_d_duplicated_space_object():
	return # TODO: fix engine crashes with double
	Zone.client = double(_CLIENT).new()
	stub(Zone.client, 'client_send_create_space_object').to_do_nothing()
	var selection_helper = GameUI.creator_ui.selection_helper
	var stubbed_so = _setup_space_object(_SPACE_OBJECT_DATA)

	selection_helper.select_nodes([stubbed_so])
	Input.action_press(&"object_snap")
	selection_helper._on_transformation_started()
	selection_helper._on_transformation_ended()
	Input.action_release(&"object_snap")
	assert_called(Zone.client, 'client_send_create_space_object')
	var called_args = get_call_parameters(Zone.client, 'client_send_create_space_object')
	var properties = {} if called_args.size() != 2 else called_args[0]
	assert_true(properties.has("castShadows"))
	assert_true(properties.has("visibleFrom"))
	assert_true(properties.has("visibleTo"))
	assert_true(properties.has("visibleFromMargin"))
	assert_true(properties.has("visibleToMargin"))
	assert_eq(properties.get("castShadows"), _SPACE_OBJECT_DATA["castShadows"])
	assert_eq(properties.get("visibleFrom"), _SPACE_OBJECT_DATA["visibleFrom"])
	assert_eq(properties.get("visibleTo"), _SPACE_OBJECT_DATA["visibleTo"])
	assert_eq(properties.get("visibleFromMargin"), _SPACE_OBJECT_DATA["visibleFromMargin"])
	assert_eq(properties.get("visibleToMargin"), _SPACE_OBJECT_DATA["visibleToMargin"])

	stubbed_so.scaled_model.queue_free()
	stubbed_so.queue_free()


func test_copy_space_object():
	return # TODO: fix engine crashes with double
	Zone.client = double(_CLIENT).new()
	stub(Zone.client, 'client_send_create_space_object').to_do_nothing()
	var selection_helper = GameUI.creator_ui.selection_helper
	var stubbed_so = _setup_space_object(_SPACE_OBJECT_DATA)

	selection_helper.select_nodes([stubbed_so])
	selection_helper.copy_selected_nodes()
	selection_helper.paste_copied_nodes(Transform3D.IDENTITY)
	assert_called(Zone.client, 'client_send_create_space_object')
	var called_args = get_call_parameters(Zone.client, 'client_send_create_space_object')
	var properties = {} if called_args.size() != 2 else called_args[0]
	assert_true(properties.has("castShadows"))
	assert_true(properties.has("visibleFrom"))
	assert_true(properties.has("visibleTo"))
	assert_true(properties.has("visibleFromMargin"))
	assert_true(properties.has("visibleToMargin"))
	assert_eq(properties.get("castShadows"), _SPACE_OBJECT_DATA["castShadows"])
	assert_eq(properties.get("visibleFrom"), _SPACE_OBJECT_DATA["visibleFrom"])
	assert_eq(properties.get("visibleTo"), _SPACE_OBJECT_DATA["visibleTo"])
	assert_eq(properties.get("visibleFromMargin"), _SPACE_OBJECT_DATA["visibleFromMargin"])
	assert_eq(properties.get("visibleToMargin"), _SPACE_OBJECT_DATA["visibleToMargin"])

	stubbed_so.scaled_model.queue_free()
	stubbed_so.queue_free()
