@tool
extends Node3D

@export var tower_life: float = 50.0  # Vie initiale de la tour commence à 50
@onready var password_input = $CanvasLayer/LineEdit  # Récupère le LineEdit
@onready var progress_bar = $CanvasLayer/ProgressBar  # Récupère le ProgressBar

# Fonction pour évaluer la force du mot de passe
func evaluate_password_strength(password: String) -> int:
	var strength = 0
	var upper_count = 0
	var digit_count = 0
	var special_count = 0
	
	# Longueur du mot de passe (si plus de 8 caractères)
	if password.length() > 8:
		strength += 1
	
	# Comptabiliser les majuscules
	for char in password:
		if char == char.to_upper() and char != char.to_lower():  # Vérifie si le caractère est une majuscule
			upper_count += 1
	
	# Comptabiliser les chiffres
	for char in password:
		if char.to_int() != null:  # Vérifie si le caractère peut être converti en entier
			digit_count += 1
	
	# Comptabiliser les caractères spéciaux
	var special_chars = "!@#$%^&*(),.?\":{}|<>"
	for char in password:
		if special_chars.contains(char):  # Vérifie si le caractère est un caractère spécial
			special_count += 1
	
	# Ajouter à la force selon les critères
	if upper_count > 0:
		strength += 1
	if digit_count > 0:
		strength += 1
	if special_count > 0:
		strength += 1
	
	return strength


# Fonction pour mettre à jour la vie de la tour
func update_tower_life(password: String):
	var strength = evaluate_password_strength(password)
	print("Strength:", strength)  # Affiche la force du mot de passe pour le débogage
	
	# Logique pour augmenter la vie de la tour en fonction de la force du mot de passe
	if strength == 0:
		pass  # Mot de passe très faible, la vie ne change pas
	elif strength == 1:
		tower_life += 5  # Mot de passe faible, la vie augmente un peu
	elif strength == 2:
		tower_life += 10  # Mot de passe moyen
	elif strength == 3:
		tower_life += 15  # Mot de passe assez fort
	elif strength == 4:
		tower_life += 20  # Mot de passe très fort
	
	# La vie ne doit jamais descendre en dessous de 50
	tower_life = max(tower_life, 50)

	# La vie peut dépasser 100, mais clampée à 100 si nécessaire
	if tower_life > 100:
		tower_life = 100
	
	progress_bar.value = tower_life  # Mise à jour du ProgressBar
	print("Tour Life: ", tower_life)

# Méthode appelée à chaque changement de texte dans LineEdit (mise à jour en temps réel)
func _on_LineEdit_text_changed(new_text: String):
	update_tower_life(new_text)

# Méthode de validation lorsque l'utilisateur soumet le texte (appuie sur Entrée)
func _on_LineEdit_text_submitted(submitted_text: String):
	update_tower_life(submitted_text)
	print("Mot de passe validé : ", submitted_text)
	password_input.clear()  # Optionnel : vide le champ après validation
