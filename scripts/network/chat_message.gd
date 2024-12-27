extends Object

# Fields for ChatMessage
var username: String
var message: String

func serialize() -> PackedByteArray:
	# Serialize the ChatMessage into a PackedByteArray
	var buffer = PackedByteArray()
	buffer.append_array(_serialize_string(username))
	buffer.append_array(_serialize_string(message))
	return buffer

func parse(data: PackedByteArray):
	# Parse a PackedByteArray to populate ChatMessage fields
	var offset = 0

	# Parse username
	var result = _parse_string(data, offset)
	username = result[0]
	offset = result[1]

	# Parse message
	result = _parse_string(data, offset)
	message = result[0]
	offset = result[1]

# Helper function to serialize a string into a PackedByteArray
func _serialize_string(value: String) -> PackedByteArray:
	var string_bytes = value.to_utf8_buffer()
	var length_bytes = PackedByteArray()
	var length = string_bytes.size()
	for i in range(4):
		length_bytes.append((length >> (i * 8)) & 0xFF)  # Append length as 4 bytes
	return length_bytes + string_bytes

# Helper function to parse a string from a PackedByteArray
func _parse_string(data: PackedByteArray, offset: int) -> Array:
	var length = _parse_int32(data, offset)
	offset += 4
	var value = data.slice(offset, offset + length).get_string_from_utf8()
	offset += length
	return [value, offset]

# Helper function to parse a 32-bit integer from PackedByteArray
func _parse_int32(data: PackedByteArray, offset: int) -> int:
	var value = 0
	for i in range(4):
		value |= int(data[offset + i]) << (i * 8)
	return value
