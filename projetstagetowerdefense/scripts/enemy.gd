extends CharacterBody3D

@export var speed: float = 0.03
@export var max_pv: float = 20.0
@export var attack_interval = 1.5

@onready var health_bar = $SubViewport/EnemyHealthBar  
@onready var detection_area = $Area3D 
@onready var attack_timer = $Timer

var pathfollow : PathFollow3D
var path : Path3D
var tower: Node 
var is_dead: bool = false  
var is_attacking = false
var parent = null
var pv : float = max_pv

func _ready():
	detection_area.body_entered.connect(_on_detection_zone_body_entered)
	#health_bar.value = pv/max_pv * 100
	if get_parent() is PathFollow3D :
		parent = get_parent()
	attack_timer.wait_time = attack_interval
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	attack_timer.start()

func _physics_process(delta):
	if is_dead:
		return
	if path and !path.is_in_group("paths") and speed > 0:
		speed = -speed
	if is_attacking :
		parent.progress = parent.progress
		if tower.is_dead : 
			is_attacking = false
	else : 
		pathfollow.progress += speed 

func _on_attack_timer_timeout():
	if tower != null:
		start_attack()

func set_tower(t: Node):
	tower = t


func start_attack():
	is_attacking = true
	print("Enemy attacking the tower")
	tower.take_attack() 

func stop_attack():
	is_attacking = false
	print("Enemy stopped attacking the towe")

func die():
	is_dead = true
	queue_free()

func _on_detection_zone_body_entered(body):
	if body.get_parent().is_in_group("intersection"):
		body = body.get_parent()
		var possible_paths = body.get_paths()
		for possibility in possible_paths : 
			if !possibility.is_in_group("paths") :
				possible_paths.erase(possibility)
		if possible_paths.size() > 0 :
			var new_path = possible_paths[RandomNumberGenerator.new().randi_range(0, possible_paths.size() - 1)]
			if speed < 0 : 
				speed = -speed
			switch_path(new_path)
		else :
			if speed > 0 :   
				speed = -speed 
			var origin = body.get_origin()
			if path != origin :
				switch_path(origin) 



func switch_path(new_path): 
	if pathfollow:  # Vérifie si l'ennemi a déjà un parent
			pathfollow.remove_child(self)
	pathfollow = PathFollow3D.new()
	pathfollow.rotation_mode = PathFollow3D.ROTATION_Y  # Pour suivre la rotation du chemin
	pathfollow.progress_ratio = 0.0
	
	# Instancie l'ennemi et l'ajoute en tant qu'enfant du PathFollow3D
	pathfollow.add_child(self)
	path = new_path
	# Ajoute PathFollow3D au Path3D
	path.add_child(pathfollow)
