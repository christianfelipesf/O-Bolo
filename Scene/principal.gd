extends CharacterBody2D

# Definição dos estados possíveis
enum State { IDLE, MOVE, ATTACK, STUNNED }
var current_state = State.STUNNED

const MAX_SPEED = 300.0
const ACCELERATION = 1800.0

@onready var _animated_sprite = $AnimatedSprite2D

func _physics_process(delta: float) -> void:
	# Se estiver atordoado/travado, não processa movimento nem input
	if current_state == State.STUNNED:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	# Só permite movimento se não estiver atacando
	if current_state != State.ATTACK:
		_processar_movimento(input_dir, delta)

	move_and_slide()

func _processar_movimento(input_dir: Vector2, delta: float) -> void:
	if input_dir != Vector2.ZERO:
		current_state = State.MOVE
		velocity = velocity.move_toward(input_dir * MAX_SPEED, ACCELERATION * delta)
		_atualizar_animacao(input_dir)
	else:
		current_state = State.IDLE
		velocity = Vector2.ZERO
		_animated_sprite.stop()

# --- FUNÇÕES PARA RECEBER SINAIS EXTERNOS ---

# Outro script pode chamar: player.set_frozen(true)
func set_frozen(should_freeze: bool) -> void:
	if should_freeze:
		current_state = State.STUNNED
		_animated_sprite.stop()
	else:
		current_state = State.IDLE

# Outro script pode chamar: player.take_damage()
func take_damage() -> void:
	# Exemplo: trava o player por 0.5 segundos ao levar dano
	set_frozen(true)
	await get_tree().create_timer(0.5).timeout
	set_frozen(false)

func _atualizar_animacao(direcao: Vector2) -> void:
	if abs(direcao.x) > abs(direcao.y):
		_animated_sprite.play("direita" if direcao.x > 0 else "esquerda")
	else:
		_animated_sprite.play("baixo" if direcao.y > 0 else "cima")
