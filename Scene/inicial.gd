extends Node2D

func _ready() -> void:
	# Aguarda 5 segundos
	await get_tree().create_timer(1.0).timeout
	
	# Troca para a próxima cena
	get_tree().change_scene_to_file("res://Scene/Menu.tscn")
