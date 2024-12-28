extends Node

static var game_logic = GameLogic.new()

func say_hello():
	print("hello")

const GAME_MODE = {
	TRESSETTE = 0,
	BRISCOLA = 1,
}

const PLAYER_MODE = {
	SOLO = 2,
	TEAM = 4
}

const CARDS = {
	CARDBACK = 52
}

const CMDs = {
	PING_PONG = 0
}
