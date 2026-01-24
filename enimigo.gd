extends CharacterBody2D

@export_group("Configurações de Movimento")
@export var MAX_SPEED := 100.0 
@export var ACCELERATION := 500.0
@export var STOP_DISTANCE := 50.0 

@export_group("Configurações de Patrulha")
@export var WANDER_RADIUS := 250.0 
@export var WANDER_WAIT_TIME := 2.5 

@export_group("Combate")
@export var health := 3
@export var damage_cooldown := 1.0
@export var knockback_force := 500.0

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var visao: Area2D = $visao

var target: CharacterBody2D = null
var origin_pos: Vector2 
var next_wander_pos: Vector2
var is_waiting := false
var is_stunned := false
var can_damage := true
var returning_to_base := false # Nova trava para o retorno

func _ready():
	origin_pos = global_position
	next_wander_pos = origin_pos
	
	visao.body_entered.connect(_on_visao_body_entered)
	visao.body_exited.connect(_on_visao_body_exited)
	
	await get_tree().process_frame

func _physics_process(delta: float) -> void:
	if is_stunned:
		velocity = velocity.move_toward(Vector2.ZERO, ACCELERATION * delta)
		move_and_slide()
		return

	if target:
		# ESTADO: PERSEGUIR
		returning_to_base = false 
		_mover_para_posicao(target.global_position, delta, STOP_DISTANCE)
		_checar_dano_player()
	elif returning_to_base:
		# ESTADO: VOLTAR PARA O SPAWN
		_mover_para_posicao(origin_pos, delta, 10.0)
		if global_position.distance_to(origin_pos) < 20.0:
			returning_to_base = false # Voltou, agora pode patrulhar
	else:
		# ESTADO: PATRULHA ALEATÓRIA
		_patrulhar(delta)
	
	move_and_slide()

# --- LÓGICA DE MOVIMENTO ---

func _mover_para_posicao(pos: Vector2, delta: float, dist_parada: float):
	nav_agent.target_position = pos
	var dist = global_position.distance_to(pos)
	
	if dist > dist_parada and not nav_agent.is_navigation_finished():
		var dir = global_position.direction_to(nav_agent.get_next_path_position())
		velocity = velocity.move_toward(dir * MAX_SPEED, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, ACCELERATION * delta)

func _patrulhar(delta: float):
	if is_waiting:
		velocity = velocity.move_toward(Vector2.ZERO, ACCELERATION * delta)
		return

	if global_position.distance_to(next_wander_pos) < 15.0:
		_esperar_para_novo_ponto()
		return

	_mover_para_posicao(next_wander_pos, delta, 5.0)

func _esperar_para_novo_ponto():
	is_waiting = true
	await get_tree().create_timer(WANDER_WAIT_TIME).timeout
	
	# Calcula ponto aleatório ao redor da origem (spawn)
	var angle = randf() * TAU
	var dist = randf() * WANDER_RADIUS
	next_wander_pos = origin_pos + Vector2(cos(angle), sin(angle)) * dist
	
	is_waiting = false

# --- SINAIS ---

# No topo do script, certifique-se de que o target está como CharacterBody2D

# Modifique os sinais para serem mais "apelões" na detecção:
func _on_visao_body_entered(body: Node2D):
	# Ele vai perseguir se o corpo for o Player (pelo nome ou grupo)
	if body.name == "Player" or body.is_in_group("Player"):
		print("Player detectado!") # Isso aparecerá no Output se funcionar
		target = body
		is_waiting = false

func _on_visao_body_exited(body: Node2D):
	if body == target:
		print("Player saiu da visão!")
		target = null
		returning_to_base = true

# --- FUNÇÕES DE DANO (MANTIDAS) ---

func _checar_dano_player():
	var dist = global_position.distance_to(target.global_position)
	if dist < STOP_DISTANCE + 15 and can_damage:
		_causar_dano_player()

func _causar_dano_player():
	if target.has_method("take_damage"):
		var knockback_dir = global_position.direction_to(target.global_position)
		target.take_damage(1, knockback_dir * knockback_force)
		can_damage = false
		await get_tree().create_timer(damage_cooldown).timeout
		can_damage = true

func take_damage():
	# (Coloque aqui sua lógica de animação de dano e morte que já tínhamos)
	if health <= 0: return
	health -= 1
	var tw = create_tween()
	tw.tween_property(self, "modulate", Color.RED, 0.1)
	tw.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	if health <= 0:
		is_stunned = true
		tw.tween_property(self, "modulate:a", 0, 0.3)
		await tw.finished
		queue_free()
	else:
		if target:
			velocity = target.global_position.direction_to(global_position) * 400.0
		is_stunned = true
		await get_tree().create_timer(0.4).timeout
		is_stunned = false
