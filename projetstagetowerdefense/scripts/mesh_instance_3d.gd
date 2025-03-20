extends MeshInstance3D

@export var new_color : Color = Color(0.2, 0.5, 0)

func _ready():
	# Crée un nouveau matériau
	var material = StandardMaterial3D.new()
	
	# Change la couleur d'albédo (couleur de base)
	material.albedo_color = new_color
	
	# Applique le matériau au mesh
	self.material_override = material
