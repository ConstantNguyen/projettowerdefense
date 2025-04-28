extends Node3D

@export var game_scene_path: String = "res://scenes/MainScene.tscn"

@onready var timer_label = $CanvasLayer/timer_label
@onready var game_timer = $game_timer
@onready var bouton_pause = $CanvasLayer/button_pause
@onready var pause_menu = $Pause
@onready var continue_button = $Pause/ContinueButton
@onready var restart_button = $Pause/RestartButton
@onready var quit_button = $Pause/QuitButton
@onready var bouton_start = $CanvasLayer/start_button

var started = false
var seconds_passed = 0
var is_paused = false

func _ready():
	game_timer.timeout.connect(_on_game_timer_timeout)
	bouton_pause.pressed.connect(_on_pause_button_pressed)
	game_timer.start()
	update_timer_display()
	
	bouton_start.pressed.connect(func(): 
		started = true
		bouton_start.visible = false
	)
	
	continue_button.pressed.connect(func(): 
		is_paused = false
		pause_menu.visible = false
		get_tree().paused = false
	)
	
	restart_button.pressed.connect(func():
		print(get_tree().current_scene)
		get_tree().paused = false
		get_tree().reload_current_scene()
	)
	quit_button.pressed.connect(func():
		get_tree().paused = false
		var menu_scene = preload("res://scenes/menu1.tscn").instantiate()
		get_tree().root.add_child(menu_scene)
		queue_free()
	)
	


func _on_pause_button_pressed():
	is_paused = true
	get_tree().paused = true
	pause_menu.visible = true

func _on_continue_button_pressed() : 
	is_paused = false
	pause_menu.visible = false
	get_tree().paused = false

func _on_game_timer_timeout():
	if not is_paused:
		seconds_passed += 1
		update_timer_display()

func update_timer_display():
	var minutes = seconds_passed / 60
	var seconds = seconds_passed % 60
	var formatted_time = "%02d:%02d" % [minutes, seconds]
	timer_label.text = formatted_time
	
func game_over():
	if get_tree().get_nodes_in_group("towers").size() == 0 : 
		var menu_scene = preload("res://scenes/menu1.tscn").instantiate()
		menu_scene.get_child(0).is_game_over = true
		get_tree().root.add_child(menu_scene)
		queue_free()
