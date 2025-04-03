extends CharacterBody3D

@export var speed: float = 0.005
@export var max_pv: float = 20.0
@export var attack_interval = 1.5

@onready var health_bar = $SubViewport/EnemyHealthBar  
@onready var detection_area = $Area3D 
@onready var attack_timer = $Timer
@onready var password_label: Label3D = $Label3D  # Label above the enemy

var possible_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()"  
var brute_force_attempt = ""  # Stores the current brute-force password attempt

var pathfollow : PathFollow3D
var path : Path3D
var tower: Node = null
var is_dead: bool = false  
var is_attacking = false
var parent = null
var pv : float = max_pv

func _ready():
	detection_area.body_entered.connect(_on_detection_zone_body_entered)
	if get_parent() is PathFollow3D:
		parent = get_parent()
	attack_timer.wait_time = attack_interval
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start()

func _physics_process(delta):
	if is_dead:
		return
	if path and !path.is_in_group("paths") and speed > 0:
		speed = -speed
	if is_attacking:
		parent.progress = parent.progress
		if tower == null or tower.is_dead: 
			stop_attack()
	else:
		parent.progress += speed + delta 

func _on_attack_timer_timeout():
	if tower != null and !tower.is_dead:
		start_attack()

func set_tower(t: Node):
	tower = t

func start_attack():
	if tower == null or tower.is_dead:
		stop_attack()
		return
		
	is_attacking = true
	password_label.visible = true  # Show password attempt

	while is_attacking:
		if tower == null or tower.is_dead:
			stop_attack()
			break
		tower.take_attack()
		update_brute_force_display()
		await get_tree().create_timer(0.5).timeout  # Updates password every 0.5 seconds

func stop_attack():
	is_attacking = false
	password_label.visible = false  # Hide password attempt when attack stops

func update_brute_force_display():
	brute_force_attempt = generate_random_password(6)
	password_label.text = brute_force_attempt

func generate_random_password(length: int) -> String:
	var password = ""
	for i in range(length):
		password += possible_chars[randi() % possible_chars.length()]
	return password

func die():
	is_dead = true
	stop_attack()  # Ensure attack stops when enemy dies
	queue_free()

func _on_detection_zone_body_entered(body):
	if body.is_in_group("intersection"):
		var possible_paths = body.get_paths()
		for possibility in possible_paths:
			if !possibility.is_in_group("paths"):
				possible_paths.erase(possibility)
		if possible_paths.size() > 0:
			var new_path = possible_paths[RandomNumberGenerator.new().randi_range(0, possible_paths.size() - 1)]
			if speed < 0:
				speed = -speed
			switch_path(new_path)
		else:
			if speed > 0:
				speed = -speed
			var origin = body.get_origin()
			if path != origin:
				switch_path(origin)

func switch_path(new_path):
	if pathfollow:
		pathfollow.queue_free()
	pathfollow = PathFollow3D.new()
	pathfollow.rotation_mode = PathFollow3D.ROTATION_Y
	pathfollow.progress_ratio = 0.0
	pathfollow.add_child(self)
	path = new_path
	path.add_child(pathfollow)
