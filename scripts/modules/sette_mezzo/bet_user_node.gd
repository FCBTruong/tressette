extends Node


@onready var label = find_child("Label")
@onready var main = find_child("HBoxContainer")
@onready var icon_chip = find_child("TextureRect")
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

var tw
var current_bet: int = 0
func update_bet(bet: int, p = null):
	for c in icon_chip.get_children():
		c.queue_free()
	if bet == 0:
		main.visible = false
	else:
		main.visible = true
	if p != null:
		if tw and tw.is_running():
			tw.kill()
		tw = create_tween()
		var start_p = p.global_position
		
		var delay = 0
		var num = 4
		for i in range(num):
			
			var sprite = Sprite2D.new()
			icon_chip.add_child(sprite)
			sprite.z_index = 1
			sprite.global_position = start_p
			sprite.modulate.a = 0
			sprite.scale = Vector2(0.15, 0.15)
			
			sprite.texture = load("res://assets/images/lobby/icon_gold.png")
			var des_p = icon_chip.global_position
			des_p.x += 20
			des_p.y += 20
			var time_move = 0.3
			tw.parallel().tween_property(
				sprite,
				"global_position",
				des_p,
				time_move
			).set_delay(delay)
			tw.parallel().tween_property(
				sprite,
				"modulate:a",
				1,
				0.1
			).set_delay(delay)
			
			tw.parallel().tween_property(
				sprite,
				"modulate:a",
				0,
				0.1
			).set_delay(delay + time_move)
			
			tw.parallel().tween_callback(
				func():
					g.v.sound_manager.play_coin_hit_sound()
					sprite.queue_free()
			).set_delay(delay + time_move + 0.1)
			
			if i == num - 1:
				# last
				tw.parallel().tween_method(
					self.on_running_update_bet, current_bet, bet, 
					0.2).set_delay(delay + time_move)
				tw.parallel().tween_callback(
					func():
						current_bet = bet
						self.label.text = StringUtils.point_number(bet)
				).set_delay(delay + time_move + 0.5)
			
			delay += 0.05
	else:	
		current_bet = bet
		# effect fly and show bet
		self.label.text = StringUtils.symbol_number(bet)

func on_running_update_bet(value):
	self.label.text = StringUtils.point_number(value)
