extends Control

@export var game_scene_path: String = "res://scenes/MainScene.tscn"
@export var is_game_over: bool = false

func _ready():
	$Button.connect("pressed", Callable(self, "_on_play_pressed"))
	$Button2.connect("pressed", Callable(self, "_on_quit_pressed"))
	$Button3.connect("pressed", Callable(self, "_on_play_pressed"))
	
	# Affiche le bon bouton selon si c'est un lancement ou une fin de partie
	if is_game_over:
		$Button.visible = false
		$Button3.visible = true
		$Label.text = "Game Over !"
	else:
		$Button.visible = true
		$Button3.visible = false
		$Label.text = "Bienvenue dans le jeu !"

func _on_play_pressed():
	print("change")
	get_tree().change_scene_to_file(game_scene_path)
	queue_free()

func _on_quit_pressed():
	get_tree().quit()
