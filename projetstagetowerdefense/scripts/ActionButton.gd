extends Button

@export var scene_to_instantiate: PackedScene
@export var grid_map_node: NodePath
@export var grid_y_level: float
@export var allowed_tiles: Array[int] = [0,1]
@export var button_texture: Texture2D

var is_dragging: bool = false
var dragged_instance: Node3D
var camera: Camera3D
var grid_map: GridMap
var controller
const RAYCAST_LENGTH: float = 100.0

var last_valid_position: Vector3
var has_valid_position: bool = false

func _ready():
	camera = get_viewport().get_camera_3d()
	if grid_map_node.is_empty():
		push_error("ERREUR : grid_map_node n'est pas assigné dans l'inspecteur.")
	else:
		grid_map = get_node(grid_map_node)
		if grid_map == null:
			push_error("ERREUR : grid_map introuvable avec le NodePath assigné !")

	controller = get_tree().get_first_node_in_group("game_controller")
	if controller == null:
		push_error("GameController non trouvé (manque dans le groupe 'game_controller')")

	if button_texture:
		var texture_rect = TextureRect.new()
		texture_rect.texture = button_texture
		texture_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH
		texture_rect.stretch_mode = TextureRect.STRETCH_SCALE
		texture_rect.size = Vector2(89, 89)
		texture_rect.custom_minimum_size = Vector2(89, 89)
		texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	if scene_to_instantiate and controller and controller.can_place_tower():
		dragged_instance = scene_to_instantiate.instantiate()
		get_tree().current_scene.add_child(dragged_instance)
		dragged_instance.visible = false
		is_dragging = true
		has_valid_position = false

func _physics_process(_delta):
	if not is_dragging or dragged_instance == null or grid_map == null:
		return

	var mouse_pos = get_viewport().get_mouse_position()
	var from = camera.project_ray_origin(mouse_pos)
	var to = from + camera.project_ray_normal(mouse_pos) * RAYCAST_LENGTH

	var space_state = camera.get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)

	if result and result.collider == grid_map:
		var position = result.position
		var cell_size = grid_map.cell_size
		position.x = round(position.x / cell_size.x) * cell_size.x + 1 - 0.4
		position.z = round(position.z / cell_size.z) * cell_size.z + 1 + 0.5
		position.y = grid_y_level

		var cell = grid_map.local_to_map(position)
		var cell_item = grid_map.get_cell_item(cell)

		if allowed_tiles.has(cell_item):
			dragged_instance.visible = true
			dragged_instance.global_position = position
			last_valid_position = position
			has_valid_position = true
		else:
			if has_valid_position:
				dragged_instance.visible = true
				dragged_instance.global_position = last_valid_position
			else:
				dragged_instance.visible = false
	else:
		if has_valid_position:
			dragged_instance.visible = true
			dragged_instance.global_position = last_valid_position
		else:
			if dragged_instance:
				dragged_instance.visible = false

func _input(event):
	if not is_dragging:
		return

	# Si clic droit : annule le drag
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if dragged_instance:
			dragged_instance.queue_free()
		is_dragging = false
		return

	# Si clic gauche relâché : valider placement
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
		is_dragging = false

		if not has_valid_position:
			if dragged_instance:
				dragged_instance.queue_free()
			return

		if last_valid_position.x < 16 or last_valid_position.x > 30:
			print("Position dans un champ interdit")
			dragged_instance.queue_free()
			return

		if controller == null or not controller.can_place_tower():
			print("Trop de tours placées")
			dragged_instance.queue_free()
			return

		dragged_instance.visible = true
		controller.notify_tower_placed()

		if controller.placed_towers == controller.MAX_TOWERS:
			self.visible = false
