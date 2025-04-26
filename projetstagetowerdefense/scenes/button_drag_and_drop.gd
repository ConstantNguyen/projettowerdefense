extends Button

@export var scene_to_instantiate: PackedScene
@export var grid_map_node: NodePath  # ← pour savoir quelle gridmap viser
@export var grid_y_level: float = 0.2  # ← niveau Y où poser l'objet

var is_dragging: bool = false
var dragged_instance: Node3D
var camera: Camera3D
var grid_map: GridMap
const RAYCAST_LENGTH: float = 100.0

func _ready():
	camera = get_viewport().get_camera_3d()
	if grid_map_node:
		grid_map = get_node(grid_map_node)

func _on_button_down() -> void:
	if scene_to_instantiate:
		print("Bouton pressé, instanciation...")
		dragged_instance = scene_to_instantiate.instantiate()
		get_tree().current_scene.add_child(dragged_instance)
		dragged_instance.visible = false
		is_dragging = true

func _physics_process(_delta):
	if is_dragging and dragged_instance:
		var mouse_pos = get_viewport().get_mouse_position()
		var from = camera.project_ray_origin(mouse_pos)
		var to = from + camera.project_ray_normal(mouse_pos) * RAYCAST_LENGTH
		
		var space_state = camera.get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, to)
		var result = space_state.intersect_ray(query)
		
		if result:
			print("Raycast touche :", result.collider)
		else:
			print("Raycast ne touche rien.")
		
		if result and result.collider == grid_map:
			dragged_instance.visible = true
			var position = result.position
			
			# Aligner à la grille
			var cell_size = grid_map.cell_size
			position.x = round(position.x / cell_size.x) * cell_size.x
			position.z = round(position.z / cell_size.z) * cell_size.z
			position.y = grid_y_level  # Forcer la hauteur voulue
			
			dragged_instance.global_position = position
		else:
			dragged_instance.visible = false

func _input(event):
	if is_dragging and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		is_dragging = false
		if dragged_instance:
			dragged_instance.visible = true
