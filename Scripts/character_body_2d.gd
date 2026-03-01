extends CharacterBody2D

@export var depth : int = 0
@export var deepest_depth : int = 0
@export var health : int = 100
@export var gold : int = 0
@export var speed = 120.0
@export var jump_velocity = -220.0
@export var lerp_speed = 9.0 # lower = more slippery
@export var zoom : float = 8.0

@export var select_overlay: Sprite2D
@export var tile_map: TileMapLayer
@export var game_ticker: Timer
@export var mine_ticker: Timer
@export var bomb_ticker: Timer
@export var bomb_ticker2: Timer
@export var shop_overlay: Control
@export var item_container: GridContainer
@export var debris: Node2D
@export var audio_stream: AudioStreamPlayer
@export var audio_stream2: AudioStreamPlayer
@export var fade_to_black: ColorRect

@export var current_items: Array[String] = []

@export var lose_state = false

var selection_pos: Vector2i
var last_shop_pos: Vector2i

var game_path = "res://Scenes/Title Screen.tscn"
var win_path = "res://Scenes/EndScreen.tscn"
var item_display = preload("res://Assets/Items/item_container.tscn")
var bomb_proj = preload("res://Assets/Items/bomb.tscn")
var bomb_proj2 = preload("res://Assets/Items/bomb2.tscn")
var break_particle = preload("res://Assets/Particles/break_particle.tscn")
var explode_particle = preload("res://Assets/Particles/explode_particle.tscn")
const MAX_REACH = 100.0

var direction = 0.0

const BREAK_SFX = {
	"Stone" : ["res://Assets/Audio/Breaking/Stone/stone_Insert 1.wav", 
	"res://Assets/Audio/Breaking/Stone/stone_Insert 2.wav",
	"res://Assets/Audio/Breaking/Stone/stone_Insert 3.wav",
	"res://Assets/Audio/Breaking/Stone/stone_Insert 4.wav",
	],
	"Dirt" : ["res://Assets/Audio/Breaking/Dirt/campfire dirt_Insert 1.wav", 
	"res://Assets/Audio/Breaking/Dirt/campfire dirt_Insert 2.wav",
	"res://Assets/Audio/Breaking/Dirt/campfire dirt_Insert 3.wav"
	]
}

const UNBREAKABLE = [Vector2i(14, 14), Vector2i(0, 4), Vector2i(0, 6)]
# THIS IS SO BAD, but it works
# Block states are linked together in a dict sequentially
const BREAKING_STATES : Dictionary[Vector2i, Vector2i] = { 
	# Stone
	Vector2i(1, 0) : Vector2i(1, 1),
	# Coal
	Vector2i(3, 0) : Vector2i(3, 1),
	# Iron
	Vector2i(4, 0) : Vector2i(4, 1),
	Vector2i(4, 1) : Vector2i(4, 2),
	# Emerald
	Vector2i(5, 0) : Vector2i(5, 1),
	Vector2i(5, 1) : Vector2i(5, 2),
	# Ruby
	Vector2i(6, 0) : Vector2i(6, 1),
	Vector2i(6, 1) : Vector2i(6, 2),
	Vector2i(6, 2) : Vector2i(6, 3),
	# Diamond
	Vector2i(7, 0) : Vector2i(7, 1),
	Vector2i(7, 1) : Vector2i(7, 2),
	Vector2i(7, 2) : Vector2i(7, 3),
	Vector2i(7, 3) : Vector2i(7, 4),
}
const TILE_VALUES : Dictionary[Vector2i, int] = { 
	Vector2i(0, 0) : 1,
	Vector2i(1, 1) : 2,
	Vector2i(3, 1) : 3,
	Vector2i(4, 2) : 5,
	Vector2i(5, 2) : 25,
	Vector2i(6, 3) : 75,
	Vector2i(7, 4) : 250,
}
const ITEMS = {
	"Bomb" : {
		"Name": "Bomb",
		"Description": "A simple bomb that explodes tiles sometimes. You won't get rewards.",
		"Cost": 150,
		"TexturePath": "res://Assets/Items/bomb_texture.tres",
	},
	"Big Bomb" : {
		"Name": "Big Bomb",
		"Description": "A larger bomb. Takes some time to detonate. You won't get rewards.",
		"Cost": 500,
		"TexturePath": "res://Assets/Items/big_bomb_texture.tres",
	},
	"Energy Drink" : {
		"Name": "Energy Drink",
		"Description": "Gives extra speed.",
		"Cost": 350,
		"TexturePath": "res://Assets/Items/energy_drink_texture.tres",
	},
	"Spring" : {
		"Name": "Spring",
		"Description": "Jump higher! (Somehow!)",
		"Cost": 350,
		"TexturePath": "res://Assets/Items/spring_texture.tres",
	},
	"Pickaxe" : {
		"Name": "Pickaxe",
		"Description": "Break tiles faster",
		"Cost": 750,
		"TexturePath": "res://Assets/Items/pickaxe_texture.tres",
	},
}
const DIRS =  [Vector2i(0, -1),
		Vector2i(-1, 0),          Vector2i(1, 0),
					Vector2i(0, 1)]

