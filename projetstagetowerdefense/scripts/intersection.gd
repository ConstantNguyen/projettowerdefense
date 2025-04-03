extends Node3D

@export var origin_path : Path3D
@export var paths : Array[Path3D] = []

func _ready() -> void:
	add_to_group("intersection")

func get_origin () : 
	return origin_path

func get_paths () : 
	return paths
