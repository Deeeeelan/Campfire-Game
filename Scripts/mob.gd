extends CharacterBody2D

@export var depth : int = 0
@export var health : int = 100
@export var gold : int = 0
@export var speed = 120.0
@export var jump_velocity = -220.0
@export var lerp_speed = 5.5 # lower = more slippery
@export var zoom : float = 8.0
@export var game_ticker: Timer
@export var tile_map: TileMapLayer
var direction = 0.0

var initialization_time

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("Mob initialized")
	game_ticker.timeout.connect(tick)
	initialization_time=Time.get_unix_time_from_system()
	pass

func dig(pos: Vector2i):
	pass

func tick():
	var player=get_node("/root/Game/Node2D/CharacterBody2D")
	print("Tick", self.position, player.position)
	if(self.position.y-player.position.y<16):
		velocity += get_gravity() * 1
		var self_pos = tile_map.local_to_map(self.position)
		print(self_pos)
		dig(self_pos)
	else:
		velocity.x = direction * speed
	if(Time.get_unix_time_from_system()-initialization_time>3):
		queue_free()
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	depth = self.position.y
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	var input_dir = Input.get_axis("Left", "Right")
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	move_and_slide()
