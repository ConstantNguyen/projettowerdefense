extends Node3D

@onready var timer_label = $CanvasLayer/timer_label
@onready var game_timer = $game_timer
@onready var bouton_pause = $button_pause

var seconds_passed = 0

func _ready() :
	game_timer.timeout.connect(_on_game_timer_timeout)
	game_timer.start()
	update_timer_display()

func _on_game_timer_timeout():
	seconds_passed += 1
	update_timer_display()


func update_timer_display():
	var minutes = seconds_passed / 60
	var seconds = seconds_passed % 60
	var formatted_time = "%02d:%02d" % [minutes, seconds]
	timer_label.text = formatted_time


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func game_over():
	if get_tree().get_nodes_in_group("towers").size() == 0 : 
		var menu_scene = preload("res://scenes/menu1.tscn").instantiate()
		menu_scene.get_child(0).is_game_over = true
		get_tree().root.add_child(menu_scene)
		queue_free()
		
