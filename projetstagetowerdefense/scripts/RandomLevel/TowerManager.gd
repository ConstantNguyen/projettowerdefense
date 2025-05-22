extends Node
var gestion_tour = preload("res://scripts/RandomLevel/TowerManager.gd").new()

var towers = []

func add_tower(tower_node):
	towers.append(tower_node)

func remove_tower(tower_node):
	towers.erase(tower_node)

func get_closest_tower(position: Vector3) -> Node3D:
	var closest = null
	var min_dist = INF
	for tower in towers:
		var dist = tower.global_position.distance_to(position)
		if dist < min_dist:
			min_dist = dist
			closest = tower
	return closest
