extends GutTest


func test_snapped_position():
	var position1 = Vector3(0.5, 0.3, 0.9)
	var position2 = Vector3(0.0, 0.0, 0.0)
	var position3 = Vector3(0.2, 0.2, 0.2)
	var position4 = Vector3(0.25, 0.25, 0.25)
	var position5 = Vector3(0.3, 0.3, 0.3)
	var snapped_position1 = Util.get_snapped_position(position1, 1.0)
	var snapped_position2 = Util.get_snapped_position(position2, 1.0)
	var snapped_position3 = Util.get_snapped_position(position3, 0.25)
	var snapped_position4 = Util.get_snapped_position(position4, 0.25)
	var snapped_position5 = Util.get_snapped_position(position5, 0.25)
	assert_eq(snapped_position1, Vector3.ONE)
	assert_eq(snapped_position2, Vector3.ZERO)
	assert_eq(snapped_position3, Vector3(0.25, 0.25, 0.25))
	assert_eq(snapped_position4, Vector3(0.25, 0.25, 0.25))
	assert_eq(snapped_position5, Vector3(0.5, 0.5, 0.5))
