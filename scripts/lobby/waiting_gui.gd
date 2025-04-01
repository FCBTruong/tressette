extends Control

# Radius of the main circle
@export var main_circle_radius: float = 40.0
# Number of smaller circles
@export var num_circles: int = 11
# Radius of smaller circles
@export var small_circle_radius: float = 20.0
@onready var circle_loading = find_child('Circle')
@onready var center_pn = find_child('Center')
@export var timeout = -1
var list_circles = []
func _ready():
	for i in range(num_circles):
		# Calculate the angle in radians (equally spaced)
		var angle = i * (2 * PI / num_circles)
		
		# Convert polar coordinates to Cartesian
		var x = cos(angle) * main_circle_radius
		var y = sin(angle) * main_circle_radius
		
		# Create a smaller circle
		var circle = create_circle(Vector2(x, y))
		list_circles.append(circle)
		# Add the circle to the scene
		center_pn.add_child(circle)
		
	# effect loading
	start_loading_animation()
	
	if timeout != -1:
		set_timeout(timeout)

@export var max_alpha: float = 1.0
@export var min_alpha: float = 0.2
@export var fade_step: float = 0.1
@export var speed: float = 0.1 # Speed of transition

func start_loading_animation():
	# Start the effect
	_update_alpha()
	var timer = get_tree().create_timer(speed)
	timer.timeout.connect(_on_timer_timeout)

var index = 0
func _on_timer_timeout():
	# Shift effect forward
	index = (index + 1) % list_circles.size()
	_update_alpha()
	var timer = get_tree().create_timer(speed)
	timer.timeout.connect(_on_timer_timeout)


func _update_alpha():
	for i in range(list_circles.size()):
		var alpha = max_alpha - (i * fade_step)
		alpha = max(alpha, min_alpha) # Ensure it doesn't go below min_alpha
		list_circles[(index + i) % list_circles.size()].modulate.a = alpha

# Function to create a circle
func create_circle(position: Vector2) -> Control:
	var circle = Control.new()  # Use Control as a base node
	circle.size = Vector2(small_circle_radius * 2, small_circle_radius * 2)
	circle.position = position - circle.size / 2  # Center the circle
	
	circle_loading.position = Vector2(0, 0)
	var c = circle_loading.duplicate()
	c.visible = true
	circle.add_child(c)
	return circle

var timer: SceneTreeTimer = null
func set_timeout(time: float):
	# If a timer already exists, stop it first
	if timer:
		timer.timeout.disconnect(_on_timeout) # Disconnect previous signal
		timer = null
	
	# Set the new timeout
	timeout = time
	timer = get_tree().create_timer(timeout)
	timer.timeout.connect(_on_timeout)

func _on_timeout():
	queue_free() # Deletes this node after the timeout
	timer = null # Reset timer reference
