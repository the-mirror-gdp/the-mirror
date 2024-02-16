extends GutTest

var MirrorTable = load("res://ui/teams/test_table.tscn")


func test_table_is_empty():
	var instance = add_child_autofree(MirrorTable.instantiate())
	assert_true(instance.get_row(0) == Array(), "table row is empty")


func test_table_get_row():
	var instance = add_child_autofree(MirrorTable.instantiate())
	instance.add_row({"id":10}) # specify external id as 10
	var internal_id = instance.find_row_internal_id(10)
	assert_true(internal_id != -1, "valid internal id")
	assert_true(instance.get_row(10) == instance._internal_get_row(internal_id), "valid internal id matches")
	# must be invalid
	assert_true(instance.get_row(0) == Array(), "table index 0 row is null")
	assert_true(instance.get_row(10) != Array(), "external id match failed")


func test_table_remove_row():
	var instance = add_child_autofree(MirrorTable.instantiate())
	instance.add_row({"id":10}) # specify external id as 10
	# must be invalid
	assert_true(instance.get_row(0) == Array(), "table row is not empty")
	assert_true(instance.get_row(10) != Array(), "external id match failed")
	instance.remove_row(10) # specify external id as 10
	assert_true(instance.get_row(0) == Array(), "table row is not empty")
	assert_true(instance.get_row(10) == Array(), "external id match failed")


func test_table_multiple_rows():
	var instance = add_child_autofree(MirrorTable.instantiate())
	for row_id in range(10):
		instance.add_row({"id": row_id+15}) # specify external id as +15
		assert_true(instance.get_row(row_id+15) != Array(), "external id match failed")
		instance.remove_row(row_id+15) # specify external id as +15
		assert_true(instance.get_row(row_id+15) == Array(), "external id match failed")


func test_table_ascending_row_removal():
	var instance = add_child_autofree(MirrorTable.instantiate())
	for row_id in range(10):
		var id = row_id + 12
		instance.add_row({"id": id}) # specify external id as +12
		assert_true(instance.get_row(id) != Array(), "external id match failed")
		var internal_id = instance.find_row_internal_id(id)
		assert_true(internal_id != -1, "internal id was found")
		assert_true(instance.get_row(id) == instance._internal_get_row(internal_id), "internal id directly matches external id instance")
	for row_id in range(10):
		var id = row_id + 12
		var internal_id = instance.find_row_internal_id(id)
		assert_true(instance.get_row(id) == instance._internal_get_row(internal_id), "internal id directly matches external id instance")
		instance.remove_row(id) # specify external id as +12
		assert_true(instance._internal_get_row(internal_id) == Array(), "internal id row was deleted properly")
		assert_true(instance.get_row(row_id+12) == Array(), "external id match failed")


func test_clear_table():
	var instance = add_child_autofree(MirrorTable.instantiate())
	for row_id in range(10):
		var id = row_id + 12
		instance.add_row({"id": id}) # specify external id as +12
		assert_true(instance.get_row(id) != Array(), "external id match failed")
		var internal_id = instance.find_row_internal_id(id)
		assert_true(internal_id != -1, "internal id was found")
		assert_true(instance.get_row(id) == instance._internal_get_row(internal_id), "internal id directly matches external id instance")
	instance.clear_table()
	for row_id in range(10):
		var id = row_id + 12
		var internal_id = instance.find_row_internal_id(id)
		var internal_row = instance.get_row(id)
		if internal_id != -1:
			print("row_id:" , internal_id)
			print("get row: ", instance._internal_get_row(internal_id))
		assert_eq(internal_id, -1, "ensure data is gone")
		assert_true(instance.get_row(id) == Array(), "ensure external data is gone")


func test_row_removal_is_correct_order():
	var instance = add_child_autofree(MirrorTable.instantiate())
	instance.add_row({"id": 1, "test_data" : "some_other_element"})
	instance.add_row({"id": 2, "test_data" : "working_element"})
	var component_1 = instance.get_row(1)[0]
	var component_2 = instance.get_row(2)[0]
	assert_ne(component_1.get_meta("external_id"), component_2.get_meta("external_id"))
	assert_eq(component_1.get_meta("external_id"), 1)
	assert_eq(component_2.get_meta("external_id"), 2)
	instance.remove_row(1)
	var component_3 = instance.get_row(2)[0]
	var component_4 = instance.get_row(1)
	assert_eq(component_3.get_meta("external_id"), 2)
	assert_eq(component_4, Array())
