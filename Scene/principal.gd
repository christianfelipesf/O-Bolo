extends CharacterBody2D

# --- Configurações ---
@export var MAX_SPEED = 300.0
@export var ACCELERATION = 1800.0
@export var light_offset_distance: float = 20.0

# --- Referências ---
@onready var health_comp = $HealthComponent
@onready var interaction_comp = $InteractionManager
@onready var _sprite = $AnimatedSprite2D
@onready var luz = $luz

# --- Estados ---
enum State { IDLE, MOVE, ACTION, STUNNED, DEAD }
var current_state = State.IDLE
var looking_at: Vector2 = Vector2.DOWN
var start_position: Vector2

func _ready() -> void:
	start_position = global_position
	# Conecta o sinal de morte do componente de vida
	if health_comp:
		health_comp.health_depleted.connect(_on_death)

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD: return
	
	_update_light(delta)
	
	if current_state == State.STUNNED:
		velocity = velocity.move_toward(Vector2.ZERO, ACCELERATION * delta)
		move_and_slide()
		return

	# Inputs
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	
	if Input.is_action_just_pressed("atacar") or Input.is_action_just_pressed("interagir"):
		_perform_action()
	
	if current_state != State.ACTION:
		_move_logic(input_dir, delta)

func _move_logic(input_dir: Vector2, delta: float) -> void:
	if input_dir != Vector2.ZERO:
		current_state = State.MOVE
		looking_at = input_dir.normalized()
		velocity = velocity.move_toward(input_dir * MAX_SPEED, ACCELERATION * delta)
		_sprite.play(_get_dir_name(looking_at))
	else:
		current_state = State.IDLE
		velocity = velocity.move_toward(Vector2.ZERO, ACCELERATION * delta)
		_sprite.stop()
	move_and_slide()

func _perform_action() -> void:
	current_state = State.ACTION
	velocity = Vector2.ZERO
	
	var target = interaction_comp.get_best_target()
	if target:
		looking_at = global_position.direction_to(target.global_position).normalized()
		interaction_comp.execute_interaction()
		if luz: luz.energy = 1.2
	
	_sprite.play(_get_dir_name(looking_at))
	await get_tree().create_timer(0.2).timeout
	
	if current_state != State.DEAD:
		current_state = State.IDLE

func _update_light(delta: float) -> void:
	if luz:
		luz.energy = move_toward(luz.energy, 0.0, 8.0 * delta)
		luz.position = looking_at * light_offset_distance

func _get_dir_name(dir: Vector2) -> String:
	if abs(dir.x) > abs(dir.y):
		return "direita" if dir.x > 0 else "esquerda"
	else:
		return "baixo" if dir.y > 0 else "cima"

func take_damage(amount: int, force: Vector2 = Vector2.ZERO) -> void:
	if current_state == State.DEAD: return
	velocity = force
	health_comp.damage(amount)
	_apply_stun()

func _apply_stun() -> void:
	current_state = State.STUNNED
	modulate = Color.RED
	await get_tree().create_timer(0.4).timeout
	if current_state != State.DEAD:
		modulate = Color.WHITE
		current_state = State.IDLE

func _on_death() -> void:
	current_state = State.DEAD
	modulate = Color.BLACK
	await get_tree().create_timer(1.0).timeout
	# Reset para teste
	global_position = start_position
	health_comp.current_health = health_comp.max_health
	modulate = Color.WHITE
	current_state = State.IDLE
