extends Control

@onready var bouton_jouer = $ButtonPlay

func _ready():
	bouton_jouer.pressed.connect(_on_bouton_jouer_pressed)

func _on_bouton_jouer_pressed():
	get_parent().get_parent().start_game() 
