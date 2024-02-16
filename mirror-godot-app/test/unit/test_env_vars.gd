extends GutTest


func test_env():
	var env = Util.get_environment()
	assert_between(env, Enums.ENV.DEV, Enums.ENV.LOCAL)
