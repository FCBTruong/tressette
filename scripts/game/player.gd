extends Node


@onready var time_progress_bar: TextureProgressBar = find_child('TimeProgressBar')
@onready var empty_slot = find_child("EmptySlot")
@onready var main_pn = find_child("MainPn")
@onready var score_lb = find_child("ScoreLb")
@onready var vortex = find_child("Vortex")
func _ready() -> void:
	pass

# Properties
var user_data


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
		name_label.text = user_data.name
	update_points_display()

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
	running = false
	print("Timer complete!")
	
	# send auto play to server
