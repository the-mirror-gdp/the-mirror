extends LoginIntegrationTest


var _test_terrain: Dictionary


func _init() -> void:
	_test_queue.append_array([
		&"login_firebase",
		&"test_create_terrain",
		&"test_get_terrain",
		&"test_get_public_terrain",
		&"test_get_user_terrain",
		&"test_update_terrain",
		&"test_delete_terrain",
	])


## Test: Creates terrain
func test_create_terrain() -> void:
	var new_terrain: Dictionary = {
		"name": "terrain",
	}
	Net.terrain_client.terrain_created.connect(_terrain_created_pass, CONNECT_ONE_SHOT)
	Net.terrain_client.request_errored.connect(test_failed)
	Net.terrain_client.create_terrain(new_terrain)


## Pass: created a new terrain
func _terrain_created_pass(terrain: Dictionary) -> void:
	Net.terrain_client.request_errored.disconnect(test_failed)
	_test_terrain = terrain
	test_passed(terrain["_id"])


## Test: Gets a terrain entity
func test_get_terrain() -> void:
	Net.terrain_client.terrain_received.connect(_terrain_received_pass, CONNECT_ONE_SHOT)
	Net.terrain_client.request_errored.connect(test_failed)
	Net.terrain_client.get_terrain(_test_terrain["_id"])


## Pass: created a new terrain
func _terrain_received_pass(terrain: Dictionary) -> void:
	Net.terrain_client.request_errored.disconnect(test_failed)
	test_passed(terrain["_id"])


## Test: Gets the user's terrain entities
func test_get_user_terrain() -> void:
	Net.terrain_client.user_terrain_received.connect(_user_terrain_received_pass, CONNECT_ONE_SHOT)
	Net.terrain_client.request_errored.connect(test_failed)
	Net.terrain_client.get_user_terrain()


## Pass: received user terrain entities
func _user_terrain_received_pass(user_terrain: Array) -> void:
	Net.terrain_client.request_errored.disconnect(test_failed)
	test_passed("User Terrain Count: %s" % str(user_terrain.size()))


## Test: Gets a terrain entity
func test_get_public_terrain() -> void:
	Net.terrain_client.public_terrain_received.connect(_public_terrain_received_pass, CONNECT_ONE_SHOT)
	Net.terrain_client.request_errored.connect(test_failed)
	Net.terrain_client.get_public_terrain()


## Pass: received public terrain entities
func _public_terrain_received_pass(public_terrain: Array) -> void:
	Net.terrain_client.request_errored.disconnect(test_failed)
	test_passed("Public Terrain Count: %s" % str(public_terrain.size()))


## Test: update terrain
func test_update_terrain() -> void:
	_test_terrain["name"] = "updated terrain"
	Net.terrain_client.terrain_updated.connect(_terrain_updated_pass, CONNECT_ONE_SHOT)
	Net.terrain_client.request_errored.connect(test_failed)
	Net.terrain_client.update_terrain(_test_terrain)


## Pass: updated a terrain
func _terrain_updated_pass(terrain: Dictionary) -> void:
	Net.terrain_client.request_errored.disconnect(test_failed)
	test_passed(terrain["_id"])


## Test: Delete a terrain
func test_delete_terrain() -> void:
	Net.terrain_client.terrain_deleted.connect(_terrain_deleted_pass, CONNECT_ONE_SHOT)
	Net.terrain_client.request_errored.connect(test_failed)
	Net.terrain_client.delete_terrain(_test_terrain["_id"])


## Pass: deleted a terrain
func _terrain_deleted_pass(terrain: Dictionary) -> void:
	Net.terrain_client.request_errored.disconnect(test_failed)
	test_passed(terrain["_id"])
