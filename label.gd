extends Label


# Called when the node enters the scene tree for the first time.
func _ready():
	print("level1 loaded")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _input(event):
	if event.is_action_pressed("return_to_main_menue"): 
		get_tree().change_scene_to_file("res://main_meue.tscn")
