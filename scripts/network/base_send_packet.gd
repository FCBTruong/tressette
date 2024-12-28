extends Object

class_name BaseSendPacket

var buffer: PackedByteArray
var position: int
var field_number: int

# Constructor, initializes the buffer and position
func _init():
	buffer = PackedByteArray()
	position = 0
	field_number = 1  # Start field numbering at 1

# Write a Varint (used for integers in Protocol Buffers)
func put_varint(value: int):
	while value >= 0x80:
		buffer.append((value & 0x7F) | 0x80)
		value >>= 7
	buffer.append(value)

# Write a String (length-delimited, wire type 2)
func put_string(value: String) -> void:
	print('put string', field_number)
	# Convert string to UTF-8 encoded bytes
	var str_bytes = value.to_utf8_buffer()
	var str_length = str_bytes.size()
	
	# Construct field key: (field_number << 3) | wire_type (wire_type = 2 for length-delimited)
	var field_key = (field_number << 3) | 2
	buffer.append(field_key)  # Append the field key
	
	# Append the length of the string (varint encoding)
	while str_length > 127:
		buffer.append((str_length & 0x7F) | 0x80)
		str_length >>= 7
	buffer.append(str_length)  # Append the final byte of the varint length
	
	# Append the actual string data
	buffer.append_array(str_bytes)
	field_number += 1
	
# Write an Integer (varint, wire type 0)
func put_int(value: int):
	var field_key = (field_number << 3) | 0  # Wire type 0 for varint
	buffer.append(field_key)  # Append the field key
	put_varint(value)  # Serialize value as varint
	field_number += 1  # Increment field number for the next field

# Write a Byte (fixed size, wire type 5)
func put_byte(value: int):
	var field_key = (field_number << 3) | 5  # Wire type 5 for 32-bit fixed size
	buffer.append(field_key)  # Append the field key
	buffer.append(value)  # Append the byte value
	field_number += 1  # Increment field number for the next field

# Write a Double (wire type 1 for 64-bit fixed size)
func put_double(value: float):
	var field_key = (field_number << 3) | 1  # Wire type 1 for 64-bit fixed size
	buffer.append(field_key)  # Append the field key
	var double_bytes = ProtocolUtils.float64_to_bytes(value)
	buffer.append_array(double_bytes)  # Append the actual double data
	field_number += 1  # Increment field number for the next field


# Reset buffer and position
func clear():
	buffer = PackedByteArray()
	position = 0
