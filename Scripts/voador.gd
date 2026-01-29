extends CharacterBody2D

enum State { IDLE, ORBITING, RESTING }

@export_group("Configurações Voador")
@export var speed := 200.0 # Mesma MAX_SPEED do player
@export var acceleration := 500.0 # Mesma ACCELERATION do player
@export var health := 3
@export var orbit_radius := 200.0
@export var orbit_speed := 1.5
@export var attack_cooldown := 2.0

var target_player: CharacterBody2D = null
var current_state = State.IDLE
var timer_state := 0.0
var angle := 0.0 

@onready var vision_area: Area2D = $visao 
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

func _ready():
	_change_state(State.IDLE)
	if nav_agent:
		nav_agent.path_desired_distance = 15.0
		nav_agent.target_desired_distance = 15.0
	if has_node("visao"):
		$visao.body_entered.connect(_on_vision_body_entered)
		$visao.body_exited.connect(_on_vision_body_exited)

func _physics_process(delta: float):
	timer_state += delta
	
	match current_state:
		State.IDLE:
			# Usa a aceleração para parar (atrito) igual ao player
			velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
			if target_player: 
				_change_state(State.ORBITING)
				
		State.ORBITING:
			if not target_player:
				_change_state(State.IDLE)
			else:
				_logic_orbit_nav(delta)
				_logic_shoot(delta)
				
	move_and_slide()

func _logic_orbit_nav(delta: float):
	# 1. Calcula posição alvo na órbita
	angle += orbit_speed * delta
	var offset = Vector2(cos(angle), sin(angle)) * orbit_radius
	var target_pos = target_player.global_position + offset
	
	# 2. Atualiza Navegação
	nav_agent.target_position = target_pos
	
	if nav_agent.is_navigation_finished():
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		return

	# 3. Movimento Tático (Copia a lógica do _processar_movimento do player)
	var next_path_pos = nav_agent.get_next_path_position()
	var input_dir = global_position.direction_to(next_path_pos)
	
	# Aplica aceleração exatamente como o player
	velocity = velocity.move_toward(input_dir * speed, acceleration * delta)

# --- RESTANTE DO CÓDIGO (TIRO E DANO) ---

func _logic_shoot(delta: float):
	if timer_state > attack_cooldown:
		_spawn_arrow()
		timer_state = 0.0

func _spawn_arrow():
	if not target_player: return
	var dir = global_position.direction_to(target_player.global_position)
	var arrow = ArrowProjectile.new(dir, self, target_player) 
	get_tree().current_scene.add_child(arrow)
	arrow.global_position = global_position
	arrow.rotation = dir.angle()

func _change_state(new_state):
	current_state = new_state
	timer_state = 0.0

func _on_vision_body_entered(body: Node2D):
	if body.is_in_group("Player") or body.name == "Player":
		target_player = body

func _on_vision_body_exited(body: Node2D):
	if body == target_player:
		target_player = null
		_change_state(State.IDLE)

func take_damage(amount: int = 1):
	health -= amount
	var tw = create_tween()
	tw.tween_property(self, "modulate", Color.RED, 0.05)
	tw.tween_property(self, "modulate", Color.WHITE, 0.05)
	if health <= 0: queue_free()

# --- CLASSE DO PROJÉTIL ---

class ArrowProjectile extends Area2D:
	var direction := Vector2.ZERO
	var speed := 450.0
	var reflected := false
	var creator: Node2D = null
	var player_ref: CharacterBody2D = null

	func _init(dir: Vector2, owner_ref: Node2D, p_ref: CharacterBody2D):
		direction = dir
		creator = owner_ref
		player_ref = p_ref
		
		var poly = Polygon2D.new()
		poly.polygon = PackedVector2Array([Vector2(10, 0), Vector2(-5, -5), Vector2(-5, 5)])
		poly.color = Color.GOLD
		add_child(poly)
		
		var shape = CollisionShape2D.new()
		shape.shape = CircleShape2D.new()
		shape.shape.radius = 8.0
		add_child(shape)

	func _ready():
		body_entered.connect(_on_impact)
		get_tree().create_timer(4.0).timeout.connect(queue_free)

	func _process(delta):
		global_position += direction * speed * delta
		_check_reflection()

	func _check_reflection():
		if reflected or !player_ref: return
		if player_ref.current_state == 2: # 2 = State.ATTACK
			var attack_node = player_ref.get_node("ataque")
			if attack_node:
				var dist_to_attack = global_position.distance_to(attack_node.global_position)
				if dist_to_attack < player_ref.attack_radius + 15.0:
					reflect()

	func reflect():
		reflected = true
		if creator:
			direction = global_position.direction_to(creator.global_position)
		else:
			direction = -direction
		speed *= 1.6
		modulate = Color.CYAN

	func _on_impact(body):
		if body == player_ref and not reflected:
			if body.has_method("take_damage"): body.take_damage(1)
			queue_free()
		elif body == creator and reflected:
			if body.has_method("take_damage"): body.take_damage(1)
			queue_free()
		elif body is TileMap or body is StaticBody2D:
			queue_free()
