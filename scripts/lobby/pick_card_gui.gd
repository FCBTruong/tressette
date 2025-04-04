extends Node

@onready var modern_card_btn = find_child("ModernCardBtn")
@onready var classic_card_btn = find_child("ClassicCardBtn")
@onready var main_pn = find_child("MainPn")
# Called when the node enters the scene tree for the first time.
var card_style = g.v.game_constants.CARD_STYLES.MODERN
func _ready() -> void:
	card_style = g.v.game_manager.card_style
	self.update_state()
	
	var tween = create_tween()
	main_pn.scale = Vector2(0, 0)
	main_pn.modulate.a = 0
	NodeUtils.set_center_pivot(self.main_pn)
	
	tween.parallel().tween_property(main_pn, 'scale', Vector2(1, 1), 0.5).set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(main_pn, 'modulate:a', 1, 0.5)

	
func update_state():
	if card_style == g.v.game_constants.CARD_STYLES.CLASSIC:
		modern_card_btn.find_child("CheckIcon").visible = false
		classic_card_btn.find_child("CheckIcon").visible = true
	else:
		modern_card_btn.find_child("CheckIcon").visible = true
		classic_card_btn.find_child("CheckIcon").visible = false
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _click_modern():
	card_style = g.v.game_constants.CARD_STYLES.MODERN
	g.v.game_manager.change_card_style(card_style)
	update_state()

func _click_classic():
	card_style = g.v.game_constants.CARD_STYLES.CLASSIC
	g.v.game_manager.change_card_style(card_style)
	update_state()
	
func _click_ok():
	self.queue_free()
	var gui = g.v.game_manager.open_guide_gui()
	gui.is_quick_play = true
	pass
