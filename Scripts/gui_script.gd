extends Control

@export var menu_open: bool = false
@onready var pause_screen = $PauseScreen
@onready var top_bar = $TopBar
@export var player: CharacterBody2D

func quit():
	get_tree().quit()

func _ready() -> void:
	pause_screen.visible = false
	pause_screen.get_node("QuitButton").pressed.connect(quit)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Escape"):
		print(pause_screen.visible)
		pause_screen.visible = not pause_screen.visible
		menu_open = not menu_open
		
		if menu_open:
			Engine.time_scale = 0
		else:
			Engine.time_scale = 1

func _process(delta: float) -> void:
	top_bar.get_node("DepthLabel").text = "Depth: " + str(player.depth)
	top_bar.get_node("HealthLabel").text = "Health: " + str(player.health)
