extends CharacterBody2D

@export var depth : int = 0
@export var deepest_depth : int = 0
@export var health : int = 100
@export var gold : int = 0
@export var speed = 180.0
@export var jump_velocity = -220.0
@export var lerp_speed = 5.5 # lower = more slippery
@export var zoom : float = 6.0

@export var select_overlay: Sprite2D
@export var tile_map: TileMapLayer
@export var game_ticker: Timer
@export var bomb_ticker: Timer
@export var shop_overlay: Control
@export var item_container: GridContainer
@export var debris: Node2D

@export var current_items: Array[String] = []


var selection_pos: Vector2i
var last_shop_pos: Vector2i

var item_display = preload("res://Assets/Items/item_container.tscn")
var bomb_proj = preload("res://Assets/Items/bomb.tscn")

const MAX_REACH = 100.0

var direction = 0.0

const UNBREAKABLE = [Vector2i(14, 14)]
# THIS IS SO BAD, but it works
# Block states are linked together in a dict sequentially
const BREAKING_STATES : Dictionary[Vector2i, Vector2i] = { 
	Vector2i(1, 0) : Vector2i(1, 1),
}
const TILE_VALUES : Dictionary[Vector2i, int] = { 
	Vector2i(0, 0) : 1,
	Vector2i(1, 1) : 2,
}
const ITEMS = {
	"Bomb" : {
		"Name": "Bomb",
		"Description": "A simple bomb that explodes tiles sometimes.",
		"Cost": 100,
		"TexturePath": "res://Assets/Items/bomb_texture.tres",
	},
}
const DIRS =  [Vector2i(0, -1),
		Vector2i(-1, 0),          Vector2i(1, 0),
					Vector2i(0, 1)]
func generate_tile_circle(atlas : Vector2i, pos : Vector2i, max_radius : int, radius : int) -> int:
	var dirs = DIRS.duplicate(true)
	if radius < max_radius:
		for dir in dirs:
			var new = pos + dir
			var coords = tile_map.get_cell_atlas_coords(new)
			if coords != atlas and coords not in UNBREAKABLE: #TODO Inefficent algorithm
				tile_map.set_cell(new, 0, atlas)
			generate_tile_circle(atlas, new, max_radius, radius + 1)
	return radius
	
func update_items():
	print(current_items)
	for c in item_container.get_children():
		c.queue_free()
	for i in range(len(current_items)):
		var item = current_items[i]
		var item_info = ITEMS[item]
		var display = item_display.instantiate()
		item_container.add_child(display)
		display.texture =  load(item_info["TexturePath"])


func open_shop():
	if shop_overlay.visible == false:
		var random_item1 = ITEMS[ITEMS.keys()[randi_range(0, len(ITEMS.keys()) - 1)]]
		var random_item2 = ITEMS[ITEMS.keys()[randi_range(0, len(ITEMS.keys()) - 1)]]
		
		var item1_ui = shop_overlay.get_node("Item1")
		item1_ui.visible = true
		item1_ui.get_node("ItemLabel").text = random_item1["Name"]
		item1_ui.get_node("GoldLabel").text = str(random_item1["Cost"])
		item1_ui.get_node("Desc").text = random_item1["Description"]
		item1_ui.get_node("TextureRect").texture = load(random_item1["TexturePath"])
		
		item1_ui.get_node("BuyButton").pressed.connect(func():
			if gold >= random_item1["Cost"] and len(current_items) < 5 and item1_ui.visible:
				item1_ui.visible = false
				gold -= random_item1["Cost"]
				current_items.append(random_item1["Name"])
				update_items()
		)
		
		var item2_ui = shop_overlay.get_node("Item2")
		item2_ui.visible = true
		item2_ui.get_node("ItemLabel").text = random_item2["Name"]
		item2_ui.get_node("GoldLabel").text = str(random_item2["Cost"])
		item2_ui.get_node("Desc").text = random_item2["Description"]
		item2_ui.get_node("TextureRect").texture = load(random_item2["TexturePath"])
		
		item2_ui.get_node("BuyButton").pressed.connect(func():
			if gold >= random_item2["Cost"] and len(current_items) < 5 and item2_ui.visible:
				item2_ui.visible = false
				gold -= random_item2["Cost"]
				current_items.append(random_item2["Name"])
				update_items()
		)
		shop_overlay.visible = true


func dig(pos : Vector2i):
	var atlas_pos = tile_map.get_cell_atlas_coords(pos)
	if atlas_pos not in UNBREAKABLE:
		if atlas_pos in BREAKING_STATES:
			tile_map.set_cell(selection_pos, 0, BREAKING_STATES[atlas_pos])
		else:
			tile_map.set_cell(selection_pos, 0, Vector2i(0, 2))
		if atlas_pos in TILE_VALUES:
			gold += TILE_VALUES[atlas_pos]
	
	
func tick():
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		dig(selection_pos)

func bomb_tick():
	if "Bomb" in current_items:
		var bomb : Sprite2D = bomb_proj.instantiate()
		debris.add_child(bomb)
		bomb.position = position
		await get_tree().create_timer(0.25).timeout
		# TODO: Explosion particle & sound
		generate_tile_circle(Vector2i(0, 2), tile_map.local_to_map(bomb.position), 4 + (current_items.count("Bomb") - 1), 0)
		bomb.queue_free()
		

func _ready() -> void:
	game_ticker.timeout.connect(tick)
	bomb_ticker.timeout.connect(bomb_tick)
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
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and zoom > 3.0:
				zoom -= 0.5
		elif event.is_released():
			if event.button_index == MOUSE_BUTTON_MASK_RIGHT:
				dig(selection_pos)
	elif event.is_action_pressed("Debug"):
		gold = 9999999
		game_ticker.wait_time = 0.05


func _physics_process(delta: float) -> void:
	depth = self.position.y
	deepest_depth = max(deepest_depth, depth)
	$Camera2D.zoom = Vector2.ONE * zoom # TODO: Tween camera position 
	
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
