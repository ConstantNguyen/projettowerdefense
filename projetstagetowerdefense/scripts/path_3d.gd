extends Path3D

@export var linked_towers : Array[Node3D] = []

func _ready():
	add_to_group("paths")
	
	

func _process(delta) :
	if !is_valid() :
		remove_from_group("paths")

func is_valid():
	return linked_towers.any(func(tower): return !tower.is_dead)
