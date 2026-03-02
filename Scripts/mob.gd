extends CharacterBody2D

@export var depth : int = 0
@export var health : int = 100
@export var gold : int = 0
@export var speed = 120.0
@export var jump_velocity = -220.0
@export var lerp_speed = 5.5 # lower = more slippery
@export var zoom : float = 8.0
@export var game_ticker: Timer
@export var game_ticker2: Timer

@export var tile_map: TileMapLayer
var direction = 0.0

var initialization_time

func die():
	queue_free()

# Called when the node e	nters the scene tree for the first time.
func _ready() -> void:
	print("Mob initialized")
	self.position.x=get_node("/root/Game/Node2D/CharacterBody2D").position.x
	game_ticker.timeout.connect(die)
	game_ticker2.timeout.connect(tick)

	pass

func dig(pos: Vector2i):
	tile_map.set_cell(pos, 0, Vector2i(0, 2))

func tick():
	var player=get_node("/root/Game/Node2D/CharacterBody2D")
	print("Tick", position, player.position)
	if position.y-player.position.y<-16:
		velocity += get_gravity() * 1
		var self_pos = tile_map.local_to_map(position)
		print("Self Position", self_pos, self_pos.x, self_pos.y)
		self_pos.y -= 1;
		dig(self_pos)
	else:
		velocity.x = direction * speed
	

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
