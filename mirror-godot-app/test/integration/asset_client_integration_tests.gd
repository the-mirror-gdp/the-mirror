extends LoginIntegrationTest


# Data that is created when we run this test
var _test_asset_data: Dictionary

var _count_public_assets: int


## Initializes the AssetClient integration test queue.
func _init() -> void:
	_test_queue.append_array([
		&"login_firebase",
		&"test_get_my_assets_pg1",
		&"test_get_my_assets_pg2",
		&"test_get_my_library_assets_pg1",
		&"test_get_my_library_assets_pg2",
		&"test_get_mirror_assets_pg1",
		&"test_get_mirror_assets_pg2",
		&"test_create_asset",
		&"test_get_asset",
		&"test_update_asset",
		&"test_delete_asset",
		&"test_create_invalid_asset",
		&"test_get_asset_not_found",
		&"test_update_asset_not_found",
	])


## Test: Creates an asset with the minimum requirements needed.
func test_create_asset() -> void:
	var asset_data: Dictionary = {
		"name": "Test Asset",
		"assetType": Enums.ASSET_TYPE.MESH,
		"massKg": 2
	}
	Net.asset_client.asset_created.connect(_asset_created_pass, CONNECT_ONE_SHOT)
	var promise = Net.asset_client.create_asset(asset_data)
	await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())


## Pass: Sets the new asset as test_asset_data
func _asset_created_pass(asset_data: Dictionary) -> void:
	_test_asset_data = asset_data
	test_passed("Created asset %s" % _test_asset_data["_id"])


## Test: Attempts to create an asset with missing data
func test_create_invalid_asset() -> void:
	Net.asset_client.asset_created.connect(_asset_created_with_invalid_data_fail, CONNECT_ONE_SHOT)
	var promise = Net.asset_client.create_asset({})
	await promise.wait_till_fulfilled()
	if promise.is_error():
		Net.asset_client.asset_created.disconnect(_asset_created_with_invalid_data_fail)
		test_passed("Asset did not create with incomplete data. %s" % promise.get_error_message())


## Fail: Asset gets created with missing data
func _asset_created_with_invalid_data_fail(_asset_data: Dictionary) -> void:
	test_failed("Created asset with invalid data. Server should reject this incomplete data.")



## Test: Gets an asset that does exist (real asset)
func test_get_asset() -> void:
	Net.asset_client.asset_received.connect(_asset_received_pass, CONNECT_ONE_SHOT)
	var promise = Net.asset_client.queue_download_asset(_test_asset_data["_id"])
	await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())


## Pass: Asset is received
func _asset_received_pass(asset_data: Dictionary) -> void:
	test_passed("Received asset with id %s" % asset_data["_id"])


## Test: Attempts to get an asset with a fake _id
func test_get_asset_not_found() -> void:
	var fake_asset: Dictionary = {
		"fake_id": "8675309",
	}
	Net.asset_client.asset_received.connect(_get_asset_not_found_fail, CONNECT_ONE_SHOT)
	var promise = Net.asset_client.queue_download_asset(fake_asset["fake_id"])
	await promise.wait_till_fulfilled()
	if promise.is_error():
		Net.asset_client.asset_received.disconnect(_get_asset_not_found_fail)
		test_passed("Attempted to get an asset that does not exist")


## Fail: Non existent asset received
func _get_asset_not_found_fail(_asset_data: Dictionary) -> void:
	test_failed("Non-existent asset received")



func test_get_my_assets_pg1() -> void:
	var params = Net.asset_client.AssetListRequestParameters.new()
	params.page = 1
	var promise = Net.asset_client.get_my_assets(params)
	var page = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	test_passed("My Assets: assets: %s, page: %s" % [page["data"].size(), page["page"]])


func test_get_my_assets_pg2() -> void:
	var params = Net.asset_client.AssetListRequestParameters.new()
	params.page = 2
	var promise = Net.asset_client.get_my_assets(params)
	var page = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	test_passed("My Assets: assets: %s, page: %s" % [page["data"].size(), page["page"]])


func test_get_mirror_assets_pg1() -> void:
	var params = Net.asset_client.AssetListRequestParameters.new()
	params.page = 1
	var promise = Net.asset_client.get_mirror_assets(params)
	var page = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	test_passed("Mirror Assets: assets: %s, page: %s" % [page["data"].size(), page["page"]])

func test_get_mirror_assets_pg2() -> void:
	var params = Net.asset_client.AssetListRequestParameters.new()
	params.page = 2
	var promise = Net.asset_client.get_mirror_assets(params)
	var page = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	test_passed("Mirror Assets: assets: %s, page: %s" % [page["data"].size(), page["page"]])


func test_get_my_library_assets_pg1() -> void:
	var params = Net.asset_client.AssetListRequestParameters.new()
	params.page = 1
	var promise = Net.asset_client.get_library_assets(params)
	var page = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	test_passed("Library Assets: assets: %s, page: %s" % [page["data"].size(), page["page"]])


func test_get_my_library_assets_pg2() -> void:
	var params = Net.asset_client.AssetListRequestParameters.new()
	params.page = 2
	var promise = Net.asset_client.get_library_assets(params)
	var page = await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())
		return
	test_passed("Library Assets: assets: %s, page: %s" % [page["data"].size(), page["page"]])



## Test: Updates an asset
func test_update_asset() -> void:
	var updated_asset_data: Dictionary = {
		"name": "Updated Asset Name",
	}
	Net.asset_client.asset_updated.connect(_asset_updated_pass, CONNECT_ONE_SHOT)
	var promise = Net.asset_client.update_asset(_test_asset_data["_id"], updated_asset_data)
	await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())


## Pass: Asset was updated
func _asset_updated_pass(asset_data: Dictionary) -> void:
	test_passed("Updated asset %s" % asset_data["_id"])


## Test: Attempts to update a fake asset
func test_update_asset_not_found() -> void:
	var fake_asset_data: Dictionary = {
		"fake_id": "8675309",
		"fake_name": "Fake Asset Name",
	}
	Net.asset_client.asset_updated.connect(_asset_update_not_found_fail, CONNECT_ONE_SHOT)
	var promise = Net.asset_client.update_asset(fake_asset_data["fake_id"], fake_asset_data)
	await promise.wait_till_fulfilled()
	if promise.is_error():
		Net.asset_client.asset_updated.disconnect(_asset_update_not_found_fail)
		test_passed("Non-existent asset could not update.")

## Fail: Attempts to update a non-existent asset. The server should not be throwing a success response.
func _asset_update_not_found_fail(_asset_data: Dictionary) -> void:
	test_failed("Update a non-existent asset should have been error but the server indicated success.")




## Test: Deletes an asset
func test_delete_asset() -> void:
	Net.asset_client.asset_deleted.connect(_asset_deleted_pass, CONNECT_ONE_SHOT)
	var promise = Net.asset_client.delete_asset(_test_asset_data["_id"])
	await promise.wait_till_fulfilled()
	if promise.is_error():
		test_failed(promise.get_error_message())


## Pass: Deleted the asset
func _asset_deleted_pass(asset_data: Dictionary) -> void:
	test_passed("Deleted asset %s" % asset_data["_id"])
