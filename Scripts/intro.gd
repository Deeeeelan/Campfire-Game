extends Control

var game_path = "res://Scenes/Game.tscn"
var info_messages = [
	"Calamity. Ever since the year 2032, that's all the people of the city of Minville knew.",
	"A brave miner named John knew he had to escape. There was nothing left to have done on the surface, so he started to dig. No one left to judge him, anyways."
]

var index = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Information.text = info_messages[0]
	$BackButton.pressed.connect(back)
	$NextButton.pressed.connect(next)

func back() -> void:
	if index > 0:
		index = index - 1
		$Information.text = info_messages[index]

func next() -> void:
	if index < (len(info_messages) - 1):
		index = index + 1
		$Information.text = info_messages[index]
	elif index == (len(info_messages) - 1):
		get_tree().change_scene_to_file(game_path)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