func generate_tile_circle(atlas : Vector2i, pos : Vector2i, max_radius : int, radius : int, break_bedrock = false) -> int:
	var dirs = DIRS.duplicate(true)
	if radius < max_radius:
		for dir in dirs:
			var new = pos + dir
			var coords = tile_map.get_cell_atlas_coords(new)
			if coords != atlas and (coords not in UNBREAKABLE or (break_bedrock and coords == Vector2i(0, 4))): #TODO Inefficent algorithm
				tile_map.set_cell(new, 0, atlas)
			generate_tile_circle(atlas, new, max_radius, radius + 1, break_bedrock)
	return radius

func particle_at_pos(particle_re : Resource, position : Vector2):
	var particle = particle_re.instantiate()
	debris.add_child(particle)
	particle.position = position
	particle.get_node("CPUParticles2D").emitting = true
	get_tree().create_timer(0.25).timeout.connect(func():
		particle.queue_free()
	)
func explode_sound():
	var sfx = load("res://Assets/Audio/Breaking/explosion.mp3")
	audio_stream2.stream = sfx
	audio_stream2.play() 

func update_items():
	for c in item_container.get_children():
		c.queue_free()
	for i in range(len(current_items)):
		var item = current_items[i]
		var item_info = ITEMS[item]
		var display = item_display.instantiate()
		item_container.add_child(display)
		display.texture =  load(item_info["TexturePath"])
		display.get_node("Label").text = "SELL\n$" + str(floor(item_info["Cost"] / 2))
		display.get_node("Button").mouse_entered.connect(func():
			display.get_node("Label").visible = true
		)
		display.get_node("Button").mouse_exited.connect(func():
			display.get_node("Label").visible = false
		)
		display.get_node("Button").pressed.connect(func():
			gold += floor(item_info["Cost"] / 2)
			current_items.remove_at(i)
			update_items()
		)
	speed = 120 + (40 * current_items.count("Energy Drink"))
	jump_velocity = -220 + (-70 * current_items.count("Spring"))
	mine_ticker.wait_time = max(0.35 - (0.15 * current_items.count("Pickaxe")), 0.05)

func lose():
	print("LOSE")
	# Pause for a second
	await get_tree().create_timer(1.0).timeout
	
	# Fade to black
	var tween = create_tween()
	tween.tween_property(fade_to_black, "modulate", Color(0, 0, 0, 1.0), 1.0) # Fades to black over 1 second
	tween.play()
	await tween.finished
	await get_tree().create_timer(2.0).timeout
	
	# Switch
	get_tree().change_scene_to_file(game_path)

