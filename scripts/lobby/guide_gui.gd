extends Node

@onready var main_pn = find_child('MainPn')
@onready var close_btn = find_child("CloseBtn")
@onready var next_btn = find_child("NextBtn")
@onready var previous_btn = find_child("PreviousBtn")
@onready var card_strong_pn = find_child("CardStrongPn")
var tween
var pages = []
var current_idx = 0
var is_quick_play = false
var strong_cards = []
var cur_card_style
func _ready() -> void:
	cur_card_style = g.v.game_constants.CARD_STYLES.CLASSIC
	tween = create_tween()
	var default_pos = main_pn.position
	#main_pn.modulate.a = 0
	main_pn.position.y -= 600
	
	previous_btn.visible = false

	
	tween.parallel().tween_property(main_pn, 'position', default_pos, 0.3).set_ease(Tween.EASE_OUT)
	tween.tween_property(next_btn, "scale", Vector2(1.2, 1.2), 0.5).set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(next_btn, "scale", Vector2(1, 1), 0.5)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)  
	tween.tween_property(next_btn, "scale", Vector2(1.2, 1.2), 0.5).set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(next_btn, "scale", Vector2(1, 1), 0.5)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)  
	
	pages.append(find_child("Page1"))
	pages.append(find_child("Page2"))
	
	if current_idx == len(pages) - 1:
		self.next_btn.visible = false
	if current_idx == 0:
		self.previous_btn.visible = false
		
	for i in len(pages):
		if i == current_idx:
			pages[i].visible = true
		else:
			pages[i].visible = false
			
	for i in range(10):
		var card = card_strong_pn.find_child("CardStrong" + str(i))
		strong_cards.append(card)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func on_close() -> void:
	if tween and tween.is_running():
		tween.kill()
	self.queue_free()
	if is_quick_play:
		g.v.game_manager.send_quick_play()
		is_quick_play = false
	
func _click_next_page():
	current_idx += 1
	for p in pages:
		p.visible = false
	pages[current_idx].visible = true
	next_btn.visible = true
	if current_idx == len(pages) - 1:
		next_btn.visible = false
	previous_btn.visible = true

func _click_previous_page():
	current_idx -= 1
	for p in pages:
		p.visible = false
	pages[current_idx].visible = true
	previous_btn.visible = true
	if current_idx == 0:
		previous_btn.visible = false
	
	next_btn.visible = true

	pass


var strong_ids = [12, 16, 20, 24, 28, 32, 36, 0, 4, 8]
func on_show():
	if cur_card_style == g.v.game_manager.card_style:
		return
	else:
		cur_card_style = g.v.game_manager.card_style
	var path
	if g.v.game_manager.card_style == g.v.game_constants.CARD_STYLES.CLASSIC:
		path = "res://assets/images/card_tressette/classic/"
	elif g.v.game_manager.card_style == g.v.game_constants.CARD_STYLES.MODERN:
		path = "res://assets/images/card_tressette/modern/card_"


	for i in range(10):
		var p = path + str(strong_ids[i]) + ".png"
		strong_cards[i].texture = load(p)
	
	var napolis = [1, 5, 9]
	for j in range(3):
		find_child("NapoliCard" + str(j)).texture = load(path + str(napolis[j]) + ".png")
