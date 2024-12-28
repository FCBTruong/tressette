extends Object

class_name BaseReceivePacket

var buffer: PackedByteArray
var position: int
var field_number: int

# Constructor, initializes the buffer and position
func _init(p_buffer: PackedByteArray):
	buffer = p_buffer
	position = 0

# Read a Varint (used for integers in Protocol Buffers)
func get_varint() -> int:
	var result: int = 0
	var shift: int = 0
	while position < buffer.size():
		var byte: int = buffer[position]
		position += 1
		result |= (byte & 0x7F) << shift
		if (byte & 0x80) == 0:
			return result
		shift += 7
	push_error("Varint decoding failed: incomplete byte sequence.")
	return -1

# Read a String (length-delimited, wire type 2)
func get_string() -> String:
	var length = get_varint()  # Get the string length
	if position + length > buffer.size():
		push_error("String decoding failed: buffer overread.")
		return ""
	var str_data = buffer.slice(position, position + length)
	position += length
	return str_data.get_string_from_utf8()

# Read an Integer (varint, wire type 0)
func get_int() -> int:
	return get_varint()  # Just use the varint reading method for integers

# Read a Byte (fixed size, wire type 5)
func get_byte() -> int:
	if position < buffer.size():
		var byte: int = buffer[position]
		position += 1
		return byte
	push_error("Byte decoding failed: buffer overread.")
	return -1

# Read a Double (wire type 1 for 64-bit fixed size)
func get_double() -> float:
	if position + 8 > buffer.size():
		push_error("Double decoding failed: buffer overread.")
		return 0.0
	var double_bytes = buffer.slice(position, position + 8)
	position += 8
	return ProtocolUtils.bytes_to_float64(double_bytes)

# Reset buffer and position
func clear():
	buffer = PackedByteArray()
	position = 0
