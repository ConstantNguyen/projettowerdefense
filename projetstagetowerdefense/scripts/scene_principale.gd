extends Node2D

@onready var tour = $Tower 

func _ready():
	center_tower()
	get_window().size_changed.connect(center_tower)

func center_tower():
	var screen_size = get_viewport().size
	tour.position = screen_size / 2
