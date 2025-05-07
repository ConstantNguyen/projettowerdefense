extends Node3D

@export var enemy_scene: PackedScene
@export var path_node: Path3D
@export var max_active_enemies := 5  # Limite maximale d'ennemis présents

@onready var spawn_timer = $Timer

var spawn_interval = 5.0
var started = false

func _ready():
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.stop()

func start_spawning():
	started = true
	spawn_timer.start()

func _on_spawn_timer_timeout():
	if not started:
		return

	# Vérifie combien d'ennemis sont déjà dans la scène
	var active_enemies = get_tree().get_nodes_in_group("enemies_rdm").size()
	if active_enemies >= max_active_enemies:
		print("⚠ Trop d'ennemis actifs, on attend…")
		return  # Trop d'ennemis, on attend

	spawn_enemy()

	# Adapter le rythme selon le temps
	var main_node = get_tree().get_root().get_node_or_null("Main")
	if main_node:
		var total_seconds = main_node.seconds_passed
		if total_seconds < 60:
			spawn_timer.wait_time = 5.0
		elif total_seconds < 120:
			spawn_timer.wait_time = 3.0
		else:
			spawn_timer.wait_time = 2.0
	else:
		push_error("⚠ Impossible de trouver le node 'Main' pour lire le temps.")

func spawn_enemy():
	if enemy_scene == null or path_node == null:
		push_error("enemy_scene ou path_node non défini dans SpawnerRdmLvl !")
		return

	var enemy = enemy_scene.instantiate()
	enemy.global_transform.origin = global_transform.origin

	# Assigner le chemin au nouvel ennemi
	if enemy.has_method("set_path"):
		enemy.set_path(path_node)
	else:
		push_error("L'ennemi n'a pas de méthode set_path !")

	# Ajoute au groupe pour le suivi
	enemy.add_to_group("enemies_rdm")

	add_child(enemy)
