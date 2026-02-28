extends CharacterBody2D


@export var speed = 120.0
@export var jump_velocity = -180.0
@export var lerp_speed = 10.0
@export var depth : int = 0

var direction = 0.0

func _physics_process(delta: float) -> void:
	depth = self.transform.origin.y
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_pressed("Jump") and is_on_floor():
		velocity.y = jump_velocity
		
	direction = lerp(direction, Input.get_axis("Left", "Right"), delta * lerp_speed)
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)

	move_and_slide()
