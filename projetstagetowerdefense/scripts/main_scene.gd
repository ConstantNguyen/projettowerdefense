extends Node3D

@export var game_scene_path: String = "res://scenes/MainScene.tscn"
@onready var pause_icon: Texture2D = load("res://assets/image/bouton_pause.png")
@onready var paused_icon: Texture2D = load("res://assets/image/bouton_paused.png")
@onready var sound_on_icon = preload("res://assets/image/sound_on.png")
@onready var sound_off_icon = preload("res://assets/image/sound_off.png")
@onready var click_sound = $CanvasLayer/click_sound
@onready var hover_sound = $CanvasLayer/hover_sound
@onready var start_button = $CanvasLayer/start_button  

@onready var sound_control = $CanvasLayer/sound_control
@onready var timer_label = $CanvasLayer/timer_label
@onready var game_timer = $game_timer
@onready var bouton_pause = $CanvasLayer/button_pause
@onready var pause_menu = $Pause
@onready var continue_button = $Pause/ContinueButton
@onready var restart_button = $Pause/RestartButton
@onready var quit_button = $Pause/QuitButton
@onready var bouton_start = $CanvasLayer/start_button
@onready var music_player = $music_player

var started = false
var seconds_passed = 0
var is_paused = false
var is_muted = false


func _ready():
	game_timer.timeout.connect(_on_game_timer_timeout)
	bouton_pause.pressed.connect(_on_pause_button_pressed)
	update_timer_display()
	
	bouton_start.connect("pressed", Callable(self, "_play_click"))
	bouton_start.connect("mouse_entered", Callable(self, "_play_hover"))
	
	bouton_start.pressed.connect(func(): 
		show_intro_image()

		started = true
		bouton_start.visible = false
		bouton_pause.visible = true
		game_timer.start()
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

	pause_menu.visible = false
	bouton_pause.visible = false

func _on_pause_button_pressed():
	is_paused = not is_paused
	bouton_pause.icon = paused_icon if is_paused else pause_icon

	if is_paused:
		game_timer.stop()
		if started:
			_pause_enemies()
	else:
		game_timer.start()
		if started:
			_resume_enemies()

func _pause_enemies():
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)

func _resume_enemies():
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.set_physics_process(true)


func _unhandled_input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_toggle_pause_menu()

func _toggle_pause_menu():
	is_paused = not is_paused
	get_tree().paused = is_paused
	pause_menu.visible = is_paused

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
	if get_tree().get_nodes_in_group("towers").size() == 0: 
		var menu_scene = preload("res://scenes/menu1.tscn").instantiate()
		menu_scene.get_child(0).is_game_over = true
		get_tree().root.add_child(menu_scene)
		queue_free()
		
func _on_button_sound_pressed():
	is_muted = not is_muted
	sound_control.icon = sound_off_icon if is_muted else sound_on_icon

	music_player.stream_paused = is_muted
	
func show_intro_image():
	var img = $CanvasLayer/IntroImage
	img.visible = true
	
	var timer = Timer.new()
	timer.wait_time = 5.0
	timer.one_shot = true
	timer.timeout.connect(func(): img.visible = false)
	add_child(timer)
	timer.start()
func _play_click():
	click_sound.play()

func _play_hover():
	hover_sound.play()
