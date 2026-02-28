extends CharacterBody2D


const SPEED = 120.0
const JUMP_VELOCITY = -180.0
const LERP_SPEED = 10

var direction = 0.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	direction = lerp(direction, Input.get_axis("Left", "Right"), delta * LERP_SPEED)
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
