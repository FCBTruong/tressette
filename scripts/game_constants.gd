extends Node

static var game_logic = GameLogic.new()

func say_hello():
	print("hello")

const GAME_MODE = {
	TRESSETTE = 0,
	BRISCOLA = 1,
}

const CARDS = {
	CARDBACK = 52
}
