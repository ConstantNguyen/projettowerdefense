extends Control

@export var game_scene_path: String = "res://scenes/MainScene.tscn"
@export var random_game_scene_path: String = "res://scenes/main.tscn"
@export var is_game_over: bool = false
@onready var sound_on_icon = preload("res://assets/image/sound_on.png")
@onready var sound_off_icon = preload("res://assets/image/sound_off.png")
@onready var sound_control = $CanvasLayer/sound_control
@onready var music_player = $music_player

var is_muted = false

func _ready():
	for button in get_tree().get_nodes_in_group("menu_buttons"):
		button.connect("pressed", Callable(self, "_play_click"))
		button.connect("mouse_entered", Callable(self, "_play_hover"))

	$Button.connect("pressed", Callable(self, "_on_play_pressed"))
	$ButtonRdmLvl.connect("pressed", Callable(self, "_on_play_random_pressed"))
	$Button2.connect("pressed", Callable(self, "_on_quit_pressed"))
	$Button3.connect("pressed", Callable(self, "_on_play_pressed"))
	
	# Affiche le bon bouton selon si c'est un lancement ou une fin de partie
	if is_game_over:
		$Button.visible = false
		$Button3.visible = true
		$Label.text = "Game Over !"
		$Background.texture = preload("res://assets/image/game_over.png")

	else:
		$Button.visible = true
		$Button3.visible = false
		#$Label.text = "Bienvenue dans le jeu !"
		$Background.texture = preload("res://assets/image/fond_menu_5_robots.png")
		

func _on_play_pressed():
	print("change")
	$click_sound.play()
	get_tree().change_scene_to_file(game_scene_path)
	queue_free()
	
func _on_play_random_pressed():
	print("change")
	get_tree().change_scene_to_file(random_game_scene_path)
	queue_free()

func _on_quit_pressed():
	get_tree().quit()


func _on_sound_control_pressed():
	is_muted = not is_muted
	sound_control.icon = sound_off_icon if is_muted else sound_on_icon

	music_player.stream_paused = is_muted
func _play_click():
	$click_sound.play()
	print("play click")

func _play_hover():
	print("play hover2")

	$hover_sound.play()
	print("play hover")
