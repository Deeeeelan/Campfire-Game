extends CharacterBody2D

@export var depth : int = 0
@export var deepest_depth : int = 0
@export var health : int = 100
@export var gold : int = 0
@export var speed = 120.0
@export var jump_velocity = -220.0
@export var lerp_speed = 5.5 # lower = more slippery
@export var zoom : float = 8.0
var direction = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Mob initialized??")
	pass # Replace with function body.

func tick():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	depth = self.position.y
	deepest_depth = max(deepest_depth, depth)
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir = Input.get_axis("Left", "Right")
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	move_and_slide()
