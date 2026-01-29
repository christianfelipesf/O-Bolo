extends CharacterBody2D

# --- Configurações de Atributos ---
@export var max_health: int = 3
var current_health: int
var start_position: Vector2

# --- Configurações de Ataque e Luz ---
@export_group("Configurações de Combate")
@export var attack_range: float = 40.0
@export var attack_radius: float = 35.0
@export var light_intensity_speed: float = 8.0 # Velocidade do fade da luz

# --- Referências de Nós ---
@onready var _animated_sprite = $AnimatedSprite2D
@onready var luz = $luz
@onready var ataque_marker = $ataque # Seu Marker2D

# --- Estados ---
enum State { IDLE, MOVE, ATTACK, STUNNED, DEAD }
var current_state = State.IDLE

const MAX_SPEED = 300.0
const ACCELERATION = 1800.0

@export_group("Debug Visual")
@export var debug_view: bool = false
var looking_at: Vector2 = Vector2.DOWN:
	set(val):
		looking_at = val
		queue_redraw()

func _ready() -> void:
	start_position = global_position
	current_health = max_health
	# Garante que a luz comece apagada
	if luz:
		luz.energy = 0.0

func _physics_process(delta: float) -> void:
	
	#shader
	RenderingServer.global_shader_parameter_set("player_pos", global_position)
	if current_state == State.DEAD:
		return

	# Suaviza a energia da luz de volta para 0 constantemente
	if luz and luz.energy > 0:
		luz.energy = move_toward(luz.energy, 0.0, light_intensity_speed * delta)

	if current_state == State.STUNNED:
		velocity = velocity.move_toward(Vector2.ZERO, ACCELERATION * delta)
		move_and_slide()
		return

	if Input.is_action_just_pressed("atacar") and current_state != State.ATTACK:
		_atacar()

	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if current_state != State.ATTACK:
		_processar_movimento(input_dir, delta)
		move_and_slide()
		_atualizar_posicoes_auxiliares()

func _processar_movimento(input_dir: Vector2, delta: float) -> void:
	if input_dir != Vector2.ZERO:
		current_state = State.MOVE
		looking_at = input_dir.normalized()
		velocity = velocity.move_toward(input_dir * MAX_SPEED, ACCELERATION * delta)
		_animated_sprite.play(_get_dir_name(looking_at))
	else:
		current_state = State.IDLE
		velocity = Vector2.ZERO
		_animated_sprite.stop()

func _atualizar_posicoes_auxiliares() -> void:
	# Move o Marker2D e a Luz para a frente de onde o player olha
	var target_pos = looking_at * attack_range
	
	if ataque_marker:
		ataque_marker.position = target_pos
	
	if luz:
		luz.position = target_pos

# --- SISTEMA DE COMBATE ---

func _atacar() -> void:
	current_state = State.ATTACK
	velocity = Vector2.ZERO
	
	# Efeito da Luz
	if luz:
		luz.energy = 1.0
	
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
	
	# Agora usamos a posição global do Marker2D para a detecção
	query.transform = ataque_marker.global_transform

	var results = space_state.intersect_shape(query)
	for result in results:
		var body = result.collider
		if body.has_method("take_damage") and body != self:
			body.take_damage()

# --- DANO E MORTE ---

func take_damage(amount: int = 1, force: Vector2 = Vector2.ZERO) -> void:
	if current_state == State.DEAD: return
	current_health -= amount
	velocity = force 
	_aplicar_stun(0.4)
	
	if current_health <= 0:
		_morrer()



func _aplicar_stun(duration: float) -> void:
	current_state = State.STUNNED
	modulate = Color.RED
	await get_tree().create_timer(duration).timeout
	if current_state != State.DEAD:
		modulate = Color.WHITE
		current_state = State.IDLE

func _morrer() -> void:
	current_state = State.DEAD
	modulate = Color.BLACK
	await get_tree().create_timer(1.0).timeout
	_reset_player()

func _reset_player() -> void:
	global_position = start_position
	current_health = max_health
	current_state = State.IDLE
	modulate = Color.WHITE

# --- AUXILIARES ---

func _get_dir_name(dir: Vector2) -> String:
	if abs(dir.x) > abs(dir.y):
		return "direita" if dir.x > 0 else "esquerda"
	else:
		return "baixo" if dir.y > 0 else "cima"

func _draw() -> void:
	if debug_view and ataque_marker:
		# Desenha o círculo de debug na posição do marker
		draw_circle(ataque_marker.position, attack_radius, Color(1, 0, 0, 0.3))
