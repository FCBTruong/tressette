extends Object

# Convert bytes to a double (using int64 for the conversion)
static func bytes_to_float64(data: PackedByteArray) -> float:
	if data.size() != 8:
		push_error("Double decoding failed: invalid byte array size.")
		return 0.0
	var result: int = 0
	for i in range(8):
		var byte = data[i] << (i * 8)
		result |= byte
	# Convert 64-bit integer to float
	return int64_to_float(result)

# Convert a double to bytes (using int64)
static func float64_to_bytes(value: float) -> PackedByteArray:
	var result = PackedByteArray()
	var int_value = float_to_int64(value)
	for i in range(8):
		result.append((int_value >> (i * 8)) & 0xFF)
	return result

# Convert int64 to float
static func int64_to_float(value: int) -> float:
	var byte_array = PackedByteArray()
	byte_array.append_array(PackedByteArray([value & 0xFF, (value >> 8) & 0xFF, (value >> 16) & 0xFF, (value >> 24) & 0xFF,
			(value >> 32) & 0xFF, (value >> 40) & 0xFF, (value >> 48) & 0xFF, (value >> 56) & 0xFF]))
	return byte_array.get_double(0)

# Convert float to int64
static func float_to_int64(value: float) -> int:
	var byte_array = PackedByteArray()
	byte_array.resize(8)
	byte_array.set_double(0, value)
	var int_value: int = 0
	for i in range(8):
		int_value |= (byte_array[i] << (i * 8))
	return int_value
