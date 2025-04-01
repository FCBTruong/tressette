extends Control

var default_pos: Vector2

var LanguageConf = {
	'it': 1,
	'en': 0  # Index not ID
}

@onready var classic_card = find_child('ClassicCardBtn')
@onready var modern_card = find_child('ModernCardBtn')
@onready var check_icon_class = classic_card.find_child('CheckIcon')
@onready var check_icon_modern = modern_card.find_child('CheckIcon')
@onready var music_checker = find_child("MusicBtn")
@onready var sound_checker = find_child('SoundBtn')
@onready var option_language = find_child('OptionLanguage')
@onready var logout_btn = find_child("LogoutBtn")
@onready var remove_acc_btn = find_child("RemoveAccBtn")
func _ready() -> void:
	default_pos = $Panel.position
	
	# Shift X so we can tween back to default at startup
	$Panel.position.x += 300
	
	var tween = create_tween()
	tween.tween_property(
		$Panel,
		"position",
		default_pos,
		0.3
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	_update_choosing_card()
	
	sound_checker.button_pressed = g.v.game_manager.enable_sound
	music_checker.button_pressed = g.v.game_manager.enable_music
	
	var lang_idx = -1
	if g.v.game_manager.language == 'en':
		lang_idx = LanguageConf.get('en')
	elif g.v.game_manager.language == 'it':
		lang_idx = LanguageConf.get('it')
	option_language.select(lang_idx)
	
	var scene = g.v.scene_manager.get_current_scene()
	if scene is BoardScene:
		remove_acc_btn.visible = false
		logout_btn.visible = false
		
	

func _hide_gui() -> void:
	var tween = create_tween()
	tween.tween_property(
		$Panel,
		"position",
		default_pos + Vector2(300, 0),
		0.3
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	
	# This is the correct way in Godot 4 to connect the `finished` signal
	tween.finished.connect(_on_close_tween_finished)

func _on_close_tween_finished() -> void:
	hide()
	$Panel.position = default_pos

func _logout() -> void:
	g.v.game_client.send_packet(g.v.game_constants.CMDs.LOG_OUT, [])
	
func _choose_card_classic():
	g.v.game_manager.change_card_style(g.v.game_constants.CARD_STYLES.CLASSIC)
	_update_choosing_card()
	
func _choose_card_modern():
	g.v.game_manager.change_card_style(g.v.game_constants.CARD_STYLES.MODERN)
	_update_choosing_card()
	
func _update_choosing_card():
	var p = null
	if g.v.game_manager.card_style == g.v.game_constants.CARD_STYLES.CLASSIC:
		check_icon_class.visible = true
		check_icon_modern.visible = false
	else:
		check_icon_class.visible = false
		check_icon_modern.visible = true

func _click_sound():
	g.v.game_manager.set_enable_sound(sound_checker.button_pressed)
	pass
	
func _click_music():
	g.v.game_manager.set_enable_music(music_checker.button_pressed)
	pass
	
func _on_select_language_option(index):
	if index == LanguageConf.get('it'):
		# italy
		g.v.game_manager.choose_language('it')
	elif index == LanguageConf.get('en'):
		g.v.game_manager.choose_language('en')
		
func _remove_account():
	if g.v.config.get_platform() == g.v.config.PLATFORMS.IOS:
		g.v.scene_manager.open_gui("res://scenes/guis/AccountDeletion.tscn")
	else:
		OS.shell_open(g.v.game_constants.DELETE_ACCOUNT_URL)
		
func _click_privacy_policy():
	OS.shell_open(g.v.game_constants.PRIVACY_POLICY_URL)

func _click_terms_of_service():
	OS.shell_open(g.v.game_constants.TERMS_OF_SERVICE_URL)
