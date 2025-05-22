extends PathFollow3D

@export var speed := 0.03
var started := false
var tours: Array = []        # Liste dynamique des tours
var target_tower: Node3D = null

func _ready():
	await get_tree().process_frame
	started = true

func _physics_process(delta):
	if not started:
		return
	
	# Met à jour la liste des tours à chaque frame (tu peux optimiser)
	tours = get_tree().get_nodes_in_group("towers")
	
	# Trouve la tour la plus proche
	target_tower = get_closest_tower()
	
	if target_tower == null:
		# Aucune tour, avance normalement sur le chemin
		progress += speed * delta
	else:
		# Avance vers la tour la plus proche
		move_towards_target(delta)

func get_closest_tower() -> Node3D:
	var closest = null
	var min_dist = INF
	for tower in tours:
		var dist = global_transform.origin.distance_to(tower.global_transform.origin)
		if dist < min_dist:
			min_dist = dist
			closest = tower
	return closest

func move_towards_target(delta):
	if target_tower == null:
		return
	
	var direction = (target_tower.global_transform.origin - global_transform.origin).normalized()
	global_translate(direction * speed * delta)
	look_at(target_tower.global_transform.origin, Vector3.UP)
