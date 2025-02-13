extends Node2D

@onready var tour = $Tower
@onready var spawner = $spawner
@onready var menu = $CanvasLayer/MenuPrincipal
@onready var game_over_screen = $CanvasLayer/GameOver
@onready var chrono = $ChronoScore
@onready var label_temps = $CanvasLayer/GameOver/Score
@onready var bouton_jouer = $CanvasLayer/MenuPrincipal/ButtonPlay
@onready var bouton_retour_menu = $CanvasLayer/GameOver/BoutonRejouer
@onready var camera = $Camera2D
@onready var info_tour_ui = $CanvasLayer/InfoTour
@onready var label_nom = $CanvasLayer/InfoTour/LabelNom
@onready var progress_vie = $CanvasLayer/InfoTour/ProgressBarVie
@onready var label_vie = $CanvasLayer/InfoTour/LabelVie
@onready var sprite_tour = tour.get_node("Sprite2D") 

var temps_survie = 0.0

func _ready():
	
	info_tour_ui.visible = false
	menu.visible = true 
	game_over_screen.visible = false 
	bouton_retour_menu.visible = false  
	chrono.timeout.connect(_on_timer_timeout)
	tour.visible = false
	spawner.visible = false
	camera.position = Vector2(0, 0)

	bouton_jouer.pressed.connect(_on_bouton_jouer_pressed)

	tour.vie_mise_a_jour.connect(mettre_a_jour_vie)
	
	
func _on_bouton_jouer_pressed():
	start_game()

func start_game():
	
	menu.visible = false
	game_over_screen.visible = false
	bouton_retour_menu.visible = false  
	chrono.start(1.0)
	temps_survie = 0.0
	tour.visible = true
	spawner.visible = true
	spawner.start_spawn() 
	cacher_info_tour()

func game_over():
	game_over_screen.visible = true
	bouton_retour_menu.visible = true
	chrono.stop()

	label_temps.text = "Temps de survie : " + str(temps_survie) + " secondes"

	spawner.stop_spawn()

func _on_timer_timeout():
	temps_survie += 1 
	
func _input(event):
	if event is InputEventMouseButton and event.pressed:
		var mouse_pos = get_global_mouse_position() 
		var sprite_size = sprite_tour.get_texture().get_size() * sprite_tour.scale  
		var rect_min = sprite_tour.global_position - (sprite_size / 2)
		var rect_max = sprite_tour.global_position + (sprite_size / 2)

		if mouse_pos.x >= rect_min.x and mouse_pos.x <= rect_max.x and mouse_pos.y >= rect_min.y and mouse_pos.y <= rect_max.y:
			afficher_info_tour()
		else:
			cacher_info_tour()

func afficher_info_tour():
	info_tour_ui.visible = true
	label_nom.text = "Tour Principale"
	mettre_a_jour_vie(tour.vie) 

func cacher_info_tour():
	info_tour_ui.visible = false
	
func mettre_a_jour_vie(nouvelle_vie):
	progress_vie.value = nouvelle_vie 
	label_vie.text = str(nouvelle_vie) + " / 200"
