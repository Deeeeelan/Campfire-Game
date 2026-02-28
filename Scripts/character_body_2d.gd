extends CharacterBody2D

@export var depth : int = 0
@export var health : int = 100
@export var speed = 180.0
@export var jump_velocity = -220.0
@export var lerp_speed = 5.5 # lower = more slippery
@export var zoom : float = 4.0

@export var select_overlay: Sprite2D
@export var tile_map: TileMapLayer
@export var game_ticker: Timer

var selection_pos: Vector2i

const MAX_REACH = 100.0

var direction = 0.0

func tick():
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		print(selection_pos)
		tile_map.set_cell(selection_pos)

func _ready() -> void:
	game_ticker.timeout.connect(tick)
	

func _input(event) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP and zoom < 8.0:
				zoom += 0.5
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and zoom > 1.0:
				zoom -= 0.5



func _physics_process(delta: float) -> void:
	depth = self.position.y 
	$Camera2D.zoom = Vector2.ONE * zoom # TODO: Tween camera position 
	
	var space_state = get_world_2d().direct_space_state
	var start_pos = self.position
	var end_pos = get_global_mouse_position()
	
	var query = PhysicsRayQueryParameters2D.create(start_pos, end_pos)
	var result = space_state.intersect_ray(query)

	if result and (start_pos - result["position"]).length() < MAX_REACH:
		var pos : Vector2 = result["position"]
		var real_pos : Vector2 = to_global(self.to_local(pos) * 1.01) # TODO: Fix bugs aroudn corners
		
		# Make the raycast go just a bit further into the cell
		selection_pos = tile_map.local_to_map(real_pos) 
		select_overlay.position = tile_map.map_to_local(selection_pos)
		select_overlay.visible = true
	else:
		select_overlay.visible = false
		
	
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
