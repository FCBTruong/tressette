extends Node

var audio_player: AudioStreamPlayer
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)

var click_sound = preload("res://assets/sounds/touch_sound.mp3")
func play_click():
	if not GameManager.enable_sound:
		return
	audio_player.stream = click_sound
	audio_player.play()

var notification_alert_sound = preload('res://assets/sounds/notification_alert_sound.mp3')
func play_notification_alert():
	if not GameManager.enable_sound:
		return
	audio_player.stream = notification_alert_sound
	audio_player.play()


var win_congrat_sound = preload('res://assets/sounds/win_congrat_sound.mp3')
func play_win_congrat_sound():
	if not GameManager.enable_sound:
		return
	audio_player.stream = win_congrat_sound
	audio_player.play()
	
var lose_sound = preload('res://assets/sounds/lose_sound.mp3')
func play_lose_sound():
	if not GameManager.enable_sound:
		return
	audio_player.stream = lose_sound
	audio_player.play()
