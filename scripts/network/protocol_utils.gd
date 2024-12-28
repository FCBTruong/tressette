extends Node

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

# Function to convert a float to a byte array (4 bytes)
static func float_to_bytes(float_value: float) -> PackedByteArray:
	var bytes = PackedByteArray()
	var float_array = PackedFloat32Array([float_value])
	bytes = float_array.to_byte_array()
	return bytes

static func double_to_bytes(double_value: float) -> PackedByteArray:
	var double_array = PackedFloat64Array([double_value])
	return double_array.to_byte_array()

# Convert int64 to float
static func int64_to_float(value: int) -> float:
	var byte_array = PackedByteArray()
	byte_array.append_array(PackedByteArray([value & 0xFF, (value >> 8) & 0xFF, (value >> 16) & 0xFF, (value >> 24) & 0xFF,
			(value >> 32) & 0xFF, (value >> 40) & 0xFF, (value >> 48) & 0xFF, (value >> 56) & 0xFF]))
	return byte_array.get_double(0)
