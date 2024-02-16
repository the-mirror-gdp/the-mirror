extends GutTest

const _test_file_hash: String = "f1d4b277355d3576810c7a17bbd1ac1cfdb0391bd7f338ea78f7010e57539fcf"

func test_platform_names() -> void:
	assert_eq(Util.get_simple_platform_name("Windows"), "windows")
	assert_eq(Util.get_simple_platform_name("macOS"), "macos")
	assert_eq(Util.get_simple_platform_name("mac"), "macos")
	assert_eq(Util.get_simple_platform_name("MACOS"), "macos")
	assert_eq(Util.get_simple_platform_name("Linux"), "linuxbsd")
	assert_eq(Util.get_simple_platform_name("FreeBSD"), "linuxbsd")
	assert_eq(Util.get_simple_platform_name("NetBSD"), "linuxbsd")
	assert_eq(Util.get_simple_platform_name("OpenBSD"), "linuxbsd")
	assert_eq(Util.get_simple_platform_name("BSD"), "linuxbsd")
	assert_eq(Util.get_simple_platform_name("linuxbsd"), "linuxbsd")
	assert_true([Util.MAC_NAME, Util.WIN_NAME, Util.LINUX_NAME].has(Util.get_current_platform_name()))


func test_compare_hash() -> void:
	assert_true(Util.compare_hash("res://test/test_files/test-image.webp", _test_file_hash))
