extends CharacterBody2D

@export var depth : int = 0
@export var health : int = 100
@export var gold : int = 0
@export var speed = 80.0
@export var jump_velocity = -220.0
@export var lerp_speed = 5.5 # lower = more slippery
@export var zoom : float = 8.0
@export var game_ticker: Timer
@export var game_ticker2: Timer

@export var tile_map: TileMapLayer
var direction = 0.0
@onready var player=get_node("/root/Game/Node2D/CharacterBody2D")

var initialization_time

func die():
	queue_free()

# Called when the node e	nters the scene tree for the first time.
func _ready() -> void:
	position =  player.position + Vector2(0, -500)
	game_ticker.timeout.connect(die)
	game_ticker2.timeout.connect(tick)

func dig(pos: Vector2i):
	tile_map.set_cell(pos, 0, Vector2i(0, 2))

func tick():
	
	#print("Tick", position, player.position)
	if (position - player.position).length() < 25:
		player.health -= 10
	if position.y - player.position.y < -16:
		var self_pos = tile_map.local_to_map(position)
		#print("Self Position", self_pos, self_pos.x, self_pos.y)
		
		dig(self_pos + Vector2i(0, 1))
	else:
		pass #velocity.x = direction * speed
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if position.y - player.position.y < -16:
		if player.position.x - position.x > 0:
			direction = 1.0
		else:
			direction = -1
	depth = self.position.y
	
	if not is_on_floor():
		velocity += get_gravity() * delta

	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	move_and_slide()
