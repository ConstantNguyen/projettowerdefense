extends Node3D


func _ready() :
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func game_over():
	if get_tree().get_nodes_in_group("towers").size() == 0 : 
		var menu_scene = preload("res://scenes/menu1.tscn").instantiate()
		menu_scene.get_child(0).is_game_over = true
		get_tree().root.add_child(menu_scene)
		queue_free()
		

			
