extends Node3D

@export var path_node: Node3D
@export var enemy_scene: PackedScene 
@export var spawn_interval: float = 3.0 

@onready var timer = $Timer

func _ready():
	timer.wait_time = spawn_interval
	timer.timeout.connect(spawn_enemy)
	timer.start()
	spawn_enemy()


func spawn_enemy():
	var enemy = enemy_scene.instantiate()
	# Crée un PathFollow3D
	var path_follow = PathFollow3D.new()
	path_follow.rotation_mode = PathFollow3D.ROTATION_Y  # Pour suivre la rotation du chemin
	path_follow.progress_ratio = 0.0

	# Instancie l'ennemi et l'ajoute en tant qu'enfant du PathFollow3D
	path_follow.add_child(enemy)

	# Ajoute PathFollow3D au Path3D
	path_node.add_child(path_follow)
