class_name UUID


const _MODULO_8_BIT = 256


static func _get_random_int_256():
	return randi() % _MODULO_8_BIT


static func _uuidbin() -> Array:
	# 16 random bytes with the bytes on index 6 and 8 modified
	return [
	_get_random_int_256(), _get_random_int_256(), _get_random_int_256(), _get_random_int_256(),
	_get_random_int_256(), _get_random_int_256(), ((_get_random_int_256()) & 0x0f) | 0x40, _get_random_int_256(),
	((_get_random_int_256()) & 0x3f) | 0x80, _get_random_int_256(), _get_random_int_256(), _get_random_int_256(),
	_get_random_int_256(), _get_random_int_256(), _get_random_int_256(), _get_random_int_256(),
]


static func generate_guid() -> String:
	# 16 random bytes with the bytes on index 6 and 8 modified
	var b = _uuidbin()
	return "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x" % [
	# low
	b[0], b[1], b[2], b[3],
	# mid
	b[4], b[5],
	# hi
	b[6], b[7],
	# clock
	b[8], b[9], b[10], b[11], b[12], b[13], b[14], b[15]
]
