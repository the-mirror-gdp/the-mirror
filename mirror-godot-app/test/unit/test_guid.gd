extends GutTest


func test_guid():
	var guid = UUID.generate_guid()
	assert_true(guid is String)
	assert_eq(guid.length(), 36)
