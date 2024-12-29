extends Object

class_name BaseReceivePacket

var buffer: PackedByteArray
var position: int

# Constructor, initializes the buffer and position
func _init(p_buffer: PackedByteArray):
	buffer = p_buffer
	position = 0

# Read a Varint (used for integers in Protocol Buffers)
func get_varint() -> int:
	var result: int = 0
	var shift: int = 0
	var bytes_read: int = 0
	while position < buffer.size():
		var byte: int = buffer[position]
		position += 1
		bytes_read += 1
		result |= (byte & 0x7F) << shift
		if (byte & 0x80) == 0:
			return result
		shift += 7
		if bytes_read > 10:
			push_error("Varint decoding failed: Malformed varint")
			return -1
	push_error("Varint decoding failed: incomplete byte sequence.")
	return -1

# Function to get tag
func get_tag() -> Dictionary:
	if position >= buffer.size():
		return {}  # Return empty dictionary for no more data

	var tag = get_varint()
	if tag == -1:
		return {}  # Return empty dictionary for error

	var field_number = tag >> 3
	var wire_type = tag & 0x7
	
	return {"field_number": field_number, "wire_type": wire_type}
		

# Read a String (length-delimited, wire type 2)
func get_string() -> String:
	var tag = get_tag()
	if not tag or tag.wire_type != 2:
		skip_field(tag.wire_type)
		return ""
	
	var length = get_varint()  # Get the string length
	if length == -1:
		return ""

	if position + length > buffer.size():
		push_error("String decoding failed: buffer overread.")
		return ""
	var str_data = buffer.slice(position, position + length)
	position += length
	return str_data.get_string_from_utf8()


# Read an Integer (varint, wire type 0)
func get_int32() -> int:
	var tag = get_tag()
	if not tag or tag.wire_type != 0:
		if tag.has("wire_type"):
			skip_field(tag.wire_type)
		else:
			skip_field(-1)
		return 0
	return get_varint()

# Read an Integer (varint, wire type 0)
func get_int64() -> int:
	var tag = get_tag()
	if not tag or tag.wire_type != 0:
		if tag.has("wire_type"):
			skip_field(tag.wire_type)
		else:
			skip_field(-1)
		return 0
	return get_varint()


# Skip unknown field
func skip_field(wire_type: int):
	match wire_type:
		0: # varint
			get_varint()
		1: # 64-bit
			position += 8
		2: # length delimited
			var length = get_varint()
			if length != -1:
				position += length
		5: # 32-bit
			position += 4
		_:
			push_error("Skipping: unknown wiretype")
			return


# Read a Double (wire type 1 for 64-bit fixed size)
func get_double() -> float:
	var tag = get_tag()
	if not tag or tag.wire_type != 1:
		skip_field(tag.wire_type)
		return 0.0
	
	if position + 8 > buffer.size():
		push_error("Double decoding failed: buffer overread.")
		return 0.0
	var double_bytes = buffer.slice(position, position + 8)
	position += 8
	return ProtocolUtils.bytes_to_double(double_bytes)

# Read a Bool (varint, wire type 0)
func get_bool() -> bool:
	var tag = get_tag()
	if not tag or tag.wire_type != 0:
		skip_field(tag.wire_type)
		return false
	var int_value := get_varint()
	return int_value != 0

func get_int32s() -> Array[int]:
	var len = get_int32()
	var arr = []
	for i in range(len):
		var n = get_int32()
		arr.append(n)
	return arr
	
func get_int64s() -> Array[int]:
	var len = get_int32()
	var arr = []
	for i in range(len):
		var n = get_int64()
		arr.append(n)
	return arr
	
func get_strings() -> Array[String]:
	var len = get_int32()
	var arr = []
	for i in range(len):
		var n = get_string()
		arr.append(n)
	return arr

# Reset buffer and position
func clear():
	buffer = PackedByteArray()
	position = 0
