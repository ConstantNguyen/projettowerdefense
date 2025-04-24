extends CharacterBody3D

@export var speed: float = 0.03
@export var max_pv: float = 20.0
@export var attack_interval = 1.5

@onready var health_bar = $SubViewport/EnemyHealthBar
@onready var detection_area = $Area3D
@onready var attack_timer = $Timer
@onready var password_label: Node3D = $PasswordDisplay

var possible_chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()"
var colors = [Color.RED, Color.BLUE, Color.GREEN]
var brute_force_attempt = ""

var pathfollow: PathFollow3D = null
var path: Path3D = null
var tower: Node = null
var is_dead: bool = false
var is_attacking = false
var pv: float = max_pv

func _ready():
	detection_area.body_entered.connect(_on_detection_zone_body_entered)
	if get_parent() is PathFollow3D:
		pathfollow = get_parent()
	attack_timer.wait_time = attack_interval
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start()
	health_bar.value = pv / max_pv * 100

func _physics_process(delta):
	if is_dead:
		return

	if path == null and pathfollow != null and pathfollow.get_parent() is Path3D:
		path = pathfollow.get_parent()

	if is_attacking:
		if pathfollow:
			pathfollow.progress = pathfollow.progress  # gèle la position
		if tower == null or tower.is_dead:
			stop_attack()
	else:
		if pathfollow:
			pathfollow.progress += speed

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
	password_label.visible = true

	while is_attacking:
		if tower == null or tower.is_dead:
			stop_attack()
			break
		tower.take_attack()
		take_damage(2)
		generate_random_password(6)
		await get_tree().create_timer(0.5).timeout

func stop_attack():
	is_attacking = false
	password_label.visible = false

func take_damage(amount: int):
	pv -= amount
	health_bar.value = pv / max_pv * 100
	if pv <= 0:
		die()

func die():
	is_dead = true
	stop_attack()
	queue_free()

func generate_random_password(length: int):
	for child in password_label.get_children():
		child.queue_free()

	for i in range(length):
		var char = possible_chars[randi() % possible_chars.length()]
		var color = colors[randi() % colors.size()]

		var label = Label3D.new()
		label.text = char
		label.modulate = color
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.position = Vector3(i * 0.2, 0, 0)
		password_label.add_child(label)

func _on_detection_zone_body_entered(body):
	if body.get_parent().is_in_group("intersection"):
		body = body.get_parent()
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
	if new_path == null:
		push_warning("switch_path: path est null")
		return

	path = new_path
	var new_pathfollow = PathFollow3D.new()
	new_pathfollow.rotation_mode = PathFollow3D.ROTATION_Y
	new_pathfollow.progress = 0.0
	new_pathfollow.add_child(self)
	path.add_child(new_pathfollow)
	pathfollow = new_pathfollow

	if path.curve.get_point_count() > 0:
		var start_pos = path.curve.get_point_position(0)
		var t = new_pathfollow.transform
		t.origin = start_pos
		new_pathfollow.transform = t

@export var speed_manual := 2.0
var path_points: Array[Vector3] = []
var current_index := 0

func _manual_ready_path_logic():
	await get_tree().process_frame
	if path_points.is_empty():
		push_error("Aucun point de chemin reçu")
		return
	global_position = path_points[0]

func _manual_process_path_logic(delta):
	if current_index >= path_points.size():
		queue_free()
		return

	var target = path_points[current_index]
	var direction = (target - global_position).normalized()
	var distance = global_position.distance_to(target)

	if distance < 0.1:
		current_index += 1
	else:
		global_position += direction * speed_manual * delta
