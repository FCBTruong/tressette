#
# BSD 3-Clause License
#
# Copyright (c) 2018 - 2023, Oleg Malyavkin
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
#   list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice,
#   this list of conditions and the following disclaimer in the documentation
#   and/or other materials provided with the distribution.
#
# * Neither the name of the copyright holder nor the names of its
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# DEBUG_TAB redefine this "  " if you need, example: const DEBUG_TAB = "\t"

const PROTO_VERSION = 3

const DEBUG_TAB : String = "  "

enum PB_ERR {
	NO_ERRORS = 0,
	VARINT_NOT_FOUND = -1,
	REPEATED_COUNT_NOT_FOUND = -2,
	REPEATED_COUNT_MISMATCH = -3,
	LENGTHDEL_SIZE_NOT_FOUND = -4,
	LENGTHDEL_SIZE_MISMATCH = -5,
	PACKAGE_SIZE_MISMATCH = -6,
	UNDEFINED_STATE = -7,
	PARSE_INCOMPLETE = -8,
	REQUIRED_FIELDS = -9
}

enum PB_DATA_TYPE {
	INT32 = 0,
	SINT32 = 1,
	UINT32 = 2,
	INT64 = 3,
	SINT64 = 4,
	UINT64 = 5,
	BOOL = 6,
	ENUM = 7,
	FIXED32 = 8,
	SFIXED32 = 9,
	FLOAT = 10,
	FIXED64 = 11,
	SFIXED64 = 12,
	DOUBLE = 13,
	STRING = 14,
	BYTES = 15,
	MESSAGE = 16,
	MAP = 17
}

const DEFAULT_VALUES_2 = {
	PB_DATA_TYPE.INT32: null,
	PB_DATA_TYPE.SINT32: null,
	PB_DATA_TYPE.UINT32: null,
	PB_DATA_TYPE.INT64: null,
	PB_DATA_TYPE.SINT64: null,
	PB_DATA_TYPE.UINT64: null,
	PB_DATA_TYPE.BOOL: null,
	PB_DATA_TYPE.ENUM: null,
	PB_DATA_TYPE.FIXED32: null,
	PB_DATA_TYPE.SFIXED32: null,
	PB_DATA_TYPE.FLOAT: null,
	PB_DATA_TYPE.FIXED64: null,
	PB_DATA_TYPE.SFIXED64: null,
	PB_DATA_TYPE.DOUBLE: null,
	PB_DATA_TYPE.STRING: null,
	PB_DATA_TYPE.BYTES: null,
	PB_DATA_TYPE.MESSAGE: null,
	PB_DATA_TYPE.MAP: null
}

const DEFAULT_VALUES_3 = {
	PB_DATA_TYPE.INT32: 0,
	PB_DATA_TYPE.SINT32: 0,
	PB_DATA_TYPE.UINT32: 0,
	PB_DATA_TYPE.INT64: 0,
	PB_DATA_TYPE.SINT64: 0,
	PB_DATA_TYPE.UINT64: 0,
	PB_DATA_TYPE.BOOL: false,
	PB_DATA_TYPE.ENUM: 0,
	PB_DATA_TYPE.FIXED32: 0,
	PB_DATA_TYPE.SFIXED32: 0,
	PB_DATA_TYPE.FLOAT: 0.0,
	PB_DATA_TYPE.FIXED64: 0,
	PB_DATA_TYPE.SFIXED64: 0,
	PB_DATA_TYPE.DOUBLE: 0.0,
	PB_DATA_TYPE.STRING: "",
	PB_DATA_TYPE.BYTES: [],
	PB_DATA_TYPE.MESSAGE: null,
	PB_DATA_TYPE.MAP: []
}

enum PB_TYPE {
	VARINT = 0,
	FIX64 = 1,
	LENGTHDEL = 2,
	STARTGROUP = 3,
	ENDGROUP = 4,
	FIX32 = 5,
	UNDEFINED = 8
}

enum PB_RULE {
	OPTIONAL = 0,
	REQUIRED = 1,
	REPEATED = 2,
	RESERVED = 3
}

enum PB_SERVICE_STATE {
	FILLED = 0,
	UNFILLED = 1
}

class PBField:
	func _init(a_name : String, a_type : int, a_rule : int, a_tag : int, packed : bool, a_value = null):
		name = a_name
		type = a_type
		rule = a_rule
		tag = a_tag
		option_packed = packed
		value = a_value
		
	var name : String
	var type : int
	var rule : int
	var tag : int
	var option_packed : bool
	var value
	var is_map_field : bool = false
	var option_default : bool = false

class PBTypeTag:
	var ok : bool = false
	var type : int
	var tag : int
	var offset : int

class PBServiceField:
	var field : PBField
	var func_ref = null
	var state : int = PB_SERVICE_STATE.UNFILLED

class PBPacker:
	static func convert_signed(n : int) -> int:
		if n < -2147483648:
			return (n << 1) ^ (n >> 63)
		else:
			return (n << 1) ^ (n >> 31)

	static func deconvert_signed(n : int) -> int:
		if n & 0x01:
			return ~(n >> 1)
		else:
			return (n >> 1)

	static func pack_varint(value) -> PackedByteArray:
		var varint : PackedByteArray = PackedByteArray()
		if typeof(value) == TYPE_BOOL:
			if value:
				value = 1
			else:
				value = 0
		for _i in range(9):
			var b = value & 0x7F
			value >>= 7
			if value:
				varint.append(b | 0x80)
			else:
				varint.append(b)
				break
		if varint.size() == 9 && varint[8] == 0xFF:
			varint.append(0x01)
		return varint

	static func pack_bytes(value, count : int, data_type : int) -> PackedByteArray:
		var bytes : PackedByteArray = PackedByteArray()
		if data_type == PB_DATA_TYPE.FLOAT:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			spb.put_float(value)
			bytes = spb.get_data_array()
		elif data_type == PB_DATA_TYPE.DOUBLE:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			spb.put_double(value)
			bytes = spb.get_data_array()
		else:
			for _i in range(count):
				bytes.append(value & 0xFF)
				value >>= 8
		return bytes

	static func unpack_bytes(bytes : PackedByteArray, index : int, count : int, data_type : int):
		var value = 0
		if data_type == PB_DATA_TYPE.FLOAT:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			for i in range(index, count + index):
				spb.put_u8(bytes[i])
			spb.seek(0)
			value = spb.get_float()
		elif data_type == PB_DATA_TYPE.DOUBLE:
			var spb : StreamPeerBuffer = StreamPeerBuffer.new()
			for i in range(index, count + index):
				spb.put_u8(bytes[i])
			spb.seek(0)
			value = spb.get_double()
		else:
			for i in range(index + count - 1, index - 1, -1):
				value |= (bytes[i] & 0xFF)
				if i != index:
					value <<= 8
		return value

	static func unpack_varint(varint_bytes) -> int:
		var value : int = 0
		for i in range(varint_bytes.size() - 1, -1, -1):
			value |= varint_bytes[i] & 0x7F
			if i != 0:
				value <<= 7
		return value

	static func pack_type_tag(type : int, tag : int) -> PackedByteArray:
		return pack_varint((tag << 3) | type)

	static func isolate_varint(bytes : PackedByteArray, index : int) -> PackedByteArray:
		var result : PackedByteArray = PackedByteArray()
		for i in range(index, bytes.size()):
			result.append(bytes[i])
			if !(bytes[i] & 0x80):
				break
		return result

	static func unpack_type_tag(bytes : PackedByteArray, index : int) -> PBTypeTag:
		var varint_bytes : PackedByteArray = isolate_varint(bytes, index)
		var result : PBTypeTag = PBTypeTag.new()
		if varint_bytes.size() != 0:
			result.ok = true
			result.offset = varint_bytes.size()
			var unpacked : int = unpack_varint(varint_bytes)
			result.type = unpacked & 0x07
			result.tag = unpacked >> 3
		return result

	static func pack_length_delimeted(type : int, tag : int, bytes : PackedByteArray) -> PackedByteArray:
		var result : PackedByteArray = pack_type_tag(type, tag)
		result.append_array(pack_varint(bytes.size()))
		result.append_array(bytes)
		return result

	static func pb_type_from_data_type(data_type : int) -> int:
		if data_type == PB_DATA_TYPE.INT32 || data_type == PB_DATA_TYPE.SINT32 || data_type == PB_DATA_TYPE.UINT32 || data_type == PB_DATA_TYPE.INT64 || data_type == PB_DATA_TYPE.SINT64 || data_type == PB_DATA_TYPE.UINT64 || data_type == PB_DATA_TYPE.BOOL || data_type == PB_DATA_TYPE.ENUM:
			return PB_TYPE.VARINT
		elif data_type == PB_DATA_TYPE.FIXED32 || data_type == PB_DATA_TYPE.SFIXED32 || data_type == PB_DATA_TYPE.FLOAT:
			return PB_TYPE.FIX32
		elif data_type == PB_DATA_TYPE.FIXED64 || data_type == PB_DATA_TYPE.SFIXED64 || data_type == PB_DATA_TYPE.DOUBLE:
			return PB_TYPE.FIX64
		elif data_type == PB_DATA_TYPE.STRING || data_type == PB_DATA_TYPE.BYTES || data_type == PB_DATA_TYPE.MESSAGE || data_type == PB_DATA_TYPE.MAP:
			return PB_TYPE.LENGTHDEL
		else:
			return PB_TYPE.UNDEFINED

	static func pack_field(field : PBField) -> PackedByteArray:
		var type : int = pb_type_from_data_type(field.type)
		var type_copy : int = type
		if field.rule == PB_RULE.REPEATED && field.option_packed:
			type = PB_TYPE.LENGTHDEL
		var head : PackedByteArray = pack_type_tag(type, field.tag)
		var data : PackedByteArray = PackedByteArray()
		if type == PB_TYPE.VARINT:
			var value
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						value = convert_signed(v)
					else:
						value = v
					data.append_array(pack_varint(value))
				return data
			else:
				if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
					value = convert_signed(field.value)
				else:
					value = field.value
				data = pack_varint(value)
		elif type == PB_TYPE.FIX32:
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					data.append_array(pack_bytes(v, 4, field.type))
				return data
			else:
				data.append_array(pack_bytes(field.value, 4, field.type))
		elif type == PB_TYPE.FIX64:
			if field.rule == PB_RULE.REPEATED:
				for v in field.value:
					data.append_array(head)
					data.append_array(pack_bytes(v, 8, field.type))
				return data
			else:
				data.append_array(pack_bytes(field.value, 8, field.type))
		elif type == PB_TYPE.LENGTHDEL:
			if field.rule == PB_RULE.REPEATED:
				if type_copy == PB_TYPE.VARINT:
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						var signed_value : int
						for v in field.value:
							signed_value = convert_signed(v)
							data.append_array(pack_varint(signed_value))
					else:
						for v in field.value:
							data.append_array(pack_varint(v))
					return pack_length_delimeted(type, field.tag, data)
				elif type_copy == PB_TYPE.FIX32:
					for v in field.value:
						data.append_array(pack_bytes(v, 4, field.type))
					return pack_length_delimeted(type, field.tag, data)
				elif type_copy == PB_TYPE.FIX64:
					for v in field.value:
						data.append_array(pack_bytes(v, 8, field.type))
					return pack_length_delimeted(type, field.tag, data)
				elif field.type == PB_DATA_TYPE.STRING:
					for v in field.value:
						var obj = v.to_utf8_buffer()
						data.append_array(pack_length_delimeted(type, field.tag, obj))
					return data
				elif field.type == PB_DATA_TYPE.BYTES:
					for v in field.value:
						data.append_array(pack_length_delimeted(type, field.tag, v))
					return data
				elif typeof(field.value[0]) == TYPE_OBJECT:
					for v in field.value:
						var obj : PackedByteArray = v.to_bytes()
						data.append_array(pack_length_delimeted(type, field.tag, obj))
					return data
			else:
				if field.type == PB_DATA_TYPE.STRING:
					var str_bytes : PackedByteArray = field.value.to_utf8_buffer()
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && str_bytes.size() > 0):
						data.append_array(str_bytes)
						return pack_length_delimeted(type, field.tag, data)
				if field.type == PB_DATA_TYPE.BYTES:
					if PROTO_VERSION == 2 || (PROTO_VERSION == 3 && field.value.size() > 0):
						data.append_array(field.value)
						return pack_length_delimeted(type, field.tag, data)
				elif typeof(field.value) == TYPE_OBJECT:
					var obj : PackedByteArray = field.value.to_bytes()
					if obj.size() > 0:
						data.append_array(obj)
					return pack_length_delimeted(type, field.tag, data)
				else:
					pass
		if data.size() > 0:
			head.append_array(data)
			return head
		else:
			return data

	static func unpack_field(bytes : PackedByteArray, offset : int, field : PBField, type : int, message_func_ref) -> int:
		if field.rule == PB_RULE.REPEATED && type != PB_TYPE.LENGTHDEL && field.option_packed:
			var count = isolate_varint(bytes, offset)
			if count.size() > 0:
				offset += count.size()
				count = unpack_varint(count)
				if type == PB_TYPE.VARINT:
					var val
					var counter = offset + count
					while offset < counter:
						val = isolate_varint(bytes, offset)
						if val.size() > 0:
							offset += val.size()
							val = unpack_varint(val)
							if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
								val = deconvert_signed(val)
							elif field.type == PB_DATA_TYPE.BOOL:
								if val:
									val = true
								else:
									val = false
							field.value.append(val)
						else:
							return PB_ERR.REPEATED_COUNT_MISMATCH
					return offset
				elif type == PB_TYPE.FIX32 || type == PB_TYPE.FIX64:
					var type_size
					if type == PB_TYPE.FIX32:
						type_size = 4
					else:
						type_size = 8
					var val
					var counter = offset + count
					while offset < counter:
						if (offset + type_size) > bytes.size():
							return PB_ERR.REPEATED_COUNT_MISMATCH
						val = unpack_bytes(bytes, offset, type_size, field.type)
						offset += type_size
						field.value.append(val)
					return offset
			else:
				return PB_ERR.REPEATED_COUNT_NOT_FOUND
		else:
			if type == PB_TYPE.VARINT:
				var val = isolate_varint(bytes, offset)
				if val.size() > 0:
					offset += val.size()
					val = unpack_varint(val)
					if field.type == PB_DATA_TYPE.SINT32 || field.type == PB_DATA_TYPE.SINT64:
						val = deconvert_signed(val)
					elif field.type == PB_DATA_TYPE.BOOL:
						if val:
							val = true
						else:
							val = false
					if field.rule == PB_RULE.REPEATED:
						field.value.append(val)
					else:
						field.value = val
				else:
					return PB_ERR.VARINT_NOT_FOUND
				return offset
			elif type == PB_TYPE.FIX32 || type == PB_TYPE.FIX64:
				var type_size
				if type == PB_TYPE.FIX32:
					type_size = 4
				else:
					type_size = 8
				var val
				if (offset + type_size) > bytes.size():
					return PB_ERR.REPEATED_COUNT_MISMATCH
				val = unpack_bytes(bytes, offset, type_size, field.type)
				offset += type_size
				if field.rule == PB_RULE.REPEATED:
					field.value.append(val)
				else:
					field.value = val
				return offset
			elif type == PB_TYPE.LENGTHDEL:
				var inner_size = isolate_varint(bytes, offset)
				if inner_size.size() > 0:
					offset += inner_size.size()
					inner_size = unpack_varint(inner_size)
					if inner_size >= 0:
						if inner_size + offset > bytes.size():
							return PB_ERR.LENGTHDEL_SIZE_MISMATCH
						if message_func_ref != null:
							var message = message_func_ref.call()
							if inner_size > 0:
								var sub_offset = message.from_bytes(bytes, offset, inner_size + offset)
								if sub_offset > 0:
									if sub_offset - offset >= inner_size:
										offset = sub_offset
										return offset
									else:
										return PB_ERR.LENGTHDEL_SIZE_MISMATCH
								return sub_offset
							else:
								return offset
						elif field.type == PB_DATA_TYPE.STRING:
							var str_bytes : PackedByteArray = PackedByteArray()
							for i in range(offset, inner_size + offset):
								str_bytes.append(bytes[i])
							if field.rule == PB_RULE.REPEATED:
								field.value.append(str_bytes.get_string_from_utf8())
							else:
								field.value = str_bytes.get_string_from_utf8()
							return offset + inner_size
						elif field.type == PB_DATA_TYPE.BYTES:
							var val_bytes : PackedByteArray = PackedByteArray()
							for i in range(offset, inner_size + offset):
								val_bytes.append(bytes[i])
							if field.rule == PB_RULE.REPEATED:
								field.value.append(val_bytes)
							else:
								field.value = val_bytes
							return offset + inner_size
					else:
						return PB_ERR.LENGTHDEL_SIZE_NOT_FOUND
				else:
					return PB_ERR.LENGTHDEL_SIZE_NOT_FOUND
		return PB_ERR.UNDEFINED_STATE

	static func unpack_message(data, bytes : PackedByteArray, offset : int, limit : int) -> int:
		while true:
			var tt : PBTypeTag = unpack_type_tag(bytes, offset)
			if tt.ok:
				offset += tt.offset
				if data.has(tt.tag):
					var service : PBServiceField = data[tt.tag]
					var type : int = pb_type_from_data_type(service.field.type)
					if type == tt.type || (tt.type == PB_TYPE.LENGTHDEL && service.field.rule == PB_RULE.REPEATED && service.field.option_packed):
						var res : int = unpack_field(bytes, offset, service.field, type, service.func_ref)
						if res > 0:
							service.state = PB_SERVICE_STATE.FILLED
							offset = res
							if offset == limit:
								return offset
							elif offset > limit:
								return PB_ERR.PACKAGE_SIZE_MISMATCH
						elif res < 0:
							return res
						else:
							break
			else:
				return offset
		return PB_ERR.UNDEFINED_STATE

	static func pack_message(data) -> PackedByteArray:
		var DEFAULT_VALUES
		if PROTO_VERSION == 2:
			DEFAULT_VALUES = DEFAULT_VALUES_2
		elif PROTO_VERSION == 3:
			DEFAULT_VALUES = DEFAULT_VALUES_3
		var result : PackedByteArray = PackedByteArray()
		var keys : Array = data.keys()
		keys.sort()
		for i in keys:
			if data[i].field.value != null:
				if data[i].state == PB_SERVICE_STATE.UNFILLED \
				&& !data[i].field.is_map_field \
				&& typeof(data[i].field.value) == typeof(DEFAULT_VALUES[data[i].field.type]) \
				&& data[i].field.value == DEFAULT_VALUES[data[i].field.type]:
					continue
				elif data[i].field.rule == PB_RULE.REPEATED && data[i].field.value.size() == 0:
					continue
				result.append_array(pack_field(data[i].field))
			elif data[i].field.rule == PB_RULE.REQUIRED:
				print("Error: required field is not filled: Tag:", data[i].field.tag)
				return PackedByteArray()
		return result

	static func check_required(data) -> bool:
		var keys : Array = data.keys()
		for i in keys:
			if data[i].field.rule == PB_RULE.REQUIRED && data[i].state == PB_SERVICE_STATE.UNFILLED:
				return false
		return true

	static func construct_map(key_values):
		var result = {}
		for kv in key_values:
			result[kv.get_key()] = kv.get_value()
		return result
	
	static func tabulate(text : String, nesting : int) -> String:
		var tab : String = ""
		for _i in range(nesting):
			tab += DEBUG_TAB
		return tab + text
	
	static func value_to_string(value, field : PBField, nesting : int) -> String:
		var result : String = ""
		var text : String
		if field.type == PB_DATA_TYPE.MESSAGE:
			result += "{"
			nesting += 1
			text = message_to_string(value.data, nesting)
			if text != "":
				result += "\n" + text
				nesting -= 1
				result += tabulate("}", nesting)
			else:
				nesting -= 1
				result += "}"
		elif field.type == PB_DATA_TYPE.BYTES:
			result += "<"
			for i in range(value.size()):
				result += str(value[i])
				if i != (value.size() - 1):
					result += ", "
			result += ">"
		elif field.type == PB_DATA_TYPE.STRING:
			result += "\"" + value + "\""
		elif field.type == PB_DATA_TYPE.ENUM:
			result += "ENUM::" + str(value)
		else:
			result += str(value)
		return result
	
	static func field_to_string(field : PBField, nesting : int) -> String:
		var result : String = tabulate(field.name + ": ", nesting)
		if field.type == PB_DATA_TYPE.MAP:
			if field.value.size() > 0:
				result += "(\n"
				nesting += 1
				for i in range(field.value.size()):
					var local_key_value = field.value[i].data[1].field
					result += tabulate(value_to_string(local_key_value.value, local_key_value, nesting), nesting) + ": "
					local_key_value = field.value[i].data[2].field
					result += value_to_string(local_key_value.value, local_key_value, nesting)
					if i != (field.value.size() - 1):
						result += ","
					result += "\n"
				nesting -= 1
				result += tabulate(")", nesting)
			else:
				result += "()"
		elif field.rule == PB_RULE.REPEATED:
			if field.value.size() > 0:
				result += "[\n"
				nesting += 1
				for i in range(field.value.size()):
					result += tabulate(str(i) + ": ", nesting)
					result += value_to_string(field.value[i], field, nesting)
					if i != (field.value.size() - 1):
						result += ","
					result += "\n"
				nesting -= 1
				result += tabulate("]", nesting)
			else:
				result += "[]"
		else:
			result += value_to_string(field.value, field, nesting)
		result += ";\n"
		return result
		
	static func message_to_string(data, nesting : int = 0) -> String:
		var DEFAULT_VALUES
		if PROTO_VERSION == 2:
			DEFAULT_VALUES = DEFAULT_VALUES_2
		elif PROTO_VERSION == 3:
			DEFAULT_VALUES = DEFAULT_VALUES_3
		var result : String = ""
		var keys : Array = data.keys()
		keys.sort()
		for i in keys:
			if data[i].field.value != null:
				if data[i].state == PB_SERVICE_STATE.UNFILLED \
				&& !data[i].field.is_map_field \
				&& typeof(data[i].field.value) == typeof(DEFAULT_VALUES[data[i].field.type]) \
				&& data[i].field.value == DEFAULT_VALUES[data[i].field.type]:
					continue
				elif data[i].field.rule == PB_RULE.REPEATED && data[i].field.value.size() == 0:
					continue
				result += field_to_string(data[i].field, nesting)
			elif data[i].field.rule == PB_RULE.REQUIRED:
				result += data[i].field.name + ": " + "error"
		return result