func open_shop():
	if shop_overlay.visible == false:
		shop_overlay.visible = true
		var random_item1 = ITEMS[ITEMS.keys()[randi_range(0, len(ITEMS.keys()) - 1)]]
		var random_item2 = ITEMS[ITEMS.keys()[randi_range(0, len(ITEMS.keys()) - 1)]]
		
		var item1_ui = shop_overlay.get_node("Item1")
		item1_ui.visible = true
		item1_ui.get_node("ItemLabel").text = random_item1["Name"]
		item1_ui.get_node("GoldLabel").text = str(random_item1["Cost"]) + " Gold"
		item1_ui.get_node("Desc").text = random_item1["Description"]
		item1_ui.get_node("TextureRect").texture = load(random_item1["TexturePath"])
		
		var buy1 = func():
			if gold >= random_item1["Cost"] and len(current_items) < 5 and item1_ui.visible:
				item1_ui.visible = false
				gold -= random_item1["Cost"]
				current_items.append(random_item1["Name"])
				update_items()
		for s in item1_ui.get_node("BuyButton").pressed.get_connections():
			item1_ui.get_node("BuyButton").pressed.disconnect(s.callable)
		item1_ui.get_node("BuyButton").pressed.connect(buy1)

		var item2_ui = shop_overlay.get_node("Item2")
		item2_ui.visible = true
		item2_ui.get_node("ItemLabel").text = random_item2["Name"]
		item2_ui.get_node("GoldLabel").text = str(random_item2["Cost"]) + " Gold"
		item2_ui.get_node("Desc").text = random_item2["Description"]
		item2_ui.get_node("TextureRect").texture = load(random_item2["TexturePath"])
		
		var buy2 = func():
			if gold >= random_item2["Cost"] and len(current_items) < 5 and item2_ui.visible:
				item2_ui.visible = false
				gold -= random_item2["Cost"]
				current_items.append(random_item2["Name"])
				update_items()
		for s in item2_ui.get_node("BuyButton").pressed.get_connections():
			item2_ui.get_node("BuyButton").pressed.disconnect(s.callable)
		item2_ui.get_node("BuyButton").pressed.connect(buy2)


func dig(pos : Vector2i):
	var atlas_pos = tile_map.get_cell_atlas_coords(pos)
	if atlas_pos not in UNBREAKABLE:
		if atlas_pos in BREAKING_STATES:
			tile_map.set_cell(selection_pos, 0, BREAKING_STATES[atlas_pos])
		else:
			tile_map.set_cell(selection_pos, 0, Vector2i(0, 2))
			if atlas_pos not in [Vector2i(0, 2), Vector2i(0, 3)]:
				var particle = break_particle.instantiate()
				debris.add_child(particle)
				particle.position = tile_map.map_to_local(pos)
				particle.get_node("CPUParticles2D").emitting = true
				get_tree().create_timer(0.25).timeout.connect(func():
					particle.queue_free()
				)
		if atlas_pos in [Vector2i(1, 1),\
			Vector2i(1, 0),\
			Vector2i(3, 1),\
			Vector2i(4, 2),\
			Vector2i(5, 2),\
			Vector2i(6, 3),\
			Vector2i(7, 4)] or atlas_pos in BREAKING_STATES:
			var sfx = load(BREAK_SFX["Stone"][randi_range(0, len(BREAK_SFX["Stone"]) - 1)])
			audio_stream.stream = sfx
			audio_stream.play() #NOTE: literally everything in BREAKING_STATES is stone
		if atlas_pos in [Vector2i(0, 0), Vector2i(2, 0)]:
			var sfx = load(BREAK_SFX["Dirt"][randi_range(0, len(BREAK_SFX["Dirt"]) - 1)])
			audio_stream.stream = sfx
			audio_stream.play()
		if atlas_pos in TILE_VALUES:
			gold += TILE_VALUES[atlas_pos]
		if atlas_pos == Vector2i(0, 5): # TNT
			generate_tile_circle(Vector2i(0, 2), pos, 5, 0, true)
			particle_at_pos(explode_particle, tile_map.map_to_local(pos))
			explode_sound()
	
func tick():
	var pos = tile_map.local_to_map(position)
	var atlas = tile_map.get_cell_atlas_coords(pos)
	if atlas == Vector2i(0, 6):
		health -= 15

func mine_tick():
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		dig(selection_pos)

func bomb_tick():
	if "Bomb" in current_items:
		var bomb : Sprite2D = bomb_proj.instantiate()
		debris.add_child(bomb)
		bomb.position = position
		await get_tree().create_timer(0.25).timeout
		generate_tile_circle(Vector2i(0, 2), tile_map.local_to_map(bomb.position), 4 + (current_items.count("Bomb") - 1), 0)
		particle_at_pos(explode_particle, bomb.position)
		explode_sound()
		bomb.queue_free()
		
		
