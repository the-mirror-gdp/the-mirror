class_name BitField
##
## Helper class for bit operations.
##

var default_bit = 0
var FLAGS = {}

var bitfield: int


func any(bit):
	return (bitfield & resolve(bit)) != default_bit

func equals(bit):
	return bitfield == resolve(bit)

func has(bit):
	bit = resolve(bit)
	return (bitfield & bit) == bit

func missing(bits):
	pass

func add(bits):
	if not typeof(bits) == TYPE_ARRAY:
		bits = [bits]
	var total = default_bit
	for bit in bits:
		total |= resolve(bit)
	bitfield |= total
	return self

func remove(bits):

	if typeof(bits) == TYPE_OBJECT and bits.is_class(self.get_class()):
		bits = bits.bitfield

	if not typeof(bits) == TYPE_ARRAY:
		bits = [bits]

	var total = default_bit
	for bit in bits:
		total |= resolve(bit)
	bitfield &= ~total
	return self

func serialize():
	var serialized = {}

	var flags = FLAGS.keys()
	var bits = FLAGS.values()

	var i = 0
	for flag in flags:
		var bit = bits[i]
		serialized[flag] = has(bit)
		i += 1

	return serialized

func to_array():
	var ret = []

	var flags = FLAGS.keys()
	var bits = FLAGS.values()

	var i = 0
	for flag in flags:
		var bit = bits[i]
		if has(bit):
			ret.append(flag)
		i += 1

	return ret

func resolve(bit):
	if typeof(default_bit) == TYPE_INT or typeof(default_bit) == TYPE_FLOAT:
		default_bit = int(default_bit)

	if typeof(bit) == TYPE_INT or typeof(bit) == TYPE_FLOAT:
		bit = int(bit)

	if typeof(default_bit) == typeof(bit):
		if bit >= default_bit:
			return bit

	if typeof(bit) == TYPE_OBJECT and bit.is_class(self.get_class()):
		return bit.bitfield

	if (typeof(bit) == TYPE_ARRAY):
		var ret = default_bit

		for b in bit:
			ret = ret | resolve(b)
		return ret

	if (Helpers.is_valid_str(bit)):
		if (FLAGS.has(bit)):
			return FLAGS[bit]

		if (not is_nan(float(bit))):
			return int(bit)

	assert(false, 'Bitfield is invalid.')

func _init(bits = default_bit):
	if bits == null:
		bits = default_bit
	bitfield = resolve(bits)


func _to_dict():
	if typeof(bitfield) == TYPE_INT:
		return bitfield
	else:
		return str(bitfield)

func value_of():
	return bitfield

func _to_string():
	return str(bitfield)
