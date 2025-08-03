extends RefCounted
class_name GameServerConfig


var time_thinking_in_turn: float = 5
var exp_levels = []
var fee_mode_no_bet: int
var level_rewards = []

func convert_exp_to_level(exp) -> int:
	var level = 1  # Default to level 1 if exp is below the first threshold
	for i in range(1, len(exp_levels)):
		if exp < exp_levels[i]:
			return level
		level += 1
	return level  # Return max level if exp is greater than the highest threshold

func is_max_level(level: int) -> bool:
	if level >= len(exp_levels) - 1:
		return true
	return false
	
func total_all_exp():
	var s = 0
	for e in exp_levels:
		s = s + e
	return s