func bomb_tick2(): # TODO: optimize so this doesn't cause lag spikes
	if "Big Bomb" in current_items:
		var bomb : Sprite2D = bomb_proj2.instantiate()
		debris.add_child(bomb)
		bomb.position = position
		await get_tree().create_timer(0.6).timeout
		particle_at_pos(explode_particle, bomb.position)
		explode_sound()
		generate_tile_circle(Vector2i(0, 2), tile_map.local_to_map(bomb.position), 6 + (current_items.count("Big Bomb") - 1), 0)
		bomb.queue_free()

func _ready() -> void:
	game_ticker.timeout.connect(tick)
	mine_ticker.timeout.connect(mine_tick)
	bomb_ticker.timeout.connect(bomb_tick)
	bomb_ticker2.timeout.connect(bomb_tick2)
	shop_overlay.visible = false
	shop_overlay.get_node("Exit").pressed.connect(func():
		shop_overlay.visible = false
		if last_shop_pos != null:
			tile_map.set_cell(last_shop_pos, 0, Vector2i(0, 2))
	)


func _input(event) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP and zoom < 32.0:
				zoom += 0.5
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and zoom > 4.0:
				zoom -= 0.5
		elif event.is_released():
			if event.button_index == MOUSE_BUTTON_LEFT:
				dig(selection_pos)
	elif event.is_action_pressed("Debug"):
		gold = 9999999
		mine_ticker.wait_time = 0.05


func _physics_process(delta: float) -> void:
	depth = int(self.position.y)
	deepest_depth = max(deepest_depth, depth)
	$Camera2D.zoom = Vector2.ONE * zoom # TODO: Tween camera position 
	
	if lose_state:
		return
	
	if health <= 0:
		lose_state = true
		lose()
	
	#if depth >= (10 * 16):
		#win()
	
	var tile_pos = tile_map.local_to_map(position)
	var space_state = get_world_2d().direct_space_state
	var start_pos = self.position
	var end_pos = get_global_mouse_position()
	
	var query = PhysicsRayQueryParameters2D.create(start_pos, end_pos)
	var result = space_state.intersect_ray(query)

	if result and (start_pos - result["position"]).length() < MAX_REACH and not shop_overlay.visible:
		var pos : Vector2 = result["position"]
		var real_pos : Vector2 = to_global(self.to_local(pos) * 1.01) # TODO: Fix bugs around corners
		
		# Make the raycast go just a bit further into the cell
		selection_pos = tile_map.local_to_map(real_pos) 
		select_overlay.position = tile_map.map_to_local(selection_pos)
		select_overlay.visible = true
	else:
		select_overlay.visible = false
		
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_pressed("Jump") and is_on_floor():
		if tile_map.get_cell_atlas_coords(tile_pos - Vector2i(0, 1)) == Vector2i(14, 14):
			last_shop_pos = tile_pos - Vector2i(0, 1)
			open_shop()
		elif tile_map.get_cell_atlas_coords(tile_pos - Vector2i(1, 1)) == Vector2i(14, 14):
			last_shop_pos = tile_pos - Vector2i(1, 1)
			open_shop()
		else:
			velocity.y = jump_velocity    
	var input_dir = Input.get_axis("Left", "Right")
	if shop_overlay.visible:
		input_dir = 0.0
	direction = lerp(direction, input_dir, delta * lerp_speed)
	if input_dir != 0.0:
		$AnimatedSprite2D.animation = "Walking"
		if shop_overlay.visible == true:
			shop_overlay.visible = false
	else:
		$AnimatedSprite2D.animation = "Idle"
	if input_dir > 0:
		$AnimatedSprite2D.scale = Vector2(1, 1) #TODO: Can add flip animation here
	elif input_dir < 0:
		$AnimatedSprite2D.scale = Vector2(-1, 1)
	if direction:
		velocity.x = direction * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
	move_and_slide()

func win() -> void:
	print("WIN")
	# Pause for a second
	await get_tree().create_timer(1.0).timeout
	
	# Fade to black
	var tween = create_tween()
	tween.tween_property(fade_to_black, "modulate", Color(0, 0, 0, 1.0), 1.0) # Fades to black over 1 second
	tween.play()
	await tween.finished
	
	# Switch
	get_tree().change_scene_to_file(win_path)
