extends CharacterBody2D


@export var speed = 120.0
@export var jump_velocity = -180.0
@export var lerp_speed = 10.0
@export var depth : int = 0
@export var zoom : float = 4.0

var direction = 0.0
func _input(event) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			print(zoom)
			if event.button_index == MOUSE_BUTTON_WHEEL_UP and zoom < 8.0:
				zoom += 0.5
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and zoom > 1.0:
				zoom -= 0.5

func _physics_process(delta: float) -> void:
	depth = self.transform.origin.y 
	$Camera2D.zoom = Vector2.ONE * zoom # TODO: Tween camera position 
	
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
