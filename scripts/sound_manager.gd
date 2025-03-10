extends Node
class_name SoundManager

var audio_player: AudioStreamPlayer
var music_player: AudioStreamPlayer
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	
	music_player = AudioStreamPlayer.new()  # Create an AudioStreamPlayer node
	add_child(music_player)  # Add to scene

var click_sound = preload("res://assets/sounds/touch_sound.mp3")
func play_click():
	if not g.v.game_manager.enable_sound:
		return
	audio_player.stream = click_sound
	audio_player.play()

var notification_alert_sound = preload('res://assets/sounds/notification_alert_sound.mp3')
func play_notification_alert():
	if not g.v.game_manager.enable_sound:
		return
	audio_player.stream = notification_alert_sound
	audio_player.play()


var win_congrat_sound = preload('res://assets/sounds/win_congrat_sound.mp3')
func play_win_congrat_sound():
	if not g.v.game_manager.enable_sound:
		return
	audio_player.stream = win_congrat_sound
	audio_player.play()
	
var lose_sound = preload('res://assets/sounds/lose_sound.mp3')
func play_lose_sound():
	if not g.v.game_manager.enable_sound:
		return
	audio_player.stream = lose_sound
	audio_player.play()
	
var coin_hit_sound = preload('res://assets/sounds/coin_hit_sound.wav')
func play_coin_hit_sound():
	if not g.v.game_manager.enable_sound:
		return
	audio_player.stream = coin_hit_sound
	audio_player.play()

var lobby_music = preload("res://assets/musics/lobby_music.mp3")
var board_music = preload("res://assets/musics/board_music.mp3")

var is_playing_music_lobby = false
func play_music_lobby():
	if not g.v.game_manager.enable_music:
		return
	if is_playing_music_lobby:
		return
	is_playing_music_lobby = true
	music_player.stop()
	music_player.volume_db = -10
	music_player.stream = lobby_music
	music_player.stream.loop = true
	music_player.play()
	
func play_music_board():
	if not g.v.game_manager.enable_music:
		return
	stop_music()
	music_player.volume_db = -10
	music_player.stream = board_music
	music_player.stream.loop = true
	music_player.play()
	
func stop_music():
	is_playing_music_lobby = false
	music_player.stop()
		
