extends Node3D

@export var max_pv: float = 200.0
@export var projectile_scene: PackedScene
@export var shoot_interval: float = 1.0  
@export var dead_tower: PackedScene

var enemy_target: Node3D = null
var list_enemies = []
var is_dead = false
var pv : float = 200
var password: String
var power_password: String
var password_entered = false 
var tower_name: String

@onready var tour_health_bar = $SubViewport/TowerHealthBar
@onready var body = $MeshInstance3D/StaticBody3D
@onready var timer = $Timer  	
@onready var detection_area = $Area3D 
@onready var mesh_instance = $MeshInstance3D

@onready var info_panel = $UI/InfoTour
@onready var info_label = $UI/InfoTour/Label

@onready var password_input = $UI/ZoneMDP/LineEdit
@onready var password_button = $UI/ZoneMDP/Button
@onready var password_text_label = $UI/ZoneMDP/Label

@onready var new_password_label = $UI/ZoneMDP/Label2
@onready var new_password_input = $UI/ZoneMDP/LineEdit2
@onready var confirm_password_label = $UI/ZoneMDP/Label3
@onready var confirm_password_input = $UI/ZoneMDP/LineEdit3




func _ready():

	body.add_to_group("towers")
	tour_health_bar.value = pv/max_pv * 100
	#timer.wait_time = shoot_interval  
	#timer.timeout.connect(shoot_projectile)  
	#timer.start()  
	
	
	
	detection_area.body_entered.connect(_on_enemy_entered)
	detection_area.body_exited.connect(_on_enemy_exited)
	
	body.input_event.connect(_on_tower_clicked)
	password_button.pressed.connect(_on_password_submitted)
	
	hide_password_elements()
	



func _on_enemy_entered(enemy):
	if enemy is CharacterBody3D:
		list_enemies.append(enemy)
		if enemy_target == null:  
			change_target()

func _on_enemy_exited(enemy):
	list_enemies.erase(enemy)
	change_target()



func change_target():
	if list_enemies.size() > 0:
		enemy_target = list_enemies[0]
	else:
		enemy_target = null

func shoot_projectile():
	if enemy_target == null:
		return

	if projectile_scene:
		var projectile = projectile_scene.instantiate()
		projectile.target = enemy_target
		get_parent().add_child(projectile)
		projectile.position = position
		
func take_damage(amount):
	pv -= amount
	pv = max(pv, 0) 
	tour_health_bar.value = pv/max_pv * 100

	if pv <= 0:
		die() 

func die():
	is_dead = true
	tour_health_bar.visible = false
	body.remove_from_group("towers")
	body.queue_free()
	detection_area.queue_free()
	visible = false
	
	# Instancie et ajoute le modèle de la tour morte
	if dead_tower:
		mesh_instance.mesh = null
	timer.stop() 
	get_parent().game_over()

			
func _on_tower_clicked(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hide_password_elements()

		info_panel.visible = true
		password_text_label.visible = true
		info_label.text = "Vie de la tour: " + str(pv)

		if password_entered:
			# Mot de passe déjà validé → masquer champ d’entrée
			password_input.visible = false
			password_button.visible = false
			password_text_label.text = self.password

			# Afficher les champs pour changer le mot de passe
			new_password_label.visible = true
			new_password_input.visible = true
			confirm_password_label.visible = true
			confirm_password_input.visible = true
		else:
			# Afficher le champ pour entrer le mot de passe
			password_input.visible = true
			password_button.visible = true
			password_text_label.text = "Saisir un mot de passe pour la tour"



func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var space_state = get_world_3d().direct_space_state
		var ray_origin = get_viewport().get_camera_3d().project_ray_origin(event.position)
		var ray_end = ray_origin + get_viewport().get_camera_3d().project_ray_normal(event.position) * 1000

		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		var result = space_state.intersect_ray(query)

		hide_password_elements()
		



func hide_password_elements():
	password_input.visible = false
	password_button.visible = false
	password_text_label.visible = false
	info_panel.visible = false

	new_password_label.visible = false
	new_password_input.visible = false
	confirm_password_label.visible = false
	confirm_password_input.visible = false

	password_input.visible = false
	password_button.visible = false
	password_text_label.visible = false
	info_panel.visible = false
	

					
func _on_password_submitted():
	password_entered = true
	password_input.visible = false
	password_button.visible = false
	
	self.update_tower_life(password_input.text)
	
	password = "Mot de passe : " + password_input.text + "\n Votre mot de passe est " + power_password

	
	password_text_label.text = password
	password_text_label.visible = true 
	
	
func update_tower_life(password: String):
	var strength = self.evaluate_password_strength(password)
	# Logique pour augmenter la vie de la tour en fonction de la force du mot de passe
	if strength == 0:
		pass  # Mot de passe très faible, la vie ne change pas
	elif strength == 1:
		pv += 5  # Mot de passe faible, la vie augmente un peu
		power_password = "faible"
	elif strength == 2:
		pv += 10  # Mot de passe moyen
		power_password = "moyen"
	elif strength == 3:
		pv += 15  # Mot de passe assez fort
		power_password = "assez fort"
	elif strength == 4:
		pv += 20  # Mot de passe très fort
		power_password = "très fort"
	
	# La vie ne doit jamais descendre en dessous de 50
	pv = max(pv, 50)	
	
	


func evaluate_password_strength(password: String) -> int:
	var strength = 0
	var upper_count = 0
	var digit_count = 0
	var special_count = 0
	
	# Longueur du mot de passe (si plus de 8 caractères)
	if password.length() > 8:
		strength += 1
	
	# Comptabiliser les majuscules
	for char in password:
		if char == char.to_upper() and char != char.to_lower():  # Vérifie si le caractère est une majuscule
			upper_count += 1
	
	# Comptabiliser les chiffres
	for char in password:
		if char.to_int() != null:  # Vérifie si le caractère peut être converti en entier
			digit_count += 1
	
	# Comptabiliser les caractères spéciaux
	var special_chars = "!@#$%^&*(),.?\":{}|<>"
	for char in password:
		if special_chars.contains(char):  # Vérifie si le caractère est un caractère spécial
			special_count += 1
	
	# Ajouter à la force selon les critères
	if upper_count > 0:
		strength += 1
	if digit_count > 0:
		strength += 1
	if special_count > 0:
		strength += 1
	
	return strength
	


	
	