############### USER DATA BEGIN ################


class Empty:
	func _init():
		var service
		
	var data = {}
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class Packet:
	func _init():
		var service
		
		_token = PBField.new("token", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _token
		data[_token.tag] = service
		
		_cmd_id = PBField.new("cmd_id", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _cmd_id
		data[_cmd_id.tag] = service
		
		_payload = PBField.new("payload", PB_DATA_TYPE.BYTES, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES])
		service = PBServiceField.new()
		service.field = _payload
		data[_payload.tag] = service
		
	var data = {}
	
	var _token: PBField
	func get_token() -> String:
		return _token.value
	func clear_token() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_token.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_token(value : String) -> void:
		_token.value = value
	
	var _cmd_id: PBField
	func get_cmd_id() -> int:
		return _cmd_id.value
	func clear_cmd_id() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_cmd_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_cmd_id(value : int) -> void:
		_cmd_id.value = value
	
	var _payload: PBField
	func get_payload() -> PackedByteArray:
		return _payload.value
	func clear_payload() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_payload.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BYTES]
	func set_payload(value : PackedByteArray) -> void:
		_payload.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class ChatMessage:
	func _init():
		var service
		
		_abc = PBField.new("abc", PB_DATA_TYPE.DOUBLE, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.DOUBLE])
		service = PBServiceField.new()
		service.field = _abc
		data[_abc.tag] = service
		
		_username = PBField.new("username", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _username
		data[_username.tag] = service
		
		_level = PBField.new("level", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = _level
		data[_level.tag] = service
		
		_gold = PBField.new("gold", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = _gold
		data[_gold.tag] = service
		
		_abcd = PBField.new("abcd", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _abcd
		data[_abcd.tag] = service
		
		_is_active = PBField.new("is_active", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _is_active
		data[_is_active.tag] = service
		
	var data = {}
	
	var _abc: PBField
	func get_abc() -> float:
		return _abc.value
	func clear_abc() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_abc.value = DEFAULT_VALUES_3[PB_DATA_TYPE.DOUBLE]
	func set_abc(value : float) -> void:
		_abc.value = value
	
	var _username: PBField
	func get_username() -> String:
		return _username.value
	func clear_username() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_username.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_username(value : String) -> void:
		_username.value = value
	
	var _level: PBField
	func get_level() -> int:
		return _level.value
	func clear_level() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_level.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_level(value : int) -> void:
		_level.value = value
	
	var _gold: PBField
	func get_gold() -> int:
		return _gold.value
	func clear_gold() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_gold.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_gold(value : int) -> void:
		_gold.value = value
	
	var _abcd: PBField
	func get_abcd() -> String:
		return _abcd.value
	func clear_abcd() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_abcd.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_abcd(value : String) -> void:
		_abcd.value = value
	
	var _is_active: PBField
	func get_is_active() -> bool:
		return _is_active.value
	func clear_is_active() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_is_active.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_is_active(value : bool) -> void:
		_is_active.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PingPong:
	func _init():
		var service
		
	var data = {}
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class Login:
	func _init():
		var service
		
		_type = PBField.new("type", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _type
		data[_type.tag] = service
		
		_token = PBField.new("token", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _token
		data[_token.tag] = service
		
		_device_model = PBField.new("device_model", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _device_model
		data[_device_model.tag] = service
		
		_platform = PBField.new("platform", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _platform
		data[_platform.tag] = service
		
		_device_country = PBField.new("device_country", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _device_country
		data[_device_country.tag] = service
		
		_app_version_code = PBField.new("app_version_code", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _app_version_code
		data[_app_version_code.tag] = service
		
	var data = {}
	
	var _type: PBField
	func get_type() -> int:
		return _type.value
	func clear_type() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_type.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_type(value : int) -> void:
		_type.value = value
	
	var _token: PBField
	func get_token() -> String:
		return _token.value
	func clear_token() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_token.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_token(value : String) -> void:
		_token.value = value
	
	var _device_model: PBField
	func get_device_model() -> String:
		return _device_model.value
	func clear_device_model() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_device_model.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_device_model(value : String) -> void:
		_device_model.value = value
	
	var _platform: PBField
	func get_platform() -> String:
		return _platform.value
	func clear_platform() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_platform.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_platform(value : String) -> void:
		_platform.value = value
	
	var _device_country: PBField
	func get_device_country() -> String:
		return _device_country.value
	func clear_device_country() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_device_country.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_device_country(value : String) -> void:
		_device_country.value = value
	
	var _app_version_code: PBField
	func get_app_version_code() -> int:
		return _app_version_code.value
	func clear_app_version_code() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_app_version_code.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_app_version_code(value : int) -> void:
		_app_version_code.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class LoginFirebase:
	func _init():
		var service
		
		_sub_type = PBField.new("sub_type", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _sub_type
		data[_sub_type.tag] = service
		
		_login_token = PBField.new("login_token", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _login_token
		data[_login_token.tag] = service
		
		_guest_id = PBField.new("guest_id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _guest_id
		data[_guest_id.tag] = service
		
	var data = {}
	
	var _sub_type: PBField
	func get_sub_type() -> int:
		return _sub_type.value
	func clear_sub_type() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_sub_type.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_sub_type(value : int) -> void:
		_sub_type.value = value
	
	var _login_token: PBField
	func get_login_token() -> String:
		return _login_token.value
	func clear_login_token() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_login_token.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_login_token(value : String) -> void:
		_login_token.value = value
	
	var _guest_id: PBField
	func get_guest_id() -> String:
		return _guest_id.value
	func clear_guest_id() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_guest_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_guest_id(value : String) -> void:
		_guest_id.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class Logout:
	func _init():
		var service
		
	var data = {}
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class LoginResponse:
	func _init():
		var service
		
		_uid = PBField.new("uid", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _uid
		data[_uid.tag] = service
		
		_token = PBField.new("token", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _token
		data[_token.tag] = service
		
		_error = PBField.new("error", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _error
		data[_error.tag] = service
		
	var data = {}
	
	var _uid: PBField
	func get_uid() -> int:
		return _uid.value
	func clear_uid() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_uid(value : int) -> void:
		_uid.value = value
	
	var _token: PBField
	func get_token() -> String:
		return _token.value
	func clear_token() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_token.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_token(value : String) -> void:
		_token.value = value
	
	var _error: PBField
	func get_error() -> int:
		return _error.value
	func clear_error() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_error.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_error(value : int) -> void:
		_error.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class UserInfo:
	func _init():
		var service
		
		_uid = PBField.new("uid", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _uid
		data[_uid.tag] = service
		
		_name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _name
		data[_name.tag] = service
		
		_gold = PBField.new("gold", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = _gold
		data[_gold.tag] = service
		
		_scores = PBField.new("scores", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 4, true, [])
		service = PBServiceField.new()
		service.field = _scores
		data[_scores.tag] = service
		
		_names = PBField.new("names", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 5, true, [])
		service = PBServiceField.new()
		service.field = _names
		data[_names.tag] = service
		
		_abc = PBField.new("abc", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _abc
		data[_abc.tag] = service
		
		_avatar = PBField.new("avatar", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _avatar
		data[_avatar.tag] = service
		
		_avatar_third_party = PBField.new("avatar_third_party", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _avatar_third_party
		data[_avatar_third_party.tag] = service
		
		_level = PBField.new("level", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _level
		data[_level.tag] = service
		
		_support_num = PBField.new("support_num", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _support_num
		data[_support_num.tag] = service
		
		_win_count = PBField.new("win_count", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 11, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _win_count
		data[_win_count.tag] = service
		
		_game_count = PBField.new("game_count", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 12, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _game_count
		data[_game_count.tag] = service
		
		_exp = PBField.new("exp", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 13, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = _exp
		data[_exp.tag] = service
		
		_startup_gold = PBField.new("startup_gold", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 14, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _startup_gold
		data[_startup_gold.tag] = service
		
		_has_first_buy = PBField.new("has_first_buy", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 15, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _has_first_buy
		data[_has_first_buy.tag] = service
		
		_time_show_ads = PBField.new("time_show_ads", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 16, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _time_show_ads
		data[_time_show_ads.tag] = service
		
		_login_type = PBField.new("login_type", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 17, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _login_type
		data[_login_type.tag] = service
		
		_time_ads_reward = PBField.new("time_ads_reward", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 18, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _time_ads_reward
		data[_time_ads_reward.tag] = service
		
	var data = {}
	
	var _uid: PBField
	func get_uid() -> int:
		return _uid.value
	func clear_uid() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_uid(value : int) -> void:
		_uid.value = value
	
	var _name: PBField
	func get_name() -> String:
		return _name.value
	func clear_name() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		_name.value = value
	
	var _gold: PBField
	func get_gold() -> int:
		return _gold.value
	func clear_gold() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_gold.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_gold(value : int) -> void:
		_gold.value = value
	
	var _scores: PBField
	func get_scores() -> Array:
		return _scores.value
	func clear_scores() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_scores.value = []
	func add_scores(value : int) -> void:
		_scores.value.append(value)
	
	var _names: PBField
	func get_names() -> Array:
		return _names.value
	func clear_names() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_names.value = []
	func add_names(value : String) -> void:
		_names.value.append(value)
	
	var _abc: PBField
	func get_abc() -> int:
		return _abc.value
	func clear_abc() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_abc.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_abc(value : int) -> void:
		_abc.value = value
	
	var _avatar: PBField
	func get_avatar() -> String:
		return _avatar.value
	func clear_avatar() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_avatar.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_avatar(value : String) -> void:
		_avatar.value = value
	
	var _avatar_third_party: PBField
	func get_avatar_third_party() -> String:
		return _avatar_third_party.value
	func clear_avatar_third_party() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_avatar_third_party.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_avatar_third_party(value : String) -> void:
		_avatar_third_party.value = value
	
	var _level: PBField
	func get_level() -> int:
		return _level.value
	func clear_level() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_level.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_level(value : int) -> void:
		_level.value = value
	
	var _support_num: PBField
	func get_support_num() -> int:
		return _support_num.value
	func clear_support_num() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		_support_num.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_support_num(value : int) -> void:
		_support_num.value = value
	
	var _win_count: PBField
	func get_win_count() -> int:
		return _win_count.value
	func clear_win_count() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
		_win_count.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_win_count(value : int) -> void:
		_win_count.value = value
	
	var _game_count: PBField
	func get_game_count() -> int:
		return _game_count.value
	func clear_game_count() -> void:
		data[12].state = PB_SERVICE_STATE.UNFILLED
		_game_count.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_game_count(value : int) -> void:
		_game_count.value = value
	
	var _exp: PBField
	func get_exp() -> int:
		return _exp.value
	func clear_exp() -> void:
		data[13].state = PB_SERVICE_STATE.UNFILLED
		_exp.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_exp(value : int) -> void:
		_exp.value = value
	
	var _startup_gold: PBField
	func get_startup_gold() -> int:
		return _startup_gold.value
	func clear_startup_gold() -> void:
		data[14].state = PB_SERVICE_STATE.UNFILLED
		_startup_gold.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_startup_gold(value : int) -> void:
		_startup_gold.value = value
	
	var _has_first_buy: PBField
	func get_has_first_buy() -> bool:
		return _has_first_buy.value
	func clear_has_first_buy() -> void:
		data[15].state = PB_SERVICE_STATE.UNFILLED
		_has_first_buy.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_has_first_buy(value : bool) -> void:
		_has_first_buy.value = value
	
	var _time_show_ads: PBField
	func get_time_show_ads() -> int:
		return _time_show_ads.value
	func clear_time_show_ads() -> void:
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_time_show_ads.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_time_show_ads(value : int) -> void:
		_time_show_ads.value = value
	
	var _login_type: PBField
	func get_login_type() -> int:
		return _login_type.value
	func clear_login_type() -> void:
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_login_type.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_login_type(value : int) -> void:
		_login_type.value = value
	
	var _time_ads_reward: PBField
	func get_time_ads_reward() -> int:
		return _time_ads_reward.value
	func clear_time_ads_reward() -> void:
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_time_ads_reward.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_time_ads_reward(value : int) -> void:
		_time_ads_reward.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class GameInfo:
	func _init():
		var service
		
		_match_id = PBField.new("match_id", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _match_id
		data[_match_id.tag] = service
		
		_game_mode = PBField.new("game_mode", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _game_mode
		data[_game_mode.tag] = service
		
		_player_mode = PBField.new("player_mode", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _player_mode
		data[_player_mode.tag] = service
		
		_uids = PBField.new("uids", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 4, true, [])
		service = PBServiceField.new()
		service.field = _uids
		data[_uids.tag] = service
		
		_user_golds = PBField.new("user_golds", PB_DATA_TYPE.INT64, PB_RULE.REPEATED, 5, true, [])
		service = PBServiceField.new()
		service.field = _user_golds
		data[_user_golds.tag] = service
		
		_user_names = PBField.new("user_names", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 6, true, [])
		service = PBServiceField.new()
		service.field = _user_names
		data[_user_names.tag] = service
		
		_cards_compare = PBField.new("cards_compare", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 7, true, [])
		service = PBServiceField.new()
		service.field = _cards_compare
		data[_cards_compare.tag] = service
		
		_current_turn = PBField.new("current_turn", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _current_turn
		data[_current_turn.tag] = service
		
		_game_state = PBField.new("game_state", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _game_state
		data[_game_state.tag] = service
		
		_my_cards = PBField.new("my_cards", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 10, true, [])
		service = PBServiceField.new()
		service.field = _my_cards
		data[_my_cards.tag] = service
		
		_remain_cards = PBField.new("remain_cards", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 11, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _remain_cards
		data[_remain_cards.tag] = service
		
		_user_points = PBField.new("user_points", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 12, true, [])
		service = PBServiceField.new()
		service.field = _user_points
		data[_user_points.tag] = service
		
		_team_ids = PBField.new("team_ids", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 13, true, [])
		service = PBServiceField.new()
		service.field = _team_ids
		data[_team_ids.tag] = service
		
		_hand_suit = PBField.new("hand_suit", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 14, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _hand_suit
		data[_hand_suit.tag] = service
		
		_avatars = PBField.new("avatars", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 15, true, [])
		service = PBServiceField.new()
		service.field = _avatars
		data[_avatars.tag] = service
		
		_is_registered_leave = PBField.new("is_registered_leave", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 16, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _is_registered_leave
		data[_is_registered_leave.tag] = service
		
		_bet = PBField.new("bet", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 17, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _bet
		data[_bet.tag] = service
		
		_pot_value = PBField.new("pot_value", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 18, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = _pot_value
		data[_pot_value.tag] = service
		
		_current_round = PBField.new("current_round", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 19, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _current_round
		data[_current_round.tag] = service
		
		_hand_in_round = PBField.new("hand_in_round", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 20, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _hand_in_round
		data[_hand_in_round.tag] = service
		
		_point_to_win = PBField.new("point_to_win", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 21, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _point_to_win
		data[_point_to_win.tag] = service
		
		_enable_bet_win_score = PBField.new("enable_bet_win_score", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 22, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _enable_bet_win_score
		data[_enable_bet_win_score.tag] = service
		
		_is_vips = PBField.new("is_vips", PB_DATA_TYPE.BOOL, PB_RULE.REPEATED, 23, true, [])
		service = PBServiceField.new()
		service.field = _is_vips
		data[_is_vips.tag] = service
		
	var data = {}
	
	var _match_id: PBField
	func get_match_id() -> int:
		return _match_id.value
	func clear_match_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_match_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_match_id(value : int) -> void:
		_match_id.value = value
	
	var _game_mode: PBField
	func get_game_mode() -> int:
		return _game_mode.value
	func clear_game_mode() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_game_mode.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_game_mode(value : int) -> void:
		_game_mode.value = value
	
	var _player_mode: PBField
	func get_player_mode() -> int:
		return _player_mode.value
	func clear_player_mode() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_player_mode.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_player_mode(value : int) -> void:
		_player_mode.value = value
	
	var _uids: PBField
	func get_uids() -> Array:
		return _uids.value
	func clear_uids() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_uids.value = []
	func add_uids(value : int) -> void:
		_uids.value.append(value)
	
	var _user_golds: PBField
	func get_user_golds() -> Array:
		return _user_golds.value
	func clear_user_golds() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_user_golds.value = []
	func add_user_golds(value : int) -> void:
		_user_golds.value.append(value)
	
	var _user_names: PBField
	func get_user_names() -> Array:
		return _user_names.value
	func clear_user_names() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_user_names.value = []
	func add_user_names(value : String) -> void:
		_user_names.value.append(value)
	
	var _cards_compare: PBField
	func get_cards_compare() -> Array:
		return _cards_compare.value
	func clear_cards_compare() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_cards_compare.value = []
	func add_cards_compare(value : int) -> void:
		_cards_compare.value.append(value)
	
	var _current_turn: PBField
	func get_current_turn() -> int:
		return _current_turn.value
	func clear_current_turn() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_current_turn.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_current_turn(value : int) -> void:
		_current_turn.value = value
	
	var _game_state: PBField
	func get_game_state() -> int:
		return _game_state.value
	func clear_game_state() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_game_state.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_game_state(value : int) -> void:
		_game_state.value = value
	
	var _my_cards: PBField
	func get_my_cards() -> Array:
		return _my_cards.value
	func clear_my_cards() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		_my_cards.value = []
	func add_my_cards(value : int) -> void:
		_my_cards.value.append(value)
	
	var _remain_cards: PBField
	func get_remain_cards() -> int:
		return _remain_cards.value
	func clear_remain_cards() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
		_remain_cards.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_remain_cards(value : int) -> void:
		_remain_cards.value = value
	
	var _user_points: PBField
	func get_user_points() -> Array:
		return _user_points.value
	func clear_user_points() -> void:
		data[12].state = PB_SERVICE_STATE.UNFILLED
		_user_points.value = []
	func add_user_points(value : int) -> void:
		_user_points.value.append(value)
	
	var _team_ids: PBField
	func get_team_ids() -> Array:
		return _team_ids.value
	func clear_team_ids() -> void:
		data[13].state = PB_SERVICE_STATE.UNFILLED
		_team_ids.value = []
	func add_team_ids(value : int) -> void:
		_team_ids.value.append(value)
	
	var _hand_suit: PBField
	func get_hand_suit() -> int:
		return _hand_suit.value
	func clear_hand_suit() -> void:
		data[14].state = PB_SERVICE_STATE.UNFILLED
		_hand_suit.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_hand_suit(value : int) -> void:
		_hand_suit.value = value
	
	var _avatars: PBField
	func get_avatars() -> Array:
		return _avatars.value
	func clear_avatars() -> void:
		data[15].state = PB_SERVICE_STATE.UNFILLED
		_avatars.value = []
	func add_avatars(value : String) -> void:
		_avatars.value.append(value)
	
	var _is_registered_leave: PBField
	func get_is_registered_leave() -> bool:
		return _is_registered_leave.value
	func clear_is_registered_leave() -> void:
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_is_registered_leave.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_is_registered_leave(value : bool) -> void:
		_is_registered_leave.value = value
	
	var _bet: PBField
	func get_bet() -> int:
		return _bet.value
	func clear_bet() -> void:
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_bet.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_bet(value : int) -> void:
		_bet.value = value
	
	var _pot_value: PBField
	func get_pot_value() -> int:
		return _pot_value.value
	func clear_pot_value() -> void:
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_pot_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_pot_value(value : int) -> void:
		_pot_value.value = value
	
	var _current_round: PBField
	func get_current_round() -> int:
		return _current_round.value
	func clear_current_round() -> void:
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_current_round.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_current_round(value : int) -> void:
		_current_round.value = value
	
	var _hand_in_round: PBField
	func get_hand_in_round() -> int:
		return _hand_in_round.value
	func clear_hand_in_round() -> void:
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_hand_in_round.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_hand_in_round(value : int) -> void:
		_hand_in_round.value = value
	
	var _point_to_win: PBField
	func get_point_to_win() -> int:
		return _point_to_win.value
	func clear_point_to_win() -> void:
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_point_to_win.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_point_to_win(value : int) -> void:
		_point_to_win.value = value
	
	var _enable_bet_win_score: PBField
	func get_enable_bet_win_score() -> bool:
		return _enable_bet_win_score.value
	func clear_enable_bet_win_score() -> void:
		data[22].state = PB_SERVICE_STATE.UNFILLED
		_enable_bet_win_score.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_enable_bet_win_score(value : bool) -> void:
		_enable_bet_win_score.value = value
	
	var _is_vips: PBField
	func get_is_vips() -> Array:
		return _is_vips.value
	func clear_is_vips() -> void:
		data[23].state = PB_SERVICE_STATE.UNFILLED
		_is_vips.value = []
	func add_is_vips(value : bool) -> void:
		_is_vips.value.append(value)
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class RegisterLeaveGame:
	func _init():
		var service
		
		_status = PBField.new("status", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _status
		data[_status.tag] = service
		
	var data = {}
	
	var _status: PBField
	func get_status() -> int:
		return _status.value
	func clear_status() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_status.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_status(value : int) -> void:
		_status.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class NewUserJoinMatch:
	func _init():
		var service
		
		_uid = PBField.new("uid", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _uid
		data[_uid.tag] = service
		
		_gold = PBField.new("gold", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = _gold
		data[_gold.tag] = service
		
		_name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _name
		data[_name.tag] = service
		
		_seat_server = PBField.new("seat_server", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _seat_server
		data[_seat_server.tag] = service
		
		_team_id = PBField.new("team_id", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _team_id
		data[_team_id.tag] = service
		
		_avatar = PBField.new("avatar", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _avatar
		data[_avatar.tag] = service
		
		_is_vip = PBField.new("is_vip", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _is_vip
		data[_is_vip.tag] = service
		
	var data = {}
	
	var _uid: PBField
	func get_uid() -> int:
		return _uid.value
	func clear_uid() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_uid(value : int) -> void:
		_uid.value = value
	
	var _gold: PBField
	func get_gold() -> int:
		return _gold.value
	func clear_gold() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_gold.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_gold(value : int) -> void:
		_gold.value = value
	
	var _name: PBField
	func get_name() -> String:
		return _name.value
	func clear_name() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		_name.value = value
	
	var _seat_server: PBField
	func get_seat_server() -> int:
		return _seat_server.value
	func clear_seat_server() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_seat_server.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_seat_server(value : int) -> void:
		_seat_server.value = value
	
	var _team_id: PBField
	func get_team_id() -> int:
		return _team_id.value
	func clear_team_id() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_team_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_team_id(value : int) -> void:
		_team_id.value = value
	
	var _avatar: PBField
	func get_avatar() -> String:
		return _avatar.value
	func clear_avatar() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_avatar.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_avatar(value : String) -> void:
		_avatar.value = value
	
	var _is_vip: PBField
	func get_is_vip() -> bool:
		return _is_vip.value
	func clear_is_vip() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_is_vip.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_is_vip(value : bool) -> void:
		_is_vip.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class UserLeaveMatch:
	func _init():
		var service
		
		_uid = PBField.new("uid", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _uid
		data[_uid.tag] = service
		
		_reason = PBField.new("reason", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _reason
		data[_reason.tag] = service
		
	var data = {}
	
	var _uid: PBField
	func get_uid() -> int:
		return _uid.value
	func clear_uid() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_uid(value : int) -> void:
		_uid.value = value
	
	var _reason: PBField
	func get_reason() -> int:
		return _reason.value
	func clear_reason() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_reason.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_reason(value : int) -> void:
		_reason.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class DealCard:
	func _init():
		var service
		
		_cards = PBField.new("cards", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 1, true, [])
		service = PBServiceField.new()
		service.field = _cards
		data[_cards.tag] = service
		
		_remain_cards = PBField.new("remain_cards", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _remain_cards
		data[_remain_cards.tag] = service
		
	var data = {}
	
	var _cards: PBField
	func get_cards() -> Array:
		return _cards.value
	func clear_cards() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_cards.value = []
	func add_cards(value : int) -> void:
		_cards.value.append(value)
	
	var _remain_cards: PBField
	func get_remain_cards() -> int:
		return _remain_cards.value
	func clear_remain_cards() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_remain_cards.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_remain_cards(value : int) -> void:
		_remain_cards.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PlayCard:
	func _init():
		var service
		
		_uid = PBField.new("uid", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _uid
		data[_uid.tag] = service
		
		_card_id = PBField.new("card_id", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _card_id
		data[_card_id.tag] = service
		
		_auto = PBField.new("auto", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _auto
		data[_auto.tag] = service
		
		_current_turn = PBField.new("current_turn", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _current_turn
		data[_current_turn.tag] = service
		
		_hand_suit = PBField.new("hand_suit", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _hand_suit
		data[_hand_suit.tag] = service
		
		_is_end_hand = PBField.new("is_end_hand", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _is_end_hand
		data[_is_end_hand.tag] = service
		
		_win_uid = PBField.new("win_uid", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _win_uid
		data[_win_uid.tag] = service
		
		_win_point = PBField.new("win_point", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _win_point
		data[_win_point.tag] = service
		
		_is_end_round = PBField.new("is_end_round", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _is_end_round
		data[_is_end_round.tag] = service
		
		_win_card = PBField.new("win_card", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _win_card
		data[_win_card.tag] = service
		
	var data = {}
	
	var _uid: PBField
	func get_uid() -> int:
		return _uid.value
	func clear_uid() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_uid(value : int) -> void:
		_uid.value = value
	
	var _card_id: PBField
	func get_card_id() -> int:
		return _card_id.value
	func clear_card_id() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_card_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_card_id(value : int) -> void:
		_card_id.value = value
	
	var _auto: PBField
	func get_auto() -> bool:
		return _auto.value
	func clear_auto() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_auto.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_auto(value : bool) -> void:
		_auto.value = value
	
	var _current_turn: PBField
	func get_current_turn() -> int:
		return _current_turn.value
	func clear_current_turn() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_current_turn.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_current_turn(value : int) -> void:
		_current_turn.value = value
	
	var _hand_suit: PBField
	func get_hand_suit() -> int:
		return _hand_suit.value
	func clear_hand_suit() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_hand_suit.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_hand_suit(value : int) -> void:
		_hand_suit.value = value
	
	var _is_end_hand: PBField
	func get_is_end_hand() -> bool:
		return _is_end_hand.value
	func clear_is_end_hand() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_is_end_hand.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_is_end_hand(value : bool) -> void:
		_is_end_hand.value = value
	
	var _win_uid: PBField
	func get_win_uid() -> int:
		return _win_uid.value
	func clear_win_uid() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_win_uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_win_uid(value : int) -> void:
		_win_uid.value = value
	
	var _win_point: PBField
	func get_win_point() -> int:
		return _win_point.value
	func clear_win_point() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_win_point.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_win_point(value : int) -> void:
		_win_point.value = value
	
	var _is_end_round: PBField
	func get_is_end_round() -> bool:
		return _is_end_round.value
	func clear_is_end_round() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_is_end_round.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_is_end_round(value : bool) -> void:
		_is_end_round.value = value
	
	var _win_card: PBField
	func get_win_card() -> int:
		return _win_card.value
	func clear_win_card() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		_win_card.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_win_card(value : int) -> void:
		_win_card.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class StartGame:
	func _init():
		var service
		
		_pot_value = PBField.new("pot_value", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _pot_value
		data[_pot_value.tag] = service
		
		_players_gold = PBField.new("players_gold", PB_DATA_TYPE.INT64, PB_RULE.REPEATED, 2, true, [])
		service = PBServiceField.new()
		service.field = _players_gold
		data[_players_gold.tag] = service
		
	var data = {}
	
	var _pot_value: PBField
	func get_pot_value() -> int:
		return _pot_value.value
	func clear_pot_value() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_pot_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_pot_value(value : int) -> void:
		_pot_value.value = value
	
	var _players_gold: PBField
	func get_players_gold() -> Array:
		return _players_gold.value
	func clear_players_gold() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_players_gold.value = []
	func add_players_gold(value : int) -> void:
		_players_gold.value.append(value)
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class NewHand:
	func _init():
		var service
		
		_current_turn = PBField.new("current_turn", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _current_turn
		data[_current_turn.tag] = service
		
		_my_cards = PBField.new("my_cards", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 2, true, [])
		service = PBServiceField.new()
		service.field = _my_cards
		data[_my_cards.tag] = service
		
	var data = {}
	
	var _current_turn: PBField
	func get_current_turn() -> int:
		return _current_turn.value
	func clear_current_turn() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_current_turn.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_current_turn(value : int) -> void:
		_current_turn.value = value
	
	var _my_cards: PBField
	func get_my_cards() -> Array:
		return _my_cards.value
	func clear_my_cards() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_my_cards.value = []
	func add_my_cards(value : int) -> void:
		_my_cards.value.append(value)
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class UpdateGamePoint:
	func _init():
		var service
		
		_points = PBField.new("points", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 1, true, [])
		service = PBServiceField.new()
		service.field = _points
		data[_points.tag] = service
		
	var data = {}
	
	var _points: PBField
	func get_points() -> Array:
		return _points.value
	func clear_points() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_points.value = []
	func add_points(value : int) -> void:
		_points.value.append(value)
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class EndHand:
	func _init():
		var service
		
		_win_uid = PBField.new("win_uid", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _win_uid
		data[_win_uid.tag] = service
		
		_win_card = PBField.new("win_card", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _win_card
		data[_win_card.tag] = service
		
		_user_points = PBField.new("user_points", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 3, true, [])
		service = PBServiceField.new()
		service.field = _user_points
		data[_user_points.tag] = service
		
		_win_point = PBField.new("win_point", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _win_point
		data[_win_point.tag] = service
		
		_is_end_round = PBField.new("is_end_round", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _is_end_round
		data[_is_end_round.tag] = service
		
	var data = {}
	
	var _win_uid: PBField
	func get_win_uid() -> int:
		return _win_uid.value
	func clear_win_uid() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_win_uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_win_uid(value : int) -> void:
		_win_uid.value = value
	
	var _win_card: PBField
	func get_win_card() -> int:
		return _win_card.value
	func clear_win_card() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_win_card.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_win_card(value : int) -> void:
		_win_card.value = value
	
	var _user_points: PBField
	func get_user_points() -> Array:
		return _user_points.value
	func clear_user_points() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_user_points.value = []
	func add_user_points(value : int) -> void:
		_user_points.value.append(value)
	
	var _win_point: PBField
	func get_win_point() -> int:
		return _win_point.value
	func clear_win_point() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_win_point.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_win_point(value : int) -> void:
		_win_point.value = value
	
	var _is_end_round: PBField
	func get_is_end_round() -> bool:
		return _is_end_round.value
	func clear_is_end_round() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_is_end_round.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_is_end_round(value : bool) -> void:
		_is_end_round.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class DrawCard:
	func _init():
		var service
		
		_cards = PBField.new("cards", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 1, true, [])
		service = PBServiceField.new()
		service.field = _cards
		data[_cards.tag] = service
		
	var data = {}
	
	var _cards: PBField
	func get_cards() -> Array:
		return _cards.value
	func clear_cards() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_cards.value = []
	func add_cards(value : int) -> void:
		_cards.value.append(value)
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class GeneralInfo:
	func _init():
		var service
		
		_timestamp = PBField.new("timestamp", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = _timestamp
		data[_timestamp.tag] = service
		
		_time_thinking_in_turn = PBField.new("time_thinking_in_turn", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _time_thinking_in_turn
		data[_time_thinking_in_turn.tag] = service
		
		_tressette_bets = PBField.new("tressette_bets", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 3, true, [])
		service = PBServiceField.new()
		service.field = _tressette_bets
		data[_tressette_bets.tag] = service
		
		_bet_multiplier_min = PBField.new("bet_multiplier_min", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _bet_multiplier_min
		data[_bet_multiplier_min.tag] = service
		
		_exp_levels = PBField.new("exp_levels", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 5, true, [])
		service = PBServiceField.new()
		service.field = _exp_levels
		data[_exp_levels.tag] = service
		
		_fee_mode_no_bet = PBField.new("fee_mode_no_bet", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _fee_mode_no_bet
		data[_fee_mode_no_bet.tag] = service
		
		_enable_ads = PBField.new("enable_ads", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _enable_ads
		data[_enable_ads.tag] = service
		
	var data = {}
	
	var _timestamp: PBField
	func get_timestamp() -> int:
		return _timestamp.value
	func clear_timestamp() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_timestamp.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_timestamp(value : int) -> void:
		_timestamp.value = value
	
	var _time_thinking_in_turn: PBField
	func get_time_thinking_in_turn() -> int:
		return _time_thinking_in_turn.value
	func clear_time_thinking_in_turn() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_time_thinking_in_turn.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_time_thinking_in_turn(value : int) -> void:
		_time_thinking_in_turn.value = value
	
	var _tressette_bets: PBField
	func get_tressette_bets() -> Array:
		return _tressette_bets.value
	func clear_tressette_bets() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_tressette_bets.value = []
	func add_tressette_bets(value : int) -> void:
		_tressette_bets.value.append(value)
	
	var _bet_multiplier_min: PBField
	func get_bet_multiplier_min() -> int:
		return _bet_multiplier_min.value
	func clear_bet_multiplier_min() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_bet_multiplier_min.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_bet_multiplier_min(value : int) -> void:
		_bet_multiplier_min.value = value
	
	var _exp_levels: PBField
	func get_exp_levels() -> Array:
		return _exp_levels.value
	func clear_exp_levels() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_exp_levels.value = []
	func add_exp_levels(value : int) -> void:
		_exp_levels.value.append(value)
	
	var _fee_mode_no_bet: PBField
	func get_fee_mode_no_bet() -> int:
		return _fee_mode_no_bet.value
	func clear_fee_mode_no_bet() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_fee_mode_no_bet.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_fee_mode_no_bet(value : int) -> void:
		_fee_mode_no_bet.value = value
	
	var _enable_ads: PBField
	func get_enable_ads() -> bool:
		return _enable_ads.value
	func clear_enable_ads() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_enable_ads.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_enable_ads(value : bool) -> void:
		_enable_ads.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class EndGame:
	func _init():
		var service
		
		_uids = PBField.new("uids", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 1, true, [])
		service = PBServiceField.new()
		service.field = _uids
		data[_uids.tag] = service
		
		_win_team_id = PBField.new("win_team_id", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _win_team_id
		data[_win_team_id.tag] = service
		
		_score_cards = PBField.new("score_cards", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 2, true, [])
		service = PBServiceField.new()
		service.field = _score_cards
		data[_score_cards.tag] = service
		
		_score_last_tricks = PBField.new("score_last_tricks", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 3, true, [])
		service = PBServiceField.new()
		service.field = _score_last_tricks
		data[_score_last_tricks.tag] = service
		
		_score_totals = PBField.new("score_totals", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 4, true, [])
		service = PBServiceField.new()
		service.field = _score_totals
		data[_score_totals.tag] = service
		
		_gold_changes = PBField.new("gold_changes", PB_DATA_TYPE.INT64, PB_RULE.REPEATED, 6, true, [])
		service = PBServiceField.new()
		service.field = _gold_changes
		data[_gold_changes.tag] = service
		
		_players_gold = PBField.new("players_gold", PB_DATA_TYPE.INT64, PB_RULE.REPEATED, 7, true, [])
		service = PBServiceField.new()
		service.field = _players_gold
		data[_players_gold.tag] = service
		
		_gold_win_score = PBField.new("gold_win_score", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = _gold_win_score
		data[_gold_win_score.tag] = service
		
	var data = {}
	
	var _uids: PBField
	func get_uids() -> Array:
		return _uids.value
	func clear_uids() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uids.value = []
	func add_uids(value : int) -> void:
		_uids.value.append(value)
	
	var _win_team_id: PBField
	func get_win_team_id() -> int:
		return _win_team_id.value
	func clear_win_team_id() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_win_team_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_win_team_id(value : int) -> void:
		_win_team_id.value = value
	
	var _score_cards: PBField
	func get_score_cards() -> Array:
		return _score_cards.value
	func clear_score_cards() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_score_cards.value = []
	func add_score_cards(value : int) -> void:
		_score_cards.value.append(value)
	
	var _score_last_tricks: PBField
	func get_score_last_tricks() -> Array:
		return _score_last_tricks.value
	func clear_score_last_tricks() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_score_last_tricks.value = []
	func add_score_last_tricks(value : int) -> void:
		_score_last_tricks.value.append(value)
	
	var _score_totals: PBField
	func get_score_totals() -> Array:
		return _score_totals.value
	func clear_score_totals() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_score_totals.value = []
	func add_score_totals(value : int) -> void:
		_score_totals.value.append(value)
	
	var _gold_changes: PBField
	func get_gold_changes() -> Array:
		return _gold_changes.value
	func clear_gold_changes() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_gold_changes.value = []
	func add_gold_changes(value : int) -> void:
		_gold_changes.value.append(value)
	
	var _players_gold: PBField
	func get_players_gold() -> Array:
		return _players_gold.value
	func clear_players_gold() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_players_gold.value = []
	func add_players_gold(value : int) -> void:
		_players_gold.value.append(value)
	
	var _gold_win_score: PBField
	func get_gold_win_score() -> int:
		return _gold_win_score.value
	func clear_gold_win_score() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_gold_win_score.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_gold_win_score(value : int) -> void:
		_gold_win_score.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PrepareStartGame:
	func _init():
		var service
		
		_time_start = PBField.new("time_start", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _time_start
		data[_time_start.tag] = service
		
	var data = {}
	
	var _time_start: PBField
	func get_time_start() -> int:
		return _time_start.value
	func clear_time_start() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_time_start.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_time_start(value : int) -> void:
		_time_start.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class InGameChatMessage:
	func _init():
		var service
		
		_uid = PBField.new("uid", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _uid
		data[_uid.tag] = service
		
		_chat_message = PBField.new("chat_message", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _chat_message
		data[_chat_message.tag] = service
		
	var data = {}
	
	var _uid: PBField
	func get_uid() -> int:
		return _uid.value
	func clear_uid() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_uid(value : int) -> void:
		_uid.value = value
	
	var _chat_message: PBField
	func get_chat_message() -> String:
		return _chat_message.value
	func clear_chat_message() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_chat_message.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_chat_message(value : String) -> void:
		_chat_message.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PaymentGoogleConsume:
	func _init():
		var service
		
		_purchase_token = PBField.new("purchase_token", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _purchase_token
		data[_purchase_token.tag] = service
		
		_quantity = PBField.new("quantity", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _quantity
		data[_quantity.tag] = service
		
		_skus = PBField.new("skus", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 3, true, [])
		service = PBServiceField.new()
		service.field = _skus
		data[_skus.tag] = service
		
		_signature = PBField.new("signature", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _signature
		data[_signature.tag] = service
		
		_sku = PBField.new("sku", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _sku
		data[_sku.tag] = service
		
	var data = {}
	
	var _purchase_token: PBField
	func get_purchase_token() -> String:
		return _purchase_token.value
	func clear_purchase_token() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_purchase_token.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_purchase_token(value : String) -> void:
		_purchase_token.value = value
	
	var _quantity: PBField
	func get_quantity() -> int:
		return _quantity.value
	func clear_quantity() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_quantity.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_quantity(value : int) -> void:
		_quantity.value = value
	
	var _skus: PBField
	func get_skus() -> Array:
		return _skus.value
	func clear_skus() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_skus.value = []
	func add_skus(value : String) -> void:
		_skus.value.append(value)
	
	var _signature: PBField
	func get_signature() -> String:
		return _signature.value
	func clear_signature() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_signature.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_signature(value : String) -> void:
		_signature.value = value
	
	var _sku: PBField
	func get_sku() -> String:
		return _sku.value
	func clear_sku() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_sku.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_sku(value : String) -> void:
		_sku.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PaymentSuccess:
	func _init():
		var service
		
		_gold = PBField.new("gold", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = _gold
		data[_gold.tag] = service
		
		_pack_id = PBField.new("pack_id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _pack_id
		data[_pack_id.tag] = service
		
	var data = {}
	
	var _gold: PBField
	func get_gold() -> int:
		return _gold.value
	func clear_gold() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_gold.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_gold(value : int) -> void:
		_gold.value = value
	
	var _pack_id: PBField
	func get_pack_id() -> String:
		return _pack_id.value
	func clear_pack_id() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_pack_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_pack_id(value : String) -> void:
		_pack_id.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class UpdateMoney:
	func _init():
		var service
		
		_gold = PBField.new("gold", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = _gold
		data[_gold.tag] = service
		
	var data = {}
	
	var _gold: PBField
	func get_gold() -> int:
		return _gold.value
	func clear_gold() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_gold.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_gold(value : int) -> void:
		_gold.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class TableList:
	func _init():
		var service
		
		_table_ids = PBField.new("table_ids", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 1, true, [])
		service = PBServiceField.new()
		service.field = _table_ids
		data[_table_ids.tag] = service
		
		_bets = PBField.new("bets", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 2, true, [])
		service = PBServiceField.new()
		service.field = _bets
		data[_bets.tag] = service
		
		_num_players = PBField.new("num_players", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 3, true, [])
		service = PBServiceField.new()
		service.field = _num_players
		data[_num_players.tag] = service
		
		_player_modes = PBField.new("player_modes", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 4, true, [])
		service = PBServiceField.new()
		service.field = _player_modes
		data[_player_modes.tag] = service
		
	var data = {}
	
	var _table_ids: PBField
	func get_table_ids() -> Array:
		return _table_ids.value
	func clear_table_ids() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_table_ids.value = []
	func add_table_ids(value : int) -> void:
		_table_ids.value.append(value)
	
	var _bets: PBField
	func get_bets() -> Array:
		return _bets.value
	func clear_bets() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_bets.value = []
	func add_bets(value : int) -> void:
		_bets.value.append(value)
	
	var _num_players: PBField
	func get_num_players() -> Array:
		return _num_players.value
	func clear_num_players() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_num_players.value = []
	func add_num_players(value : int) -> void:
		_num_players.value.append(value)
	
	var _player_modes: PBField
	func get_player_modes() -> Array:
		return _player_modes.value
	func clear_player_modes() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_player_modes.value = []
	func add_player_modes(value : int) -> void:
		_player_modes.value.append(value)
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class ShopConfig:
	func _init():
		var service
		
		_pack_ids = PBField.new("pack_ids", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 1, true, [])
		service = PBServiceField.new()
		service.field = _pack_ids
		data[_pack_ids.tag] = service
		
		_golds = PBField.new("golds", PB_DATA_TYPE.INT64, PB_RULE.REPEATED, 2, true, [])
		service = PBServiceField.new()
		service.field = _golds
		data[_golds.tag] = service
		
		_prices = PBField.new("prices", PB_DATA_TYPE.DOUBLE, PB_RULE.REPEATED, 3, true, [])
		service = PBServiceField.new()
		service.field = _prices
		data[_prices.tag] = service
		
		_currencies = PBField.new("currencies", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 4, true, [])
		service = PBServiceField.new()
		service.field = _currencies
		data[_currencies.tag] = service
		
		_no_ads_days = PBField.new("no_ads_days", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 5, true, [])
		service = PBServiceField.new()
		service.field = _no_ads_days
		data[_no_ads_days.tag] = service
		
		_gold_offer_first = PBField.new("gold_offer_first", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _gold_offer_first
		data[_gold_offer_first.tag] = service
		
		_no_ads_day_offer_first = PBField.new("no_ads_day_offer_first", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _no_ads_day_offer_first
		data[_no_ads_day_offer_first.tag] = service
		
		_price_offer_first = PBField.new("price_offer_first", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _price_offer_first
		data[_price_offer_first.tag] = service
		
		_currency_offer_first = PBField.new("currency_offer_first", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _currency_offer_first
		data[_currency_offer_first.tag] = service
		
		_pack_id_offer_first = PBField.new("pack_id_offer_first", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _pack_id_offer_first
		data[_pack_id_offer_first.tag] = service
		
	var data = {}
	
	var _pack_ids: PBField
	func get_pack_ids() -> Array:
		return _pack_ids.value
	func clear_pack_ids() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_pack_ids.value = []
	func add_pack_ids(value : String) -> void:
		_pack_ids.value.append(value)
	
	var _golds: PBField
	func get_golds() -> Array:
		return _golds.value
	func clear_golds() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_golds.value = []
	func add_golds(value : int) -> void:
		_golds.value.append(value)
	
	var _prices: PBField
	func get_prices() -> Array:
		return _prices.value
	func clear_prices() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_prices.value = []
	func add_prices(value : float) -> void:
		_prices.value.append(value)
	
	var _currencies: PBField
	func get_currencies() -> Array:
		return _currencies.value
	func clear_currencies() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_currencies.value = []
	func add_currencies(value : String) -> void:
		_currencies.value.append(value)
	
	var _no_ads_days: PBField
	func get_no_ads_days() -> Array:
		return _no_ads_days.value
	func clear_no_ads_days() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_no_ads_days.value = []
	func add_no_ads_days(value : int) -> void:
		_no_ads_days.value.append(value)
	
	var _gold_offer_first: PBField
	func get_gold_offer_first() -> int:
		return _gold_offer_first.value
	func clear_gold_offer_first() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_gold_offer_first.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_gold_offer_first(value : int) -> void:
		_gold_offer_first.value = value
	
	var _no_ads_day_offer_first: PBField
	func get_no_ads_day_offer_first() -> int:
		return _no_ads_day_offer_first.value
	func clear_no_ads_day_offer_first() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_no_ads_day_offer_first.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_no_ads_day_offer_first(value : int) -> void:
		_no_ads_day_offer_first.value = value
	
	var _price_offer_first: PBField
	func get_price_offer_first() -> int:
		return _price_offer_first.value
	func clear_price_offer_first() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_price_offer_first.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_price_offer_first(value : int) -> void:
		_price_offer_first.value = value
	
	var _currency_offer_first: PBField
	func get_currency_offer_first() -> String:
		return _currency_offer_first.value
	func clear_currency_offer_first() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_currency_offer_first.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_currency_offer_first(value : String) -> void:
		_currency_offer_first.value = value
	
	var _pack_id_offer_first: PBField
	func get_pack_id_offer_first() -> String:
		return _pack_id_offer_first.value
	func clear_pack_id_offer_first() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		_pack_id_offer_first.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_pack_id_offer_first(value : String) -> void:
		_pack_id_offer_first.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class GuestAccount:
	func _init():
		var service
		
		_guest_id = PBField.new("guest_id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _guest_id
		data[_guest_id.tag] = service
		
	var data = {}
	
	var _guest_id: PBField
	func get_guest_id() -> String:
		return _guest_id.value
	func clear_guest_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_guest_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_guest_id(value : String) -> void:
		_guest_id.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class ChangeAvatar:
	func _init():
		var service
		
		_avatar_id = PBField.new("avatar_id", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _avatar_id
		data[_avatar_id.tag] = service
		
	var data = {}
	
	var _avatar_id: PBField
	func get_avatar_id() -> int:
		return _avatar_id.value
	func clear_avatar_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_avatar_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_avatar_id(value : int) -> void:
		_avatar_id.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class InGameChatEmoticon:
	func _init():
		var service
		
		_uid = PBField.new("uid", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _uid
		data[_uid.tag] = service
		
		_emoticon = PBField.new("emoticon", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _emoticon
		data[_emoticon.tag] = service
		
	var data = {}
	
	var _uid: PBField
	func get_uid() -> int:
		return _uid.value
	func clear_uid() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_uid(value : int) -> void:
		_uid.value = value
	
	var _emoticon: PBField
	func get_emoticon() -> int:
		return _emoticon.value
	func clear_emoticon() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_emoticon.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_emoticon(value : int) -> void:
		_emoticon.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class SearchFriend:
	func _init():
		var service
		
		_uid = PBField.new("uid", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _uid
		data[_uid.tag] = service
		
	var data = {}
	
	var _uid: PBField
	func get_uid() -> int:
		return _uid.value
	func clear_uid() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_uid(value : int) -> void:
		_uid.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class SearchFriendResponse:
	func _init():
		var service
		
		_uid = PBField.new("uid", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _uid
		data[_uid.tag] = service
		
		_gold = PBField.new("gold", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = _gold
		data[_gold.tag] = service
		
		_name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _name
		data[_name.tag] = service
		
		_avatar = PBField.new("avatar", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _avatar
		data[_avatar.tag] = service
		
		_win_count = PBField.new("win_count", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _win_count
		data[_win_count.tag] = service
		
		_game_count = PBField.new("game_count", PB_DATA_TYPE.DOUBLE, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.DOUBLE])
		service = PBServiceField.new()
		service.field = _game_count
		data[_game_count.tag] = service
		
		_error = PBField.new("error", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _error
		data[_error.tag] = service
		
		_level = PBField.new("level", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _level
		data[_level.tag] = service
		
		_exp = PBField.new("exp", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = _exp
		data[_exp.tag] = service
		
		_is_verified = PBField.new("is_verified", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _is_verified
		data[_is_verified.tag] = service
		
	var data = {}
	
	var _uid: PBField
	func get_uid() -> int:
		return _uid.value
	func clear_uid() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_uid(value : int) -> void:
		_uid.value = value
	
	var _gold: PBField
	func get_gold() -> int:
		return _gold.value
	func clear_gold() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_gold.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_gold(value : int) -> void:
		_gold.value = value
	
	var _name: PBField
	func get_name() -> String:
		return _name.value
	func clear_name() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		_name.value = value
	
	var _avatar: PBField
	func get_avatar() -> String:
		return _avatar.value
	func clear_avatar() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_avatar.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_avatar(value : String) -> void:
		_avatar.value = value
	
	var _win_count: PBField
	func get_win_count() -> int:
		return _win_count.value
	func clear_win_count() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_win_count.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_win_count(value : int) -> void:
		_win_count.value = value
	
	var _game_count: PBField
	func get_game_count() -> float:
		return _game_count.value
	func clear_game_count() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_game_count.value = DEFAULT_VALUES_3[PB_DATA_TYPE.DOUBLE]
	func set_game_count(value : float) -> void:
		_game_count.value = value
	
	var _error: PBField
	func get_error() -> int:
		return _error.value
	func clear_error() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_error.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_error(value : int) -> void:
		_error.value = value
	
	var _level: PBField
	func get_level() -> int:
		return _level.value
	func clear_level() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_level.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_level(value : int) -> void:
		_level.value = value
	
	var _exp: PBField
	func get_exp() -> int:
		return _exp.value
	func clear_exp() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_exp.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_exp(value : int) -> void:
		_exp.value = value
	
	var _is_verified: PBField
	func get_is_verified() -> bool:
		return _is_verified.value
	func clear_is_verified() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		_is_verified.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_is_verified(value : bool) -> void:
		_is_verified.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class CheatGoldUser:
	func _init():
		var service
		
		_gold = PBField.new("gold", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = _gold
		data[_gold.tag] = service
		
	var data = {}
	
	var _gold: PBField
	func get_gold() -> int:
		return _gold.value
	func clear_gold() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_gold.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_gold(value : int) -> void:
		_gold.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class FriendList:
	func _init():
		var service
		
		_uids = PBField.new("uids", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 1, true, [])
		service = PBServiceField.new()
		service.field = _uids
		data[_uids.tag] = service
		
		_names = PBField.new("names", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 2, true, [])
		service = PBServiceField.new()
		service.field = _names
		data[_names.tag] = service
		
		_avatars = PBField.new("avatars", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 3, true, [])
		service = PBServiceField.new()
		service.field = _avatars
		data[_avatars.tag] = service
		
		_levels = PBField.new("levels", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 4, true, [])
		service = PBServiceField.new()
		service.field = _levels
		data[_levels.tag] = service
		
		_golds = PBField.new("golds", PB_DATA_TYPE.INT64, PB_RULE.REPEATED, 5, true, [])
		service = PBServiceField.new()
		service.field = _golds
		data[_golds.tag] = service
		
		_onlines = PBField.new("onlines", PB_DATA_TYPE.BOOL, PB_RULE.REPEATED, 6, true, [])
		service = PBServiceField.new()
		service.field = _onlines
		data[_onlines.tag] = service
		
		_is_playings = PBField.new("is_playings", PB_DATA_TYPE.BOOL, PB_RULE.REPEATED, 7, true, [])
		service = PBServiceField.new()
		service.field = _is_playings
		data[_is_playings.tag] = service
		
	var data = {}
	
	var _uids: PBField
	func get_uids() -> Array:
		return _uids.value
	func clear_uids() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uids.value = []
	func add_uids(value : int) -> void:
		_uids.value.append(value)
	
	var _names: PBField
	func get_names() -> Array:
		return _names.value
	func clear_names() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_names.value = []
	func add_names(value : String) -> void:
		_names.value.append(value)
	
	var _avatars: PBField
	func get_avatars() -> Array:
		return _avatars.value
	func clear_avatars() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_avatars.value = []
	func add_avatars(value : String) -> void:
		_avatars.value.append(value)
	
	var _levels: PBField
	func get_levels() -> Array:
		return _levels.value
	func clear_levels() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_levels.value = []
	func add_levels(value : int) -> void:
		_levels.value.append(value)
	
	var _golds: PBField
	func get_golds() -> Array:
		return _golds.value
	func clear_golds() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_golds.value = []
	func add_golds(value : int) -> void:
		_golds.value.append(value)
	
	var _onlines: PBField
	func get_onlines() -> Array:
		return _onlines.value
	func clear_onlines() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_onlines.value = []
	func add_onlines(value : bool) -> void:
		_onlines.value.append(value)
	
	var _is_playings: PBField
	func get_is_playings() -> Array:
		return _is_playings.value
	func clear_is_playings() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_is_playings.value = []
	func add_is_playings(value : bool) -> void:
		_is_playings.value.append(value)
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class FriendRequests:
	func _init():
		var service
		
		_uids = PBField.new("uids", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 1, true, [])
		service = PBServiceField.new()
		service.field = _uids
		data[_uids.tag] = service
		
		_names = PBField.new("names", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 2, true, [])
		service = PBServiceField.new()
		service.field = _names
		data[_names.tag] = service
		
		_avatars = PBField.new("avatars", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 3, true, [])
		service = PBServiceField.new()
		service.field = _avatars
		data[_avatars.tag] = service
		
		_levels = PBField.new("levels", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 4, true, [])
		service = PBServiceField.new()
		service.field = _levels
		data[_levels.tag] = service
		
		_golds = PBField.new("golds", PB_DATA_TYPE.INT64, PB_RULE.REPEATED, 5, true, [])
		service = PBServiceField.new()
		service.field = _golds
		data[_golds.tag] = service
		
		_sent_uids = PBField.new("sent_uids", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 6, true, [])
		service = PBServiceField.new()
		service.field = _sent_uids
		data[_sent_uids.tag] = service
		
	var data = {}
	
	var _uids: PBField
	func get_uids() -> Array:
		return _uids.value
	func clear_uids() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uids.value = []
	func add_uids(value : int) -> void:
		_uids.value.append(value)
	
	var _names: PBField
	func get_names() -> Array:
		return _names.value
	func clear_names() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_names.value = []
	func add_names(value : String) -> void:
		_names.value.append(value)
	
	var _avatars: PBField
	func get_avatars() -> Array:
		return _avatars.value
	func clear_avatars() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_avatars.value = []
	func add_avatars(value : String) -> void:
		_avatars.value.append(value)
	
	var _levels: PBField
	func get_levels() -> Array:
		return _levels.value
	func clear_levels() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_levels.value = []
	func add_levels(value : int) -> void:
		_levels.value.append(value)
	
	var _golds: PBField
	func get_golds() -> Array:
		return _golds.value
	func clear_golds() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_golds.value = []
	func add_golds(value : int) -> void:
		_golds.value.append(value)
	
	var _sent_uids: PBField
	func get_sent_uids() -> Array:
		return _sent_uids.value
	func clear_sent_uids() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_sent_uids.value = []
	func add_sent_uids(value : int) -> void:
		_sent_uids.value.append(value)
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class AddFriend:
	func _init():
		var service
		
		_error = PBField.new("error", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _error
		data[_error.tag] = service
		
		_uid = PBField.new("uid", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _uid
		data[_uid.tag] = service
		
	var data = {}
	
	var _error: PBField
	func get_error() -> int:
		return _error.value
	func clear_error() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_error.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_error(value : int) -> void:
		_error.value = value
	
	var _uid: PBField
	func get_uid() -> int:
		return _uid.value
	func clear_uid() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_uid(value : int) -> void:
		_uid.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class RequestFriendAccept:
	func _init():
		var service
		
		_uid = PBField.new("uid", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _uid
		data[_uid.tag] = service
		
		_action = PBField.new("action", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _action
		data[_action.tag] = service
		
	var data = {}
	
	var _uid: PBField
	func get_uid() -> int:
		return _uid.value
	func clear_uid() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_uid(value : int) -> void:
		_uid.value = value
	
	var _action: PBField
	func get_action() -> int:
		return _action.value
	func clear_action() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_action.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_action(value : int) -> void:
		_action.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class RemoveFriend:
	func _init():
		var service
		
		_uid = PBField.new("uid", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _uid
		data[_uid.tag] = service
		
	var data = {}
	
	var _uid: PBField
	func get_uid() -> int:
		return _uid.value
	func clear_uid() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_uid(value : int) -> void:
		_uid.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class NewFriendRequest:
	func _init():
		var service
		
		_uid = PBField.new("uid", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _uid
		data[_uid.tag] = service
		
		_avatar = PBField.new("avatar", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _avatar
		data[_avatar.tag] = service
		
		_name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _name
		data[_name.tag] = service
		
		_level = PBField.new("level", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _level
		data[_level.tag] = service
		
		_gold = PBField.new("gold", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = _gold
		data[_gold.tag] = service
		
	var data = {}
	
	var _uid: PBField
	func get_uid() -> int:
		return _uid.value
	func clear_uid() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_uid(value : int) -> void:
		_uid.value = value
	
	var _avatar: PBField
	func get_avatar() -> String:
		return _avatar.value
	func clear_avatar() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_avatar.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_avatar(value : String) -> void:
		_avatar.value = value
	
	var _name: PBField
	func get_name() -> String:
		return _name.value
	func clear_name() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		_name.value = value
	
	var _level: PBField
	func get_level() -> int:
		return _level.value
	func clear_level() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_level.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_level(value : int) -> void:
		_level.value = value
	
	var _gold: PBField
	func get_gold() -> int:
		return _gold.value
	func clear_gold() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_gold.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_gold(value : int) -> void:
		_gold.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class FriendRequestAccepted:
	func _init():
		var service
		
		_uid = PBField.new("uid", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _uid
		data[_uid.tag] = service
		
		_name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _name
		data[_name.tag] = service
		
		_avatar = PBField.new("avatar", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _avatar
		data[_avatar.tag] = service
		
		_level = PBField.new("level", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _level
		data[_level.tag] = service
		
		_gold = PBField.new("gold", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = _gold
		data[_gold.tag] = service
		
	var data = {}
	
	var _uid: PBField
	func get_uid() -> int:
		return _uid.value
	func clear_uid() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_uid(value : int) -> void:
		_uid.value = value
	
	var _name: PBField
	func get_name() -> String:
		return _name.value
	func clear_name() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		_name.value = value
	
	var _avatar: PBField
	func get_avatar() -> String:
		return _avatar.value
	func clear_avatar() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_avatar.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_avatar(value : String) -> void:
		_avatar.value = value
	
	var _level: PBField
	func get_level() -> int:
		return _level.value
	func clear_level() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_level.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_level(value : int) -> void:
		_level.value = value
	
	var _gold: PBField
	func get_gold() -> int:
		return _gold.value
	func clear_gold() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_gold.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_gold(value : int) -> void:
		_gold.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class RecommendFriends:
	func _init():
		var service
		
		_uids = PBField.new("uids", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 1, true, [])
		service = PBServiceField.new()
		service.field = _uids
		data[_uids.tag] = service
		
		_names = PBField.new("names", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 2, true, [])
		service = PBServiceField.new()
		service.field = _names
		data[_names.tag] = service
		
		_avatars = PBField.new("avatars", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 3, true, [])
		service = PBServiceField.new()
		service.field = _avatars
		data[_avatars.tag] = service
		
		_levels = PBField.new("levels", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 4, true, [])
		service = PBServiceField.new()
		service.field = _levels
		data[_levels.tag] = service
		
		_golds = PBField.new("golds", PB_DATA_TYPE.INT64, PB_RULE.REPEATED, 5, true, [])
		service = PBServiceField.new()
		service.field = _golds
		data[_golds.tag] = service
		
	var data = {}
	
	var _uids: PBField
	func get_uids() -> Array:
		return _uids.value
	func clear_uids() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uids.value = []
	func add_uids(value : int) -> void:
		_uids.value.append(value)
	
	var _names: PBField
	func get_names() -> Array:
		return _names.value
	func clear_names() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_names.value = []
	func add_names(value : String) -> void:
		_names.value.append(value)
	
	var _avatars: PBField
	func get_avatars() -> Array:
		return _avatars.value
	func clear_avatars() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_avatars.value = []
	func add_avatars(value : String) -> void:
		_avatars.value.append(value)
	
	var _levels: PBField
	func get_levels() -> Array:
		return _levels.value
	func clear_levels() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_levels.value = []
	func add_levels(value : int) -> void:
		_levels.value.append(value)
	
	var _golds: PBField
	func get_golds() -> Array:
		return _golds.value
	func clear_golds() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_golds.value = []
	func add_golds(value : int) -> void:
		_golds.value.append(value)
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PaymentAppleConsume:
	func _init():
		var service
		
		_pack_id = PBField.new("pack_id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _pack_id
		data[_pack_id.tag] = service
		
		_receipt_data = PBField.new("receipt_data", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _receipt_data
		data[_receipt_data.tag] = service
		
	var data = {}
	
	var _pack_id: PBField
	func get_pack_id() -> String:
		return _pack_id.value
	func clear_pack_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_pack_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_pack_id(value : String) -> void:
		_pack_id.value = value
	
	var _receipt_data: PBField
	func get_receipt_data() -> String:
		return _receipt_data.value
	func clear_receipt_data() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_receipt_data.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_receipt_data(value : String) -> void:
		_receipt_data.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PaymentFinishedAppleTransaction:
	func _init():
		var service
		
		_pack_id = PBField.new("pack_id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _pack_id
		data[_pack_id.tag] = service
		
	var data = {}
	
	var _pack_id: PBField
	func get_pack_id() -> String:
		return _pack_id.value
	func clear_pack_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_pack_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_pack_id(value : String) -> void:
		_pack_id.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class NewRound:
	func _init():
		var service
		
		_current_round = PBField.new("current_round", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _current_round
		data[_current_round.tag] = service
		
		_pot_value = PBField.new("pot_value", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = _pot_value
		data[_pot_value.tag] = service
		
		_players_gold = PBField.new("players_gold", PB_DATA_TYPE.INT64, PB_RULE.REPEATED, 3, true, [])
		service = PBServiceField.new()
		service.field = _players_gold
		data[_players_gold.tag] = service
		
	var data = {}
	
	var _current_round: PBField
	func get_current_round() -> int:
		return _current_round.value
	func clear_current_round() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_current_round.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_current_round(value : int) -> void:
		_current_round.value = value
	
	var _pot_value: PBField
	func get_pot_value() -> int:
		return _pot_value.value
	func clear_pot_value() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_pot_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_pot_value(value : int) -> void:
		_pot_value.value = value
	
	var _players_gold: PBField
	func get_players_gold() -> Array:
		return _players_gold.value
	func clear_players_gold() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_players_gold.value = []
	func add_players_gold(value : int) -> void:
		_players_gold.value.append(value)
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class CreateTable:
	func _init():
		var service
		
		_bet = PBField.new("bet", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _bet
		data[_bet.tag] = service
		
		_player_mode = PBField.new("player_mode", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _player_mode
		data[_player_mode.tag] = service
		
		_is_private = PBField.new("is_private", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _is_private
		data[_is_private.tag] = service
		
		_point_mode = PBField.new("point_mode", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _point_mode
		data[_point_mode.tag] = service
		
		_bet_mode = PBField.new("bet_mode", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _bet_mode
		data[_bet_mode.tag] = service
		
	var data = {}
	
	var _bet: PBField
	func get_bet() -> int:
		return _bet.value
	func clear_bet() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_bet.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_bet(value : int) -> void:
		_bet.value = value
	
	var _player_mode: PBField
	func get_player_mode() -> int:
		return _player_mode.value
	func clear_player_mode() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_player_mode.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_player_mode(value : int) -> void:
		_player_mode.value = value
	
	var _is_private: PBField
	func get_is_private() -> bool:
		return _is_private.value
	func clear_is_private() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_is_private.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_is_private(value : bool) -> void:
		_is_private.value = value
	
	var _point_mode: PBField
	func get_point_mode() -> int:
		return _point_mode.value
	func clear_point_mode() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_point_mode.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_point_mode(value : int) -> void:
		_point_mode.value = value
	
	var _bet_mode: PBField
	func get_bet_mode() -> bool:
		return _bet_mode.value
	func clear_bet_mode() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_bet_mode.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_bet_mode(value : bool) -> void:
		_bet_mode.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class JoinTableById:
	func _init():
		var service
		
		_match_id = PBField.new("match_id", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _match_id
		data[_match_id.tag] = service
		
	var data = {}
	
	var _match_id: PBField
	func get_match_id() -> int:
		return _match_id.value
	func clear_match_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_match_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_match_id(value : int) -> void:
		_match_id.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class JoinTableResponse:
	func _init():
		var service
		
		_error = PBField.new("error", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _error
		data[_error.tag] = service
		
	var data = {}
	
	var _error: PBField
	func get_error() -> int:
		return _error.value
	func clear_error() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_error.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_error(value : int) -> void:
		_error.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class ClaimSupport:
	func _init():
		var service
		
		_support_amount = PBField.new("support_amount", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _support_amount
		data[_support_amount.tag] = service
		
	var data = {}
	
	var _support_amount: PBField
	func get_support_amount() -> int:
		return _support_amount.value
	func clear_support_amount() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_support_amount.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_support_amount(value : int) -> void:
		_support_amount.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class AppCodeVersion:
	func _init():
		var service
		
		_android_version = PBField.new("android_version", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _android_version
		data[_android_version.tag] = service
		
		_android_forced_update_version = PBField.new("android_forced_update_version", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _android_forced_update_version
		data[_android_forced_update_version.tag] = service
		
		_android_remind_update_version = PBField.new("android_remind_update_version", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _android_remind_update_version
		data[_android_remind_update_version.tag] = service
		
		_ios_version = PBField.new("ios_version", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _ios_version
		data[_ios_version.tag] = service
		
		_ios_forced_update_version = PBField.new("ios_forced_update_version", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _ios_forced_update_version
		data[_ios_forced_update_version.tag] = service
		
		_ios_remind_update_version = PBField.new("ios_remind_update_version", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _ios_remind_update_version
		data[_ios_remind_update_version.tag] = service
		
		_ios_reviewing_version = PBField.new("ios_reviewing_version", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _ios_reviewing_version
		data[_ios_reviewing_version.tag] = service
		
	var data = {}
	
	var _android_version: PBField
	func get_android_version() -> int:
		return _android_version.value
	func clear_android_version() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_android_version.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_android_version(value : int) -> void:
		_android_version.value = value
	
	var _android_forced_update_version: PBField
	func get_android_forced_update_version() -> int:
		return _android_forced_update_version.value
	func clear_android_forced_update_version() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_android_forced_update_version.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_android_forced_update_version(value : int) -> void:
		_android_forced_update_version.value = value
	
	var _android_remind_update_version: PBField
	func get_android_remind_update_version() -> int:
		return _android_remind_update_version.value
	func clear_android_remind_update_version() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_android_remind_update_version.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_android_remind_update_version(value : int) -> void:
		_android_remind_update_version.value = value
	
	var _ios_version: PBField
	func get_ios_version() -> int:
		return _ios_version.value
	func clear_ios_version() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_ios_version.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_ios_version(value : int) -> void:
		_ios_version.value = value
	
	var _ios_forced_update_version: PBField
	func get_ios_forced_update_version() -> int:
		return _ios_forced_update_version.value
	func clear_ios_forced_update_version() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_ios_forced_update_version.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_ios_forced_update_version(value : int) -> void:
		_ios_forced_update_version.value = value
	
	var _ios_remind_update_version: PBField
	func get_ios_remind_update_version() -> int:
		return _ios_remind_update_version.value
	func clear_ios_remind_update_version() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_ios_remind_update_version.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_ios_remind_update_version(value : int) -> void:
		_ios_remind_update_version.value = value
	
	var _ios_reviewing_version: PBField
	func get_ios_reviewing_version() -> int:
		return _ios_reviewing_version.value
	func clear_ios_reviewing_version() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_ios_reviewing_version.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_ios_reviewing_version(value : int) -> void:
		_ios_reviewing_version.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PlayCardResponse:
	func _init():
		var service
		
		_status = PBField.new("status", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _status
		data[_status.tag] = service
		
	var data = {}
	
	var _status: PBField
	func get_status() -> int:
		return _status.value
	func clear_status() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_status.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_status(value : int) -> void:
		_status.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class CheatViewCardBot:
	func _init():
		var service
		
		_cards = PBField.new("cards", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 1, true, [])
		service = PBServiceField.new()
		service.field = _cards
		data[_cards.tag] = service
		
	var data = {}
	
	var _cards: PBField
	func get_cards() -> Array:
		return _cards.value
	func clear_cards() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_cards.value = []
	func add_cards(value : int) -> void:
		_cards.value.append(value)
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class InviteFriendPlay:
	func _init():
		var service
		
		_uid = PBField.new("uid", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _uid
		data[_uid.tag] = service
		
		_room_id = PBField.new("room_id", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _room_id
		data[_room_id.tag] = service
		
	var data = {}
	
	var _uid: PBField
	func get_uid() -> int:
		return _uid.value
	func clear_uid() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_uid(value : int) -> void:
		_uid.value = value
	
	var _room_id: PBField
	func get_room_id() -> int:
		return _room_id.value
	func clear_room_id() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_room_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_room_id(value : int) -> void:
		_room_id.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class GameActionNapoli:
	func _init():
		var service
		
		_uid = PBField.new("uid", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _uid
		data[_uid.tag] = service
		
		_point_add = PBField.new("point_add", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _point_add
		data[_point_add.tag] = service
		
		_suits = PBField.new("suits", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 3, true, [])
		service = PBServiceField.new()
		service.field = _suits
		data[_suits.tag] = service
		
	var data = {}
	
	var _uid: PBField
	func get_uid() -> int:
		return _uid.value
	func clear_uid() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_uid(value : int) -> void:
		_uid.value = value
	
	var _point_add: PBField
	func get_point_add() -> int:
		return _point_add.value
	func clear_point_add() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_point_add.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_point_add(value : int) -> void:
		_point_add.value = value
	
	var _suits: PBField
	func get_suits() -> Array:
		return _suits.value
	func clear_suits() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_suits.value = []
	func add_suits(value : int) -> void:
		_suits.value.append(value)
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class CustomerServiceReport:
	func _init():
		var service
		
		_report_type = PBField.new("report_type", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _report_type
		data[_report_type.tag] = service
		
		_report_content = PBField.new("report_content", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _report_content
		data[_report_content.tag] = service
		
	var data = {}
	
	var _report_type: PBField
	func get_report_type() -> int:
		return _report_type.value
	func clear_report_type() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_report_type.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_report_type(value : int) -> void:
		_report_type.value = value
	
	var _report_content: PBField
	func get_report_content() -> String:
		return _report_content.value
	func clear_report_content() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_report_content.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_report_content(value : String) -> void:
		_report_content.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class AdminBroadcast:
	func _init():
		var service
		
		_mes = PBField.new("mes", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _mes
		data[_mes.tag] = service
		
	var data = {}
	
	var _mes: PBField
	func get_mes() -> String:
		return _mes.value
	func clear_mes() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_mes.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_mes(value : String) -> void:
		_mes.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PaymentPaypalRequestOrder:
	func _init():
		var service
		
		_pack_id = PBField.new("pack_id", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _pack_id
		data[_pack_id.tag] = service
		
	var data = {}
	
	var _pack_id: PBField
	func get_pack_id() -> String:
		return _pack_id.value
	func clear_pack_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_pack_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_pack_id(value : String) -> void:
		_pack_id.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class PaymentPaypalOrder:
	func _init():
		var service
		
		_order_url = PBField.new("order_url", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _order_url
		data[_order_url.tag] = service
		
	var data = {}
	
	var _order_url: PBField
	func get_order_url() -> String:
		return _order_url.value
	func clear_order_url() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_order_url.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_order_url(value : String) -> void:
		_order_url.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class QuickPlay:
	func _init():
		var service
		
	var data = {}
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class SetteMezzoNewUserJoinMatch:
	func _init():
		var service
		
		_uid = PBField.new("uid", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _uid
		data[_uid.tag] = service
		
		_gold = PBField.new("gold", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = _gold
		data[_gold.tag] = service
		
		_name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _name
		data[_name.tag] = service
		
		_seat_server = PBField.new("seat_server", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 4, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _seat_server
		data[_seat_server.tag] = service
		
		_team_id = PBField.new("team_id", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 5, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _team_id
		data[_team_id.tag] = service
		
		_avatar = PBField.new("avatar", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 6, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _avatar
		data[_avatar.tag] = service
		
	var data = {}
	
	var _uid: PBField
	func get_uid() -> int:
		return _uid.value
	func clear_uid() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_uid(value : int) -> void:
		_uid.value = value
	
	var _gold: PBField
	func get_gold() -> int:
		return _gold.value
	func clear_gold() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_gold.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_gold(value : int) -> void:
		_gold.value = value
	
	var _name: PBField
	func get_name() -> String:
		return _name.value
	func clear_name() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		_name.value = value
	
	var _seat_server: PBField
	func get_seat_server() -> int:
		return _seat_server.value
	func clear_seat_server() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_seat_server.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_seat_server(value : int) -> void:
		_seat_server.value = value
	
	var _team_id: PBField
	func get_team_id() -> int:
		return _team_id.value
	func clear_team_id() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_team_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_team_id(value : int) -> void:
		_team_id.value = value
	
	var _avatar: PBField
	func get_avatar() -> String:
		return _avatar.value
	func clear_avatar() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_avatar.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_avatar(value : String) -> void:
		_avatar.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class SetteMezzoPrepareStartGame:
	func _init():
		var service
		
		_pot_value = PBField.new("pot_value", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _pot_value
		data[_pot_value.tag] = service
		
		_players_gold = PBField.new("players_gold", PB_DATA_TYPE.INT64, PB_RULE.REPEATED, 2, true, [])
		service = PBServiceField.new()
		service.field = _players_gold
		data[_players_gold.tag] = service
		
	var data = {}
	
	var _pot_value: PBField
	func get_pot_value() -> int:
		return _pot_value.value
	func clear_pot_value() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_pot_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_pot_value(value : int) -> void:
		_pot_value.value = value
	
	var _players_gold: PBField
	func get_players_gold() -> Array:
		return _players_gold.value
	func clear_players_gold() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_players_gold.value = []
	func add_players_gold(value : int) -> void:
		_players_gold.value.append(value)
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class SetteMezzoGameInfo:
	func _init():
		var service
		
		_match_id = PBField.new("match_id", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _match_id
		data[_match_id.tag] = service
		
		_game_mode = PBField.new("game_mode", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _game_mode
		data[_game_mode.tag] = service
		
		_player_mode = PBField.new("player_mode", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _player_mode
		data[_player_mode.tag] = service
		
		_uids = PBField.new("uids", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 4, true, [])
		service = PBServiceField.new()
		service.field = _uids
		data[_uids.tag] = service
		
		_user_golds = PBField.new("user_golds", PB_DATA_TYPE.INT64, PB_RULE.REPEATED, 5, true, [])
		service = PBServiceField.new()
		service.field = _user_golds
		data[_user_golds.tag] = service
		
		_user_names = PBField.new("user_names", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 6, true, [])
		service = PBServiceField.new()
		service.field = _user_names
		data[_user_names.tag] = service
		
		_banker_uid = PBField.new("banker_uid", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 7, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _banker_uid
		data[_banker_uid.tag] = service
		
		_current_turn = PBField.new("current_turn", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 8, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _current_turn
		data[_current_turn.tag] = service
		
		_game_state = PBField.new("game_state", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _game_state
		data[_game_state.tag] = service
		
		_user_points = PBField.new("user_points", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 11, true, [])
		service = PBServiceField.new()
		service.field = _user_points
		data[_user_points.tag] = service
		
		_team_ids = PBField.new("team_ids", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 12, true, [])
		service = PBServiceField.new()
		service.field = _team_ids
		data[_team_ids.tag] = service
		
		_hand_suit = PBField.new("hand_suit", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 13, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _hand_suit
		data[_hand_suit.tag] = service
		
		_avatars = PBField.new("avatars", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 14, true, [])
		service = PBServiceField.new()
		service.field = _avatars
		data[_avatars.tag] = service
		
		_is_registered_leave = PBField.new("is_registered_leave", PB_DATA_TYPE.BOOL, PB_RULE.OPTIONAL, 15, true, DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL])
		service = PBServiceField.new()
		service.field = _is_registered_leave
		data[_is_registered_leave.tag] = service
		
		_bet = PBField.new("bet", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 16, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _bet
		data[_bet.tag] = service
		
		_pot_value = PBField.new("pot_value", PB_DATA_TYPE.INT64, PB_RULE.OPTIONAL, 17, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT64])
		service = PBServiceField.new()
		service.field = _pot_value
		data[_pot_value.tag] = service
		
		_current_round = PBField.new("current_round", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 18, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _current_round
		data[_current_round.tag] = service
		
		_hand_in_round = PBField.new("hand_in_round", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 19, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _hand_in_round
		data[_hand_in_round.tag] = service
		
		_is_in_games = PBField.new("is_in_games", PB_DATA_TYPE.BOOL, PB_RULE.REPEATED, 20, true, [])
		service = PBServiceField.new()
		service.field = _is_in_games
		data[_is_in_games.tag] = service
		
		_play_turn_time = PBField.new("play_turn_time", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 21, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _play_turn_time
		data[_play_turn_time.tag] = service
		
		_player_infos = PBField.new("player_infos", PB_DATA_TYPE.BYTES, PB_RULE.REPEATED, 22, true, [])
		service = PBServiceField.new()
		service.field = _player_infos
		data[_player_infos.tag] = service
		
		_banker_cards = PBField.new("banker_cards", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 23, true, [])
		service = PBServiceField.new()
		service.field = _banker_cards
		data[_banker_cards.tag] = service
		
	var data = {}
	
	var _match_id: PBField
	func get_match_id() -> int:
		return _match_id.value
	func clear_match_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_match_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_match_id(value : int) -> void:
		_match_id.value = value
	
	var _game_mode: PBField
	func get_game_mode() -> int:
		return _game_mode.value
	func clear_game_mode() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_game_mode.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_game_mode(value : int) -> void:
		_game_mode.value = value
	
	var _player_mode: PBField
	func get_player_mode() -> int:
		return _player_mode.value
	func clear_player_mode() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_player_mode.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_player_mode(value : int) -> void:
		_player_mode.value = value
	
	var _uids: PBField
	func get_uids() -> Array:
		return _uids.value
	func clear_uids() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_uids.value = []
	func add_uids(value : int) -> void:
		_uids.value.append(value)
	
	var _user_golds: PBField
	func get_user_golds() -> Array:
		return _user_golds.value
	func clear_user_golds() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_user_golds.value = []
	func add_user_golds(value : int) -> void:
		_user_golds.value.append(value)
	
	var _user_names: PBField
	func get_user_names() -> Array:
		return _user_names.value
	func clear_user_names() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_user_names.value = []
	func add_user_names(value : String) -> void:
		_user_names.value.append(value)
	
	var _banker_uid: PBField
	func get_banker_uid() -> int:
		return _banker_uid.value
	func clear_banker_uid() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_banker_uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_banker_uid(value : int) -> void:
		_banker_uid.value = value
	
	var _current_turn: PBField
	func get_current_turn() -> int:
		return _current_turn.value
	func clear_current_turn() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_current_turn.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_current_turn(value : int) -> void:
		_current_turn.value = value
	
	var _game_state: PBField
	func get_game_state() -> int:
		return _game_state.value
	func clear_game_state() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_game_state.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_game_state(value : int) -> void:
		_game_state.value = value
	
	var _user_points: PBField
	func get_user_points() -> Array:
		return _user_points.value
	func clear_user_points() -> void:
		data[11].state = PB_SERVICE_STATE.UNFILLED
		_user_points.value = []
	func add_user_points(value : int) -> void:
		_user_points.value.append(value)
	
	var _team_ids: PBField
	func get_team_ids() -> Array:
		return _team_ids.value
	func clear_team_ids() -> void:
		data[12].state = PB_SERVICE_STATE.UNFILLED
		_team_ids.value = []
	func add_team_ids(value : int) -> void:
		_team_ids.value.append(value)
	
	var _hand_suit: PBField
	func get_hand_suit() -> int:
		return _hand_suit.value
	func clear_hand_suit() -> void:
		data[13].state = PB_SERVICE_STATE.UNFILLED
		_hand_suit.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_hand_suit(value : int) -> void:
		_hand_suit.value = value
	
	var _avatars: PBField
	func get_avatars() -> Array:
		return _avatars.value
	func clear_avatars() -> void:
		data[14].state = PB_SERVICE_STATE.UNFILLED
		_avatars.value = []
	func add_avatars(value : String) -> void:
		_avatars.value.append(value)
	
	var _is_registered_leave: PBField
	func get_is_registered_leave() -> bool:
		return _is_registered_leave.value
	func clear_is_registered_leave() -> void:
		data[15].state = PB_SERVICE_STATE.UNFILLED
		_is_registered_leave.value = DEFAULT_VALUES_3[PB_DATA_TYPE.BOOL]
	func set_is_registered_leave(value : bool) -> void:
		_is_registered_leave.value = value
	
	var _bet: PBField
	func get_bet() -> int:
		return _bet.value
	func clear_bet() -> void:
		data[16].state = PB_SERVICE_STATE.UNFILLED
		_bet.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_bet(value : int) -> void:
		_bet.value = value
	
	var _pot_value: PBField
	func get_pot_value() -> int:
		return _pot_value.value
	func clear_pot_value() -> void:
		data[17].state = PB_SERVICE_STATE.UNFILLED
		_pot_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT64]
	func set_pot_value(value : int) -> void:
		_pot_value.value = value
	
	var _current_round: PBField
	func get_current_round() -> int:
		return _current_round.value
	func clear_current_round() -> void:
		data[18].state = PB_SERVICE_STATE.UNFILLED
		_current_round.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_current_round(value : int) -> void:
		_current_round.value = value
	
	var _hand_in_round: PBField
	func get_hand_in_round() -> int:
		return _hand_in_round.value
	func clear_hand_in_round() -> void:
		data[19].state = PB_SERVICE_STATE.UNFILLED
		_hand_in_round.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_hand_in_round(value : int) -> void:
		_hand_in_round.value = value
	
	var _is_in_games: PBField
	func get_is_in_games() -> Array:
		return _is_in_games.value
	func clear_is_in_games() -> void:
		data[20].state = PB_SERVICE_STATE.UNFILLED
		_is_in_games.value = []
	func add_is_in_games(value : bool) -> void:
		_is_in_games.value.append(value)
	
	var _play_turn_time: PBField
	func get_play_turn_time() -> int:
		return _play_turn_time.value
	func clear_play_turn_time() -> void:
		data[21].state = PB_SERVICE_STATE.UNFILLED
		_play_turn_time.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_play_turn_time(value : int) -> void:
		_play_turn_time.value = value
	
	var _player_infos: PBField
	func get_player_infos() -> Array:
		return _player_infos.value
	func clear_player_infos() -> void:
		data[22].state = PB_SERVICE_STATE.UNFILLED
		_player_infos.value = []
	func add_player_infos(value : PackedByteArray) -> void:
		_player_infos.value.append(value)
	
	var _banker_cards: PBField
	func get_banker_cards() -> Array:
		return _banker_cards.value
	func clear_banker_cards() -> void:
		data[23].state = PB_SERVICE_STATE.UNFILLED
		_banker_cards.value = []
	func add_banker_cards(value : int) -> void:
		_banker_cards.value.append(value)
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class SetteMezzoPlayerInfo:
	func _init():
		var service
		
		_card_ids = PBField.new("card_ids", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 1, true, [])
		service = PBServiceField.new()
		service.field = _card_ids
		data[_card_ids.tag] = service
		
	var data = {}
	
	var _card_ids: PBField
	func get_card_ids() -> Array:
		return _card_ids.value
	func clear_card_ids() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_card_ids.value = []
	func add_card_ids(value : int) -> void:
		_card_ids.value.append(value)
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class SetteMezzoQuickPlay:
	func _init():
		var service
		
	var data = {}
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class SetteMezzoStartGame:
	func _init():
		var service
		
		_pot_value = PBField.new("pot_value", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _pot_value
		data[_pot_value.tag] = service
		
		_players_gold = PBField.new("players_gold", PB_DATA_TYPE.INT64, PB_RULE.REPEATED, 2, true, [])
		service = PBServiceField.new()
		service.field = _players_gold
		data[_players_gold.tag] = service
		
		_uids = PBField.new("uids", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 3, true, [])
		service = PBServiceField.new()
		service.field = _uids
		data[_uids.tag] = service
		
		_cards = PBField.new("cards", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 4, true, [])
		service = PBServiceField.new()
		service.field = _cards
		data[_cards.tag] = service
		
	var data = {}
	
	var _pot_value: PBField
	func get_pot_value() -> int:
		return _pot_value.value
	func clear_pot_value() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_pot_value.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_pot_value(value : int) -> void:
		_pot_value.value = value
	
	var _players_gold: PBField
	func get_players_gold() -> Array:
		return _players_gold.value
	func clear_players_gold() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_players_gold.value = []
	func add_players_gold(value : int) -> void:
		_players_gold.value.append(value)
	
	var _uids: PBField
	func get_uids() -> Array:
		return _uids.value
	func clear_uids() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_uids.value = []
	func add_uids(value : int) -> void:
		_uids.value.append(value)
	
	var _cards: PBField
	func get_cards() -> Array:
		return _cards.value
	func clear_cards() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_cards.value = []
	func add_cards(value : int) -> void:
		_cards.value.append(value)
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class RankingInfo:
	func _init():
		var service
		
		_season_id = PBField.new("season_id", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _season_id
		data[_season_id.tag] = service
		
		_time_start = PBField.new("time_start", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _time_start
		data[_time_start.tag] = service
		
		_time_end = PBField.new("time_end", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _time_end
		data[_time_end.tag] = service
		
		_rewards = PBField.new("rewards", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 4, true, [])
		service = PBServiceField.new()
		service.field = _rewards
		data[_rewards.tag] = service
		
		_uids = PBField.new("uids", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 5, true, [])
		service = PBServiceField.new()
		service.field = _uids
		data[_uids.tag] = service
		
		_avatars = PBField.new("avatars", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 6, true, [])
		service = PBServiceField.new()
		service.field = _avatars
		data[_avatars.tag] = service
		
		_names = PBField.new("names", PB_DATA_TYPE.STRING, PB_RULE.REPEATED, 7, true, [])
		service = PBServiceField.new()
		service.field = _names
		data[_names.tag] = service
		
		_scores = PBField.new("scores", PB_DATA_TYPE.INT32, PB_RULE.REPEATED, 8, true, [])
		service = PBServiceField.new()
		service.field = _scores
		data[_scores.tag] = service
		
		_my_rank = PBField.new("my_rank", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 9, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _my_rank
		data[_my_rank.tag] = service
		
		_my_score = PBField.new("my_score", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 10, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _my_score
		data[_my_score.tag] = service
		
	var data = {}
	
	var _season_id: PBField
	func get_season_id() -> int:
		return _season_id.value
	func clear_season_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_season_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_season_id(value : int) -> void:
		_season_id.value = value
	
	var _time_start: PBField
	func get_time_start() -> int:
		return _time_start.value
	func clear_time_start() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_time_start.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_time_start(value : int) -> void:
		_time_start.value = value
	
	var _time_end: PBField
	func get_time_end() -> int:
		return _time_end.value
	func clear_time_end() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_time_end.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_time_end(value : int) -> void:
		_time_end.value = value
	
	var _rewards: PBField
	func get_rewards() -> Array:
		return _rewards.value
	func clear_rewards() -> void:
		data[4].state = PB_SERVICE_STATE.UNFILLED
		_rewards.value = []
	func add_rewards(value : int) -> void:
		_rewards.value.append(value)
	
	var _uids: PBField
	func get_uids() -> Array:
		return _uids.value
	func clear_uids() -> void:
		data[5].state = PB_SERVICE_STATE.UNFILLED
		_uids.value = []
	func add_uids(value : int) -> void:
		_uids.value.append(value)
	
	var _avatars: PBField
	func get_avatars() -> Array:
		return _avatars.value
	func clear_avatars() -> void:
		data[6].state = PB_SERVICE_STATE.UNFILLED
		_avatars.value = []
	func add_avatars(value : String) -> void:
		_avatars.value.append(value)
	
	var _names: PBField
	func get_names() -> Array:
		return _names.value
	func clear_names() -> void:
		data[7].state = PB_SERVICE_STATE.UNFILLED
		_names.value = []
	func add_names(value : String) -> void:
		_names.value.append(value)
	
	var _scores: PBField
	func get_scores() -> Array:
		return _scores.value
	func clear_scores() -> void:
		data[8].state = PB_SERVICE_STATE.UNFILLED
		_scores.value = []
	func add_scores(value : int) -> void:
		_scores.value.append(value)
	
	var _my_rank: PBField
	func get_my_rank() -> int:
		return _my_rank.value
	func clear_my_rank() -> void:
		data[9].state = PB_SERVICE_STATE.UNFILLED
		_my_rank.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_my_rank(value : int) -> void:
		_my_rank.value = value
	
	var _my_score: PBField
	func get_my_score() -> int:
		return _my_score.value
	func clear_my_score() -> void:
		data[10].state = PB_SERVICE_STATE.UNFILLED
		_my_score.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_my_score(value : int) -> void:
		_my_score.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class RankingResult:
	func _init():
		var service
		
		_season_id = PBField.new("season_id", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _season_id
		data[_season_id.tag] = service
		
		_gold_reward = PBField.new("gold_reward", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _gold_reward
		data[_gold_reward.tag] = service
		
		_rank = PBField.new("rank", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _rank
		data[_rank.tag] = service
		
	var data = {}
	
	var _season_id: PBField
	func get_season_id() -> int:
		return _season_id.value
	func clear_season_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_season_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_season_id(value : int) -> void:
		_season_id.value = value
	
	var _gold_reward: PBField
	func get_gold_reward() -> int:
		return _gold_reward.value
	func clear_gold_reward() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_gold_reward.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_gold_reward(value : int) -> void:
		_gold_reward.value = value
	
	var _rank: PBField
	func get_rank() -> int:
		return _rank.value
	func clear_rank() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_rank.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_rank(value : int) -> void:
		_rank.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class RankingClaimReward:
	func _init():
		var service
		
		_season_id = PBField.new("season_id", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _season_id
		data[_season_id.tag] = service
		
	var data = {}
	
	var _season_id: PBField
	func get_season_id() -> int:
		return _season_id.value
	func clear_season_id() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_season_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_season_id(value : int) -> void:
		_season_id.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class UpdateAds:
	func _init():
		var service
		
		_time_show_ads = PBField.new("time_show_ads", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _time_show_ads
		data[_time_show_ads.tag] = service
		
	var data = {}
	
	var _time_show_ads: PBField
	func get_time_show_ads() -> int:
		return _time_show_ads.value
	func clear_time_show_ads() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_time_show_ads.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_time_show_ads(value : int) -> void:
		_time_show_ads.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class AdsReward:
	func _init():
		var service
		
		_gold = PBField.new("gold", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _gold
		data[_gold.tag] = service
		
		_time_ads_reward = PBField.new("time_ads_reward", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _time_ads_reward
		data[_time_ads_reward.tag] = service
		
	var data = {}
	
	var _gold: PBField
	func get_gold() -> int:
		return _gold.value
	func clear_gold() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_gold.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_gold(value : int) -> void:
		_gold.value = value
	
	var _time_ads_reward: PBField
	func get_time_ads_reward() -> int:
		return _time_ads_reward.value
	func clear_time_ads_reward() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_time_ads_reward.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_time_ads_reward(value : int) -> void:
		_time_ads_reward.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class ChangeUserName:
	func _init():
		var service
		
		_name = PBField.new("name", PB_DATA_TYPE.STRING, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.STRING])
		service = PBServiceField.new()
		service.field = _name
		data[_name.tag] = service
		
	var data = {}
	
	var _name: PBField
	func get_name() -> String:
		return _name.value
	func clear_name() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_name.value = DEFAULT_VALUES_3[PB_DATA_TYPE.STRING]
	func set_name(value : String) -> void:
		_name.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class SetteMezzoActionHit:
	func _init():
		var service
		
		_uid = PBField.new("uid", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _uid
		data[_uid.tag] = service
		
		_card_id = PBField.new("card_id", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _card_id
		data[_card_id.tag] = service
		
	var data = {}
	
	var _uid: PBField
	func get_uid() -> int:
		return _uid.value
	func clear_uid() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_uid(value : int) -> void:
		_uid.value = value
	
	var _card_id: PBField
	func get_card_id() -> int:
		return _card_id.value
	func clear_card_id() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_card_id.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_card_id(value : int) -> void:
		_card_id.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class SetteMezzoUpdateTurn:
	func _init():
		var service
		
		_current_turn = PBField.new("current_turn", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _current_turn
		data[_current_turn.tag] = service
		
		_play_turn_time = PBField.new("play_turn_time", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _play_turn_time
		data[_play_turn_time.tag] = service
		
	var data = {}
	
	var _current_turn: PBField
	func get_current_turn() -> int:
		return _current_turn.value
	func clear_current_turn() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_current_turn.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_current_turn(value : int) -> void:
		_current_turn.value = value
	
	var _play_turn_time: PBField
	func get_play_turn_time() -> int:
		return _play_turn_time.value
	func clear_play_turn_time() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_play_turn_time.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_play_turn_time(value : int) -> void:
		_play_turn_time.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
class SetteMezzoActionStand:
	func _init():
		var service
		
		_uid = PBField.new("uid", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 1, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _uid
		data[_uid.tag] = service
		
		_current_turn = PBField.new("current_turn", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 2, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _current_turn
		data[_current_turn.tag] = service
		
		_play_turn_time = PBField.new("play_turn_time", PB_DATA_TYPE.INT32, PB_RULE.OPTIONAL, 3, true, DEFAULT_VALUES_3[PB_DATA_TYPE.INT32])
		service = PBServiceField.new()
		service.field = _play_turn_time
		data[_play_turn_time.tag] = service
		
	var data = {}
	
	var _uid: PBField
	func get_uid() -> int:
		return _uid.value
	func clear_uid() -> void:
		data[1].state = PB_SERVICE_STATE.UNFILLED
		_uid.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_uid(value : int) -> void:
		_uid.value = value
	
	var _current_turn: PBField
	func get_current_turn() -> int:
		return _current_turn.value
	func clear_current_turn() -> void:
		data[2].state = PB_SERVICE_STATE.UNFILLED
		_current_turn.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_current_turn(value : int) -> void:
		_current_turn.value = value
	
	var _play_turn_time: PBField
	func get_play_turn_time() -> int:
		return _play_turn_time.value
	func clear_play_turn_time() -> void:
		data[3].state = PB_SERVICE_STATE.UNFILLED
		_play_turn_time.value = DEFAULT_VALUES_3[PB_DATA_TYPE.INT32]
	func set_play_turn_time(value : int) -> void:
		_play_turn_time.value = value
	
	func _to_string() -> String:
		return PBPacker.message_to_string(data)
		
	func to_bytes() -> PackedByteArray:
		return PBPacker.pack_message(data)
		
	func from_bytes(bytes : PackedByteArray, offset : int = 0, limit : int = -1) -> int:
		var cur_limit = bytes.size()
		if limit != -1:
			cur_limit = limit
		var result = PBPacker.unpack_message(data, bytes, offset, cur_limit)
		if result == cur_limit:
			if PBPacker.check_required(data):
				if limit == -1:
					return PB_ERR.NO_ERRORS
			else:
				return PB_ERR.REQUIRED_FIELDS
		elif limit == -1 && result > 0:
			return PB_ERR.PARSE_INCOMPLETE
		return result
	
################ USER DATA END #################
