extends Control

var ready_to_leave = false
var title_screen_path = "res://Scenes/Title Screen.tscn"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$ResetLabel.visible = false
	await get_tree().create_timer(5.0).timeout
	$ResetLabel.visible = true
	ready_to_leave = true

func _input(event) -> void:
	if !ready_to_leave: return # wait until text appears
	
	if event is InputEventMouseButton:
		if event.is_released():
			if event.button_index == MOUSE_BUTTON_LEFT:
				get_tree().change_scene_to_file(title_screen_path)
	elif event is InputEventKey:
		if event.is_released():
			get_tree().change_scene_to_file(title_screen_path)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
