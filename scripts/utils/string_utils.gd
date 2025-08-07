extends RefCounted
class_name StringUtils


static func point_number(number: int) -> String:
	var number_str = str(number)
	var formatted = ""
	var count = 0

	# Check if the number is negative
	var is_negative = number < 0
	if is_negative:
		number_str = number_str.substr(1)  # Remove the negative sign for formatting

	# Format the number
	for i in range(number_str.length() - 1, -1, -1):
		formatted = number_str[i] + formatted
		count += 1
		if count % 3 == 0 and i != 0:
			formatted = "." + formatted

	# Re-add the negative sign if the number is negative
	if is_negative:
		formatted = "-" + formatted

	return formatted


static func symbol_number(num: int) -> String:
	var abs_num = abs(num)
	var prefix = "-" if num < 0 else ""
	if abs_num >= 1_000_000_000:
		return prefix + str(floor(abs_num / 1_000_000_000.0)) + "B"
	elif abs_num >= 1_000_000:
		return prefix + str(floor(abs_num / 1_000_000.0)) + "M"
	elif abs_num >= 1_000:
		return prefix + str(floor(abs_num / 1_000.0)) + "K"
	else:
		return str(num)

		
static func sub_string(str: String, size: int) -> String:
	if str.length() > size:
		return str.substr(0, size) + "..."
	return str
	
static func convert_point_string_to_int(point_str: String) -> int:
	# Remove all periods from the string
	var cleaned_str = point_str.replace(".", "")
	# Convert the cleaned string to an integer
	return cleaned_str.to_int()

# hours:minutes:seconds
static func format_time(time_remain: int) -> String:
	var hours = time_remain / 3600
	var minutes = (time_remain % 3600) / 60
	var seconds = time_remain % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

# 10h:10h:10m:10s
static func format_time2(time_remain: int) -> String:
	var total_seconds = time_remain
	var days = total_seconds / 86400
	var hours = (total_seconds % 86400) / 3600
	var minutes = (total_seconds % 3600) / 60
	var seconds = total_seconds % 60

	if days >= 1:
		return "%dd:%02dh:%02dm" % [days, hours, minutes]
	else:
		return "%02dh:%02dm:%02ds" % [hours, minutes, seconds]
