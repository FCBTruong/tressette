extends Node

# Function to convert a float to a byte array (4 bytes)
func float_to_bytes(float_value: float) -> PackedByteArray:
	var bytes = PackedByteArray()
	var float_array = PackedFloat32Array([float_value])
	bytes = float_array.to_byte_array()
	return bytes

func double_to_bytes(double_value: float) -> PackedByteArray:
	var double_array = PackedFloat64Array([double_value])
	return double_array.to_byte_array()
	
func bytes_to_double(byte_array: PackedByteArray) -> float:
	# Ensure the byte array has exactly 8 bytes (size of a double in IEEE 754 format)
	if byte_array.size() != 8:
		push_error("Invalid byte array size. Expected 8 bytes for a double.")
		return 0.0

	# Create a stream from the byte array
	var stream = StreamPeerBuffer.new()
	stream.data_array = byte_array

	# Reset the cursor position to the start
	stream.seek(0)

	# Read a double (64-bit float) from the stream
	return stream.get_double()

# Convert int64 to float
func int64_to_float(value: int) -> float:
	var byte_array = PackedByteArray()
	byte_array.append_array(PackedByteArray([value & 0xFF, (value >> 8) & 0xFF, (value >> 16) & 0xFF, (value >> 24) & 0xFF,
			(value >> 32) & 0xFF, (value >> 40) & 0xFF, (value >> 48) & 0xFF, (value >> 56) & 0xFF]))
	return byte_array.get_double(0)
