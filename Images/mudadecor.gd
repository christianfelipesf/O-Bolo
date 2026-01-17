extends Control

@onready var sprite := $Sprite2D
var gradient: Gradient

func _ready() -> void:
	gradient = sprite.texture.gradient
	_animar_gradiente()

func _animar_gradiente() -> void:
	var tween := create_tween()
	tween.set_loops()
	
	tween.tween_property(
		gradient,
		"colors",
		PackedColorArray([Color.RED, Color.BLUE]),
		2.0
	)
	
	tween.tween_property(
		gradient,
		"colors",
		PackedColorArray([Color.GREEN, Color.PURPLE]),
		2.0
	)
