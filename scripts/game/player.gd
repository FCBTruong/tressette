extends Node


@onready var time_progress_bar: TextureProgressBar = find_child('TimeProgressBar')
@onready var empty_slot = find_child("EmptySlot")
@onready var main_pn = find_child("MainPn")
@onready var score_lb = find_child("ScoreLb")
@onready var vortex = find_child("Vortex")
@onready var avatar_img = find_child('AvatarImg')
@onready var emo_icon = find_child('EmoIcon')
@onready var gold_lb = find_child("GoldLb")
func _ready() -> void:
	#effect_add_score(5)
	emo_icon.visible = false
	time_progress_bar.visible = false
	pass

# Properties
var user_data: UserData


# Function to update properties
func set_user_data(user_dt: UserData) -> void:
	user_data = user_dt
	if not user_data or user_data.uid == -1:
		main_pn.visible = false
		empty_slot.visible = true
		return

	main_pn.visible = true
	empty_slot.visible = false
	
	
	#name_label.text = StringUtils.sub_string(user_data.name, 9)
	gold_lb.text = _get_gold_str(user_data.gold)
	update_points_display()
	# update avatar
	print('userdatavat', user_data.avatar)
	if user_data.uid == PlayerInfoMgr.my_user_data.uid:
		SignalBus.connect_global('on_update_money', Callable(self, "_on_update_money"))
		avatar_img.set_me()
	avatar_img.set_avatar(user_data.avatar)
	

func update_points_display(effect_add = false):
	pass
	#score_lb.text = str(user_data.game_data.points)


var elapsed_time: float = 0.0  # Tracks the elapsed time
var running: bool = false

func start_timer():
	if self.user_data.uid == PlayerInfoMgr.my_user_data.uid:
		SceneManager.INSTANCES.BOARD_SCENE.play_sound_my_turn()
	time_progress_bar.visible = true
	elapsed_time = 0.0
	running = true
	time_progress_bar.value = 0
	vortex.visible = true

func _process(delta: float):
	if self.user_data.uid == -1:
		time_progress_bar.visible = false
		vortex.visible = false
		return
	if GameConstants.game_logic.get_uid_in_turn() == self.user_data.uid:
		if not running: 
			start_timer()
	else:
		time_progress_bar.visible = false
		vortex.visible = false
		running = false
		
	if running:
		elapsed_time += delta
		if elapsed_time < GameServerConfig.time_thinking_in_turn:
			# Update progress bar value based on elapsed time
			time_progress_bar.value = (GameServerConfig.time_thinking_in_turn - elapsed_time) \
				/ GameServerConfig.time_thinking_in_turn * 100
		else:
			# Ensure progress bar is full and end the timer
			time_progress_bar.value = 100
			running = false
			end_timer()

func get_user_data() -> UserData:
	return user_data
	
func end_timer():
	time_progress_bar.visible = false
	vortex.visible = false
	await get_tree().create_timer(1).timeout
	running = false
	print("Timer complete!")

var effect_add_score_scene = preload('res://scenes/board/AddScoreEffect.tscn')
func effect_add_score(score):
	if score <= 0:
		return
	var main = score / 3
	var sub = score % 3
	# send auto play to server
	var eff = effect_add_score_scene.instantiate()
	self.add_child(eff)
	eff.find_child('MainLb').text = str(main) if main > 0 else ''
	eff.find_child('SubLb').text = str(sub)
	eff.find_child('Sub').visible = true if sub > 0 else false
	var x = 70
	if self.global_position.x > get_viewport().get_visible_rect().size.x / 2:
		x = -120
	var default_pos = Vector2(x, 0)
	eff.position = default_pos
	var n_pos = Vector2(x, -50)
	var tween = create_tween()
	tween.tween_property(eff, 'position', n_pos, 0.5)
	tween.tween_property(eff, 'modulate:a', 0, 0.5)
	tween.tween_callback(eff.queue_free)


func _show_info():
	FriendManager.search_friend(user_data.uid)

func show_emotion(emo_id):
	var texture_path = "res://assets/animations/" + str(emo_id) + '.png'
	emo_icon.texture = load(texture_path)
	
	emo_icon.visible = true
	var tween = create_tween()
	emo_icon.scale = Vector2(0, 0)
	emo_icon.modulate.a = 1
	tween.parallel().tween_property(
		emo_icon, 'scale', Vector2(1, 1), 0.4
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.parallel().tween_property(
		emo_icon, 'modulate:a', 0, 0.4
	).set_delay(1)
	
	
func _on_update_money():
	gold_lb.text = _get_gold_str(PlayerInfoMgr.my_user_data.gold)

func _get_gold_str(gold) -> String:
	var str = StringUtils.point_number(gold)
	if gold > 100000000:
		str = StringUtils.symbol_number(gold)
	return str
