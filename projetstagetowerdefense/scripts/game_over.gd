extends Control

@onready var bouton_retour = $BoutonRejouer
@onready var label_score = $Score
@onready var tour = get_tree().current_scene.get_node("Tower")
@onready var spawner = get_tree().current_scene.get_node("spawner") 
@onready var chrono = get_tree().current_scene.get_node("ChronoScore")  
@onready var menu = get_tree().current_scene.get_node("CanvasLayer/MenuPrincipal")

func _ready():
	bouton_retour.pressed.connect(retour_menu)

func retour_menu():

	tour.vie = 200  
	tour.mort = false 
	tour.affichageTour.texture = preload("res://assets/tour.png")
	
	tour.visible = false
	spawner.visible = false
	menu.visible = true
	get_tree().current_scene.get_node("CanvasLayer/GameOver").visible = false


	chrono.stop()
	chrono.start(1.0)
	spawner.timer.start()
	
	#je supprime les ennemies qui existent déja
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()  
		
	tour.barre_vie_tour.visible = true
	
	
