extends Object

var cmd_id: int
var payload: PackedByteArray

# Serialize the object into a PackedByteArray
func serialize() -> PackedByteArray:
	var buffer = PackedByteArray()
	
	# Field 1: cmd_id (field number 1, wire type 0)
	var field1_key = (1 << 3) | 0  # Field number 1, wire type 0
	buffer.append(field1_key)  # Add field key
	buffer.append_array(_serialize_varint(cmd_id))  # Add cmd_id as varint
	
	# Field 2: payload (field number 2, wire type 2)
	var field2_key = (2 << 3) | 2  # Field number 2, wire type 2
	buffer.append(field2_key)  # Add field key
	buffer.append_array(_serialize_length_delimited(payload))  # Add payload with length prefix
	
	return buffer

# Parse the PackedByteArray and populate the object
func parse(data: PackedByteArray) -> void:
	var offset = 0
	while offset < data.size():
		# Read the field key (field number + wire type)
		var field_key = int(data[offset])
		offset += 1
		
		# Parse based on field number and wire type
		var field_number = field_key >> 3  # Field number (3 bits)
		var wire_type = field_key & 0x07   # Wire type (3 bits)
		
		if field_number == 1 and wire_type == 0:  # cmd_id (varint)
			var result = _parse_varint(data, offset)
			cmd_id = result[0]
			offset = result[1]
		elif field_number == 2 and wire_type == 2:  # payload (length-delimited)
			var result = _parse_length_delimited(data, offset)
			payload = result[0]
			offset = result[1]
		else:
			push_error("Unknown field or wire type. Skipping.")
			break
			
# Helper: Serialize a varint
func _serialize_varint(value: int) -> PackedByteArray:
	var buffer = PackedByteArray()
	while value > 0x7F:
		buffer.append((value & 0x7F) | 0x80)  # Append lower 7 bits with continuation bit
		value >>= 7
	buffer.append(value)  # Append last 7 bits
	return buffer

# Helper: Parse a varint
func _parse_varint(data: PackedByteArray, offset: int) -> Array:
	var value = 0
	var shift = 0
	while offset < data.size():
		var byte = data[offset]
		offset += 1
		value |= (byte & 0x7F) << shift
		if (byte & 0x80) == 0:  # Last byte
			break
		shift += 7
	return [value, offset]

# Helper: Serialize a length-delimited field (e.g., payload)
func _serialize_length_delimited(value: PackedByteArray) -> PackedByteArray:
	var buffer = PackedByteArray()
	buffer.append_array(_serialize_varint(value.size()))  # Add length as varint
	buffer.append_array(value)  # Add actual bytes
	return buffer

# Helper: Parse a length-delimited field
func _parse_length_delimited(data: PackedByteArray, offset: int) -> Array:
	var result = _parse_varint(data, offset)
	var length = result[0]
	offset = result[1]
	if offset + length > data.size():
		push_error("Error: Length-delimited field exceeds data size.")
		return [PackedByteArray(), offset]
	var value = data.slice(offset, offset + length)  # Extract payload
	offset += length
	return [value, offset]
