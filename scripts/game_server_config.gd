extends Node


var time_thinking_in_turn: int = 5
var tressette_bets = []
var exp_levels = []
var bet_multiplier_min = 1
var min_gold_play: int

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
