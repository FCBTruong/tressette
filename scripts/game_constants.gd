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
	PING_PONG = 0,
	LOGIN = 1,
	TEST_MESSAGE = 100,
	GENERAL_INFO = 1000,
	USER_INFO = 1001,
	QUICK_PLAY = 2000,
	GAME_INFO = 2001,
	LEAVE_GAME = 2002
}

const PROTOBUF = {
	PACKETS = preload("res://scripts/protobuf/Packets.gd")
}
