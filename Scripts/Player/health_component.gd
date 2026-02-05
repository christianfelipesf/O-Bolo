extends Node
class_name HealthComponent

signal health_depleted
signal health_changed(new_health)

@export var max_health: int = 3
var current_health: int

func _ready():
	current_health = max_health

func damage(amount: int):
	# Use apenas max()
	current_health = max(0, current_health - amount)
	health_changed.emit(current_health)
	
	if current_health <= 0:
		health_depleted.emit()
		
func heal(amount: int):
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health)
