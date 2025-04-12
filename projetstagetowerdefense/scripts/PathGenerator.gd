extends Object
class_name PathGenerator

var _grid_length: int
var _grid_height: int
var _path: Array[Vector2i]

func _init(length: int, height: int):
	_grid_length = length
	_grid_height = height
	_path = []
	
func set_path(path: Array[Vector2i]):
	_path = path

func add_path_segment(segment: Array[Vector2i]):
	for p in segment:
		if not _path.has(p):
			_path.append(p)

func generate_path() -> Array[Vector2i]:
	_path.clear()
	var x = 0
	var y = int(_grid_height / 2)

	while x < _grid_length:
		if not _path.has(Vector2i(x, y)):
			_path.append(Vector2i(x, y))

		var choice = randi_range(0, 2)

		if choice == 0 or x % 2 == 0 or x == _grid_length - 1:
			x += 1
		elif choice == 1 and y < _grid_height - 2 and not _path.has(Vector2i(x, y + 1)):
			y += 1
		elif choice == 2 and y > 1 and not _path.has(Vector2i(x, y - 1)):
			y -= 1

	return _path

func get_tile_score(tile: Vector2i) -> int:
	var score = 0
	var x = tile.x
	var y = tile.y

	score += 1 if _path.has(Vector2i(x, y - 1)) else 0  # haut
	score += 2 if _path.has(Vector2i(x + 1, y)) else 0  # droite
	score += 4 if _path.has(Vector2i(x, y + 1)) else 0  # bas
	score += 8 if _path.has(Vector2i(x - 1, y)) else 0  # gauche

	return score

func get_path() -> Array[Vector2i]:
	debug_path()
	return _path

#aide debug
func debug_path():
	for p in _path:
		print("tile:", p, " → score: ", get_tile_score(p))
