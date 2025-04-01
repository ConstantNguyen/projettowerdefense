extends Node3D

@export var max_pv: float = 200.0
@export var projectile_scene: PackedScene
@export var shoot_interval: float = 1.0  
@export var dead_tower: PackedScene

var enemy_target: Node3D = null
var ennemies = []
var is_dead = false
var pv : float = 200
var password: String
var power_password: String
var password_entered = false 
var tower_name: String
var resistance: float = 0.0 
var decay_rate: float = 0.05
var min_resistance: float = 5.0  


@export var min_password_strength: float = 1.0  # Minimum password strength
@export var max_password_strength: float = 100.0  # Maximum password strength

@export var length_multiplier: float = 1.5  # Length factor
@export var diversity_multiplier: float = 2.0  # Diversity factor (lowercase, uppercase, numbers, symbols)
@export var char_set_boost: float = 20.0  # Boost factor for strong characters (letters and symbols)
@export var repeat_penalty: float = -5.0  # Penalty for repeated characters
@export var max_unique_chars: int = 26  # The maximum number of unique characters to count
@export var decay_acceleration: float = 0.01

@onready var tour_health_bar = $SubViewport/TowerHealthBar
@onready var body = $MeshInstance3D/StaticBody3D
@onready var timer = $Timer  	
@onready var detection_area = $Area3D 
@onready var mesh_instance = $MeshInstance3D

@onready var panel_color = $Panel
@onready var info_panel = $Panel/UI/InfoTour
@onready var info_label = $Panel/UI/InfoTour/Label

@onready var password_input = $Panel/UI/ZoneMDP/LineEdit
@onready var password_button = $Panel/UI/ZoneMDP/Button
@onready var password_text_label = $Panel/UI/ZoneMDP/Label

@onready var new_password_label = $Panel/UI/ZoneMDP/Label2
@onready var new_password_input = $Panel/UI/ZoneMDP/LineEdit2
@onready var confirm_password_label = $Panel/UI/ZoneMDP/Label3
@onready var confirm_password_input = $Panel/UI/ZoneMDP/LineEdit3
@onready var confirm_password_button = $Panel/UI/ZoneMDP/Button2



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
		ennemies.append(enemy)
		enemy.set_tower(self)
		

func _on_enemy_exited(enemy):
	ennemies.erase(enemy)
	
	
func set_new_password(new_password: String):
	password = new_password
	resistance = calculate_password_strength(password)
	print("New password set: ", password)

# Calculate resistance based on the password strength
func calculate_password_strength(password: String) -> float:
	var strength = 0.0
	var length = password.length()

	# Base strength based on length (longer is stronger)
	strength += length * length_multiplier

	# Track character categories
	var has_lower = false
	var has_upper = false
	var has_numbers = false
	var has_symbols = false
	
	var lower_chars = {}  # Store unique lowercase characters
	var upper_chars = {}  # Store unique uppercase characters
	var number_chars = {}  # Store unique numeric characters
	var symbol_chars = {}  # Store unique symbol characters
	
	# Loop through the password and categorize each character
	for c in password:
		if c.to_lower() == c:
			has_lower = true
			lower_chars[c] = true
		elif c.to_upper() == c:
			has_upper = true
			upper_chars[c] = true
		elif c.to_int() != null:
			has_numbers = true
			number_chars[c] = true
		else:
			has_symbols = true
			symbol_chars[c] = true

	# Add diversity boost based on character types used
	var diversity_count = 0
	if has_lower:
		diversity_count += 1
	if has_upper:
		diversity_count += 1
	if has_numbers:
		diversity_count += 1
	if has_symbols:
		diversity_count += 1
	
	strength += diversity_count * diversity_multiplier

	# Character Set Boost: Increase strength based on number of unique characters in each category
	strength += len(lower_chars) * char_set_boost
	strength += len(upper_chars) * char_set_boost
	strength += len(number_chars) * char_set_boost
	strength += len(symbol_chars) * char_set_boost

	# Penalty for repeated characters: If a character appears more than once, penalize the password strength
	var unique_characters = lower_chars.keys() + upper_chars.keys() + number_chars.keys() + symbol_chars.keys()
	var repeated_characters = password.length() - unique_characters.size()
	if repeated_characters > 0:
		strength += repeat_penalty * repeated_characters  # Apply penalty

	# Maximum character set bonus based on the number of unique characters (e.g., 26 unique letters max)
	var max_unique_chars_limit = min(max_unique_chars, password.length())  # Limit by password length
	strength = min(strength, max_password_strength)  # Cap the strength to avoid excessive values

	# Clamp strength between min and max values
	print(strength)
	return clamp(strength, min_password_strength, max_password_strength)


func _process(delta):
	if resistance > min_resistance:
		resistance -= decay_rate * delta
		decay_rate += decay_acceleration * delta
		
		#if resistance <= min_resistance + 10:
			#prompt_password_change()  # Prompt user to change password when resistance is low


func prompt_password_change():
	print("Your password is getting weak! Change it now!")

func take_attack():
	if resistance > 0:
		resistance -= decay_rate  
		print("Tower resisting! Resistance left:", resistance)
		
		if resistance <= min_resistance:
			print("Resistance is critically low!")
			prompt_password_change()
	else:
		print("Tower destroyed!")
		die()  









func die():
	for enemy in ennemies:
		enemy.set_tower(null)
		enemy.stop_attack()
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
		panel_color.visible = true
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
			confirm_password_button.visible = true
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
	panel_color.visible = false

	new_password_label.visible = false
	new_password_input.visible = false
	confirm_password_label.visible = false
	confirm_password_input.visible = false
	confirm_password_button.visible = false

					
func _on_password_submitted():
	password_entered = true
	password_input.visible = false
	password_button.visible = false
	
	self.set_new_password(password_input.text)
	
	password = "Mot de passe : " + password_input.text + "\n Votre mot de passe est " + power_password

	
	password_text_label.text = password
	password_text_label.visible = true 
	
	
