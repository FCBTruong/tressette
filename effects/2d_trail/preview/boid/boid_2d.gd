extends Node2D

@export var target : Node2D
var size_factor = randf_range(0.8, 1.2)
@onready var zone = %Zone
@onready var zone_collision = %CollisionShape2D

var speed = 50.0
var top_speed = 10.0
var fear_factor = 1.0
var velocity : Vector2 = Vector2.ZERO

@onready var zone_size = 256.0 * size_factor
@onready var half_zone_size = zone_size / 2.0
@onready var visual_root = %VisualRoot
@onready var trail_2d = %Trail2D
@onready var fade = %Fade
var is_live: bool = true
func _ready():
	fade.width *= size_factor	
	trail_2d.width *= size_factor
	visual_root.scale *= size_factor

func avoid(delta):
	return

func _physics_process(delta: float):
	if not is_live:
		return
	if not target:
		is_live = false
		var tween = create_tween()
		tween.tween_callback(self.queue_free).set_delay(1)
		# remove self after 1 second
		return
	global_position = target.global_position
	#return
	## Follow target
	#var distance_target = clamp(position.distance_to(target.global_position), 0.0, zone_size * 2.0)
	#var angle_target = position.angle_to_point(target.global_position)
	#var acceleration_amount = remap(distance_target, 0.0, zone_size * 2.0, 0.0, 1.0)
	#velocity += Vector2.from_angle(angle_target) * speed * acceleration_amount * delta
	## Avoid
	#if fear_factor != 0.0:
		#avoid(delta)
	#velocity = velocity.limit_length(top_speed)
	#position += velocity
	#visual_root.rotation = velocity.angle()
