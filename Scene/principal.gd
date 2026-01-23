extends CharacterBody2D

# --- Configurações de Atributos ---
@export var max_health: int = 3
var current_health: int
var start_position: Vector2

# --- Configurações de Debug ---
@export_group("Debug Visual")
@export var debug_view: bool = true
@export var attack_range: float = 40.0
@export var attack_radius: float = 20.0
@export var looking_at: Vector2 = Vector2.DOWN:
	set(val):
		looking_at = val
		queue_redraw()

enum State { IDLE, MOVE, ATTACK, STUNNED, DEAD }
var current_state = State.IDLE

const MAX_SPEED = 300.0
const ACCELERATION = 1800.0

@onready var _animated_sprite = $AnimatedSprite2D

func _ready() -> void:
	# Salva a posição inicial e define a vida cheia
	start_position = global_position
	current_health = max_health

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return

	if current_state == State.STUNNED:
		# Aplicamos uma fricção para o player não deslizar infinitamente
		velocity = velocity.move_toward(Vector2.ZERO, ACCELERATION * delta)
		move_and_slide()
		return

	# Input de Ataque
	if Input.is_action_just_pressed("atacar") and current_state != State.ATTACK:
		_atacar()

	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if current_state != State.ATTACK:
		_processar_movimento(input_dir, delta)
		move_and_slide()

func _processar_movimento(input_dir: Vector2, delta: float) -> void:
	if input_dir != Vector2.ZERO:
		current_state = State.MOVE
		looking_at = input_dir.normalized()
		velocity = velocity.move_toward(input_dir * MAX_SPEED, ACCELERATION * delta)
		_atualizar_animacao(input_dir)
	else:
		current_state = State.IDLE
		velocity = Vector2.ZERO
		_animated_sprite.stop()

# --- SISTEMA DE DANO E ESTADO ---

# No script do PLAYER, substitua a função take_damage por esta:

func take_damage(amount: int = 1, force: Vector2 = Vector2.ZERO) -> void:
	if current_state == State.DEAD: return
	
	current_health -= amount
	
	# Aplicamos a força ANTES de mudar o estado
	velocity = force 
	current_state = State.STUNNED
	
	if current_health <= 0:
		_morrer()
	else:
		_aplicar_stun(0.4) # Chama a função que gerencia o tempo do stun

func _aplicar_stun(duration: float) -> void:
	current_state = State.STUNNED
	modulate = Color.RED # Feedback visual
	
	await get_tree().create_timer(duration).timeout
	
	if current_state != State.DEAD:
		modulate = Color.WHITE
		current_state = State.IDLE

func _morrer() -> void:
	current_state = State.DEAD
	modulate = Color.BLACK # Indica que morreu
	print("O player morreu!")
	
	# Pequena pausa antes de resetar para o jogador ver que morreu
	await get_tree().create_timer(1.0).timeout
	_reset_player()

func _reset_player() -> void:
	global_position = start_position
	current_health = max_health
	current_state = State.IDLE
	modulate = Color.WHITE
	print("Player resetado!")

# --- MÉTODOS DE ATAQUE E AUXILIARES ---

func _atacar() -> void:
	current_state = State.ATTACK
	velocity = Vector2.ZERO
	_verificar_colisao_ataque()
	
	await get_tree().create_timer(0.2).timeout
	
	if current_state == State.ATTACK:
		current_state = State.IDLE

func _verificar_colisao_ataque() -> void:
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()
	var circle = CircleShape2D.new()
	circle.radius = attack_radius
	query.shape = circle
	query.transform = global_transform.translated(looking_at * attack_range)

	var results = space_state.intersect_shape(query)
	for result in results:
		var body = result.collider
		if body.has_method("take_damage") and body != self:
			body.take_damage()

func _get_dir_name(dir: Vector2) -> String:
	if abs(dir.x) > abs(dir.y):
		return "direita" if dir.x > 0 else "esquerda"
	else:
		return "baixo" if dir.y > 0 else "cima"

func _atualizar_animacao(direcao: Vector2) -> void:
	_animated_sprite.play(_get_dir_name(direcao))

func _draw() -> void:
	if debug_view:
		draw_line(Vector2.ZERO, looking_at * attack_range, Color.CHARTREUSE, 2.0)
		draw_circle(looking_at * attack_range, attack_radius, Color(1, 0, 0, 0.3))
