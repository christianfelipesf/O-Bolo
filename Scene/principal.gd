extends CharacterBody2D

const MAX_SPEED = 300.0
const ACCELERATION = 1800.0

# Referência ao nó de animação
@onready var _animated_sprite = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	if input_dir != Vector2.ZERO:
		# Movimentação
		velocity = velocity.move_toward(input_dir * MAX_SPEED, ACCELERATION * delta)
		
		# Lógica de Animação
		_atualizar_animacao(input_dir)
	else:
		velocity = Vector2.ZERO
		# Para a animação no frame atual
		_animated_sprite.stop()

	move_and_slide()

func _atualizar_animacao(direcao: Vector2) -> void:
	# Priorizamos a animação baseada no eixo que o jogador está pressionando mais forte
	if abs(direcao.x) > abs(direcao.y):
		if direcao.x > 0:
			_animated_sprite.play("direita")
		else:
			_animated_sprite.play("esquerda")
	else:
		if direcao.y > 0:
			_animated_sprite.play("baixo")
		else:
			_animated_sprite.play("cima")
