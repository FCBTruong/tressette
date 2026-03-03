extends Control

@onready var load_bar: ProgressBar = find_child('LoadBar')  # Ensure your loading bar node is named 'LoadBar'
@onready var loading_timer: Timer = Timer.new()  # Timer to simulate loading progress

var loading_progress: float = 0.0
var is_loading_complete: bool = false

func _ready() -> void:
	# Initialize the loading bar
	load_bar.value = 0
	
	# Add and configure the timer
	add_child(loading_timer)
	loading_timer.wait_time = 0.01  # Update progress every 0.1 seconds
	loading_timer.timeout.connect(_update_loading_bar)
	loading_timer.start()

func _update_loading_bar() -> void:
	# Simulate loading progress
	loading_progress += 5.0  # Increase progress by 1% each tick
	load_bar.value = loading_progress

	# Check if loading is complete
	if loading_progress >= 100.0:
		_finish_loading()

func _finish_loading() -> void:
	# Stop the timer and mark loading as complete
	loading_timer.stop()
	is_loading_complete = true

	# Optional: Add a delay before transitioning to the next scene
	#await get_tree().create_timer(1.0).timeout  # Wait 1 second before transitioning

	g.v.scene_manager.switch_scene(g.v.scene_manager.LOBBY_SCENE)

func _process(delta: float) -> void:
	# Optional: Add any additional logic you want to run during loading
	pass
