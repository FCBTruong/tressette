extends Node


@onready var time_progress_bar: TextureProgressBar = find_child('TimeProgressBar')
@onready var empty_slot = find_child("EmptySlot")
@onready var main_pn = find_child("MainPn")
@onready var score_lb = find_child("ScoreLb")
@onready var vortex = find_child("Vortex")
@onready var avatar_img = find_child('AvatarImg')
func _ready() -> void:
	#effect_add_score(5)
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
	
	var name_label = find_child('NameLb')  # Access the RichTextLabel
	if name_label:
		name_label.text = StringUtils.sub_string(user_data.name, 9)
	update_points_display()
	# update avatar
	print('userdatavat', user_data.avatar)
	avatar_img.set_avatar(user_data.avatar)
	

func update_points_display(effect_add = false):
	pass
	#score_lb.text = str(user_data.game_data.points)
	
var user_info_gui: PackedScene = preload("res://scenes/guis/UserInfoGUI.tscn")

func _open_user_info_gui():
	SceneManager.open_gui("res://scenes/guis/UserInfoGUI.tscn")
	
var timer_duration: float = 10.0  # Total duration of the timer in seconds
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
		if elapsed_time < timer_duration:
			# Update progress bar value based on elapsed time
			time_progress_bar.value = (timer_duration - elapsed_time) / timer_duration * 100
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
