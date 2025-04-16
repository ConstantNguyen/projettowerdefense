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
var shaking: bool = false

@export var min_password_strength: float = 1.0  # Minimum password strength
@export var max_password_strength: float = 100.0  # Maximum password strength

@export var length_multiplier: float = 1.5  # Length factor
@export var diversity_multiplier: float = 2.0  # Diversity factor (lowercase, uppercase, numbers, symbols)
@export var char_set_boost: float = 20.0  # Boost factor for strong characters (letters and symbols)
@export var repeat_penalty: float = -5.0  # Penalty for repeated characters
@export var max_unique_chars: int = 26  # The maximum number of unique characters to count
@export var decay_acceleration: float = 0.01

@export var shake_intensity: float = 0.1  # Adjust shaking power
@export var shake_duration: float = 0.5  # Time the shake lasts@onready var original_position: Vector3 = global_transform.origin
@onready var original_position: Vector3 = global_transform.origin

@onready var tour_health_bar = $SubViewport/TowerHealthBar
@onready var body = $MeshInstance3D/StaticBody3D
@onready var timer = $Timer  	
@onready var detection_area = $Area3D 
@onready var mesh_instance = $MeshInstance3D

@onready var password_scene = $CanvasLayer/PasswordScene
@onready var password_input = $CanvasLayer/PasswordScene/UI/MainContainer/VBox/password_input
@onready var confirm_password_input_1 = $CanvasLayer/PasswordScene/UI/MainContainer/VBox/password_confirmation_input
@onready var set_button = $CanvasLayer/PasswordScene/UI/MainContainer/VBox/set_password_button
@onready var set_info_label = $CanvasLayer/PasswordScene/UI/MainContainer/VBox/info
@onready var res_label_set = $CanvasLayer/PasswordScene/UI/HBoxContainer/res

@onready var change_scene = $CanvasLayer2/PasswordChangeScene
@onready var old_password_input = $CanvasLayer2/PasswordChangeScene/UI/MainContainer/VBox/old_password_input
@onready var new_password_input = $CanvasLayer2/PasswordChangeScene/UI/MainContainer/VBox/new_password_input
@onready var confirm_password_input_2 = $CanvasLayer2/PasswordChangeScene/UI/MainContainer/VBox/confirm_password_input
@onready var change_button = $CanvasLayer2/PasswordChangeScene/UI/MainContainer/VBox/change_password_button
@onready var change_info_label = $CanvasLayer2/PasswordChangeScene/UI/MainContainer/VBox/info
@onready var res_label_change = $CanvasLayer2/PasswordChangeScene/UI/HBoxContainer/res

@onready var windows = $WindowLights.get_children()
var lights_timer = null



func _ready():

	body.add_to_group("towers")
	tour_health_bar.value = pv/max_pv * 100	
	
	
	detection_area.body_entered.connect(_on_enemy_entered)
	detection_area.body_exited.connect(_on_enemy_exited)
	
	body.input_event.connect(_on_tower_clicked)
	
	set_button.pressed.connect(_on_password_submit)
	change_button.pressed.connect(_on_password_change_submit)
	hide_all_ui()
	
	lights_timer = Timer.new()
	timer.wait_time = 1
	timer.one_shot = false
	timer.connect("timeout", Callable(self, "activate_lights"))
	add_child(timer)
	timer.start()
	



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
	if shaking:
		var offset = Vector3(randf_range(-shake_intensity, shake_intensity), 0, randf_range(-shake_intensity, shake_intensity))
		global_transform.origin = original_position + offset
	if resistance > min_resistance:
		resistance -= decay_rate * delta
		decay_rate += decay_acceleration * delta
		
		if resistance <= min_resistance + 10:
			start_shaking()
			
	res_label_change.text = "Vie de la tour : %d" % resistance
	


func start_shaking():
	if shaking:
		return
	shaking = true
	var timer = get_tree().create_timer(shake_duration)
	timer.timeout.connect(stop_shaking)
	set_process(true)


func stop_shaking():
	shaking = false
	global_transform.origin = original_position  # Reset position
	


func take_attack():
	if resistance > 0:
		resistance -= decay_rate  
		print("Tower resisting! Resistance left:", resistance)
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
		var dead_tower_instance = dead_tower.instantiate()
		get_parent().add_child(dead_tower_instance)
		dead_tower_instance.global_transform = global_transform

	mesh_instance.queue_free()
	timer.stop() 
	get_parent().game_over()
	hide_all_ui()

			
func _on_tower_clicked(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hide_all_ui()
		if password:
			show_password_change_scene()
		else:
			show_password_scene()

		



func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var space_state = get_world_3d().direct_space_state
		var ray_origin = get_viewport().get_camera_3d().project_ray_origin(event.position)
		var ray_end = ray_origin + get_viewport().get_camera_3d().project_ray_normal(event.position) * 1000

		var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
		var result = space_state.intersect_ray(query)

		hide_all_ui()
		


func _on_password_submit():
	var input = password_input.text.strip_edges()
	var confirm_pw = confirm_password_input_1.text.strip_edges()

	if input == "" or input != confirm_pw:
		show_message("Les nouveaux mots de passe ne correspondent pas ou sont vides.", set_info_label)
		return
	
	set_new_password(input)
	password_entered = true
	show_message("Mot de passe enregistré : " + password, set_info_label)


	hide_password_scene(true)
	
func _on_password_change_submit():
	var old_pw = old_password_input.text.strip_edges()
	var new_pw = new_password_input.text.strip_edges()
	var confirm_pw = confirm_password_input_2.text.strip_edges()

	if old_pw != password:
		show_message("Ancien mot de passe incorrect.", change_info_label)
		return

	if new_pw == "" or new_pw != confirm_pw:
		show_message("Les nouveaux mots de passe ne correspondent pas ou sont vides.", change_info_label)
		return

	set_new_password(new_pw)
	show_message("Mot de passe changé avec succès !", change_info_label)
	hide_password_change_scene(true)
	
func show_password_scene():
	hide_all_ui()
	password_scene.visible = true
	res_label_set.text = "Vie de la tour : %d" % resistance


func hide_password_scene(delay := false):
	if delay:
		await get_tree().create_timer(1.5).timeout
	password_scene.visible = false
	password_input.text = ""
	confirm_password_input_1.text = ""

func show_password_change_scene():
	hide_all_ui()
	change_scene.visible = true
	old_password_input.text = ""
	new_password_input.text = ""
	confirm_password_input_2.text = ""
	res_label_change.text = "Vie de la tour : %d" % resistance


func hide_password_change_scene(delay := false):
	if delay:
		await get_tree().create_timer(1.5).timeout
	change_scene.visible = false

func hide_all_ui():
	password_scene.visible = false
	change_scene.visible = false
	empty_inputs()

func empty_inputs():
	old_password_input.text = "" 
	new_password_input.text = ""
	confirm_password_input_1.text = ""
	confirm_password_input_2.text = ""
	
func show_message(text: String, label):
	label.text = text
	label.visible = true
	
func activate_lights() :
	for window in windows : 
		window.visible = false
	var nb_lights = randi() % windows.size() - 2
	for i in range(nb_lights) :
		windows[randi() % windows.size()].visible = true
