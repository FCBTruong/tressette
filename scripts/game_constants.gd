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
	LEAVE_GAME = 2002,
	NEW_USER_JOIN_MATCH = 2003,
	USER_LEAVE_MATCH = 2004,
	DEAL_CARD = 2005,
	PLAY_CARD = 2006,
	START_GAME = 2007,
	NEW_ROUND = 2008,
	END_ROUND = 2009
}

const PROTOBUF = {
	PACKETS = preload("res://scripts/protobuf/Packets.gd")
}
