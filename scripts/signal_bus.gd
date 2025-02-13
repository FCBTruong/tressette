extends Node

# Declare global signals
signal update_table_list
signal player_joined
signal game_started
signal on_picking_avatar
signal on_changed_avatar
signal on_update_money
signal update_friend_list
signal update_friend_requests
signal update_card_style

# Emit a signal globally with arguments
func emit_signal_global(signal_name: String, args: Array = []) -> void:
	if has_signal(signal_name):
		match args.size():
			0:
				emit_signal(signal_name)
			1:
				emit_signal(signal_name, args[0])
			2:
				emit_signal(signal_name, args[0], args[1])
			3:
				emit_signal(signal_name, args[0], args[1], args[2])
			_:
				push_error("Too many arguments for signal '%s'." % signal_name)
	else:
		push_error("Signal '%s' does not exist in SignalBus." % signal_name)

# Connect to a global signal using Callable
func connect_global(signal_name: String, callable: Callable) -> void:
	if has_signal(signal_name):
		connect(signal_name, callable)
	else:
		push_error("Signal '%s' does not exist in SignalBus." % signal_name)
