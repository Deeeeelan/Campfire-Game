extends Control

var game_path = "res://Scenes/Game.tscn"
var info_messages = [
	"Calamity. Ever since the year 2032, that's all the people of the city of Minville knew.",
	"A brave miner named Joe knew he had to escape. There was nothing left to have done on the surface, so he started to dig. No one left to judge him, anyways.",
	"You must help him secure himself, away from all the mobs and storms above, chasing him to the depths of the world. Can you help save Joe from the dangers of the world by digging him down to the safe bunker below?",
]

var index = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Information.text = info_messages[0]
	
	$BackButton.pressed.connect(back)
	$NextButton.pressed.connect(next)
	
	$BackButton.visible = false
	$NextButton.visible = true

func back() -> void:
	$NextButton/Label.text = "Next"
	if index > 0:
		index = index - 1
		$Information.text = info_messages[index]
	if index == 0:
		$BackButton.visible = false

func next() -> void:
	$BackButton.visible = true
	if index < (len(info_messages) - 1):
		index = index + 1
		$Information.text = info_messages[index]
	elif index == (len(info_messages) - 1):
		get_tree().change_scene_to_file(game_path)
	
	if index == (len(info_messages) - 1): # Next "next" click will load game
		$NextButton/Label.text = "Start"

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
