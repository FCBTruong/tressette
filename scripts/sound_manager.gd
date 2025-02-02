extends Node

var audio_player: AudioStreamPlayer
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)

var click_sound = preload("res://assets/sounds/touch_sound.wav")
func play_click():
	if not GameManager.enable_sound:
		return
	audio_player.stream = click_sound
	audio_player.play()
