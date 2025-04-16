extends Node3D

@onready var timer_label = $CanvasLayer/timer_label
@onready var game_timer = $game_timer
@onready var bouton_pause = $CanvasLayer/button_pause

var seconds_passed = 0
var is_paused = false

func _ready():
	game_timer.timeout.connect(_on_game_timer_timeout)
	bouton_pause.pressed.connect(_on_pause_button_pressed)
	game_timer.start()
	update_timer_display()
	


func _on_pause_button_pressed():
	if is_paused:
		is_paused = false
		get_tree().paused = false
		bouton_pause.text = "Pause"
		print("Jeu repris !")
	else:
		is_paused = true
		get_tree().paused = true
		bouton_pause.text = "Reprendre"  
		print("Jeu en pause !")  

func _on_game_timer_timeout():
	if not is_paused:
		seconds_passed += 1
		update_timer_display()

func update_timer_display():
	var minutes = seconds_passed / 60
	var seconds = seconds_passed % 60
	var formatted_time = "%02d:%02d" % [minutes, seconds]
	timer_label.text = formatted_time
