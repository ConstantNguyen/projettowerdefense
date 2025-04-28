extends Button

@export var scene_to_instantiate: PackedScene
@export var grid_map_node: NodePath
@export var grid_y_level: float
@export var allowed_tiles: Array[int] = [0,1]  # ← IDs des tuiles valides pour poser
@export var button_texture: Texture2D


var is_dragging: bool = false
var dragged_instance: Node3D
var camera: Camera3D
var grid_map: GridMap
const RAYCAST_LENGTH: float = 100.0

var last_valid_position: Vector3
var has_valid_position: bool = false

func _ready():
	camera = get_viewport().get_camera_3d()
	if grid_map_node:
		grid_map = get_node(grid_map_node)
		
	if button_texture:
		var texture_rect = TextureRect.new()
		texture_rect.texture = button_texture
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH  # Adapter tout en respectant la taille
		texture_rect.stretch_mode = TextureRect.STRETCH_SCALE  # Permet le redimensionnement
		texture_rect.size = Vector2(89, 89)
		texture_rect.custom_minimum_size = Vector2(89, 89)
		texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Ne bloque pas les clics sur le bouton
		add_child(texture_rect)
		texture_rect.anchor_left = 0.5
		texture_rect.anchor_top = 0.5
		texture_rect.anchor_right = 0.5
		texture_rect.anchor_bottom = 0.5
		texture_rect.offset_left = -44.5
		texture_rect.offset_top = -44.5
		texture_rect.offset_right = 44.5
		texture_rect.offset_bottom = 44.5

func _on_button_down() -> void:
	if scene_to_instantiate:
		print("Bouton pressé, instanciation...")
		dragged_instance = scene_to_instantiate.instantiate()
		get_tree().current_scene.add_child(dragged_instance)
		dragged_instance.visible = false
		is_dragging = true
		has_valid_position = false

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
			if result.collider == grid_map:
				var position = result.position
				
				# Aligner à la grille
				var cell_size = grid_map.cell_size
				position.x = round(position.x / cell_size.x) * cell_size.x + 1 - 0.4
				position.z = round(position.z / cell_size.z) * cell_size.z + 1 + 0.5
				position.y = grid_y_level

				# Vérifier si la tuile est autorisée
				var cell = grid_map.local_to_map(position)
				var cell_item = grid_map.get_cell_item(cell)
				print("ID de la tuile :", cell_item)
				
				if allowed_tiles.has(cell_item):
					dragged_instance.visible = true
					dragged_instance.global_position = position
					
					# Mémoriser dernière bonne position
					last_valid_position = position
					has_valid_position = true
				else:
					print("Tuile non autorisée pour placer.")
					if has_valid_position:
						dragged_instance.visible = true
						dragged_instance.global_position = last_valid_position
					else:
						dragged_instance.visible = false
		else:
			print("Raycast ne touche rien.")
			if has_valid_position:
				dragged_instance.visible = true
				dragged_instance.global_position = last_valid_position
			else:
				dragged_instance.visible = false

func _input(event):
	if is_dragging and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		is_dragging = false
		if dragged_instance:
			dragged_instance.visible = true
