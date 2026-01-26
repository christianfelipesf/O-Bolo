extends CharacterBody2D

enum State { IDLE, ATTACK_H, ATTACK_V, RESTING }

@export_group("Configurações Miniboss")
@export var speed := 300.0
@export var health := 4
@export var resting_time := 3.0
@export var attack_duration := 3.0
@export var attack_cooldown := 0.25
@export var orbit_distance := 150.0 # Distância que ele tenta manter do player

# Ponto de spawn para quando estiver em IDLE ou RESTING
var spawn_point: Vector2
var target_player: CharacterBody2D = null

var current_state = State.IDLE
var timer_state := 0.0
var attack_timer := 0.0

@onready var vision_area: Area2D = $visao 

func _ready():
	spawn_point = global_position
	_change_state(State.IDLE)
	
	# Corrigido para verificar o nome correto do nó "visao"
	if has_node("visao"):
		$visao.body_entered.connect(_on_vision_body_entered)
		$visao.body_exited.connect(_on_vision_body_exited)
	else:
		print("ERRO: Nó 'visao' não encontrado no Miniboss!")

func _physics_process(delta: float):
	timer_state += delta
	
	match current_state:
		State.IDLE:
			_move_to_point(delta, spawn_point)
			if target_player:
				_pick_random_attack()
				
		State.ATTACK_H:
			if not target_player: 
				_change_state(State.IDLE)
			else:
				_move_vertical_wave(delta, target_player.global_position)
				_shoot_logic(delta, [Vector2.LEFT, Vector2.RIGHT])
				if timer_state > attack_duration:
					_change_state(State.RESTING)
				
		State.ATTACK_V:
			if not target_player: 
				_change_state(State.IDLE)
			else:
				_move_horizontal_wave(delta, target_player.global_position)
				_shoot_logic(delta, [Vector2.UP, Vector2.DOWN])
				if timer_state > attack_duration:
					_change_state(State.RESTING)
				
		State.RESTING:
			# Retorna ao ponto de spawn para descansar
			_move_to_point(delta, spawn_point)
			if timer_state > resting_time:
				if target_player:
					_pick_random_attack()
				else:
					_change_state(State.IDLE)

	move_and_slide()

# --- LÓGICA DE MOVIMENTO ---

func _move_to_point(delta, point: Vector2):
	var dir = global_position.direction_to(point)
	var dist = global_position.distance_to(point)
	
	if dist > 15:
		velocity = velocity.lerp(dir * speed, 0.1)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, speed * delta * 5)

func _move_vertical_wave(delta, center: Vector2):
	var time = Time.get_ticks_msec() * 0.001
	# Mantém a distância horizontal fixa (orbit_distance) e oscila no Y
	var target_x = center.x + (orbit_distance if global_position.x > center.x else -orbit_distance)
	var wave_y = center.y + sin(time * 5.0) * 150.0
	var target_pos = Vector2(target_x, wave_y)
	
	var desired_velocity = (target_pos - global_position) * 8.0
	velocity = velocity.lerp(desired_velocity, 0.1)

func _move_horizontal_wave(delta, center: Vector2):
	var time = Time.get_ticks_msec() * 0.001
	# Mantém a distância vertical fixa (orbit_distance) e oscila no X
	var target_y = center.y + (orbit_distance if global_position.y > center.y else -orbit_distance)
	var wave_x = center.x + cos(time * 5.0) * 180.0
	var target_pos = Vector2(wave_x, target_y)
	
	var desired_velocity = (target_pos - global_position) * 8.0
	velocity = velocity.lerp(desired_velocity, 0.1)

# --- LÓGICA DE ATAQUE ---

func _shoot_logic(delta, directions: Array):
	attack_timer += delta
	if attack_timer > attack_cooldown:
		for dir in directions:
			_spawn_projectile(dir)
		attack_timer = 0.0

func _spawn_projectile(dir: Vector2):
	var p = MinibossProjectile.new(dir)
	get_tree().current_scene.add_child(p)
	p.global_position = global_position

func _pick_random_attack():
	var roll = randi() % 2
	_change_state(State.ATTACK_H if roll == 0 else State.ATTACK_V)

func _change_state(new_state):
	current_state = new_state
	timer_state = 0.0
	attack_timer = 0.0
	var tw = create_tween()
	match new_state:
		State.RESTING: tw.tween_property(self, "modulate", Color(0.3, 0.6, 1.0), 0.3)
		State.IDLE: tw.tween_property(self, "modulate", Color(0.7, 0.7, 0.7), 0.3)
		_: tw.tween_property(self, "modulate", Color.WHITE, 0.2)

# --- DETECÇÃO ---

func _on_vision_body_entered(body: Node2D):
	if body.is_in_group("Player") or body.name == "Player":
		target_player = body as CharacterBody2D

func _on_vision_body_exited(body: Node2D):
	if body == target_player:
		target_player = null
		if current_state != State.RESTING:
			_change_state(State.IDLE)

# --- DANO ---

func take_damage(amount: int = 1):
	health -= amount
	# Se for atacado enquanto descansa ou está parado, revida imediatamente
	if current_state == State.RESTING or current_state == State.IDLE:
		if target_player: 
			_pick_random_attack()
	
	var tw = create_tween()
	tw.tween_property(self, "modulate", Color.RED, 0.05)
	tw.tween_property(self, "modulate", Color.WHITE, 0.05)
	
	if health <= 0:
		set_physics_process(false)
		tw.set_parallel(true)
		tw.tween_property(self, "scale", Vector2.ZERO, 0.5)
		tw.tween_property(self, "rotation", PI * 2, 0.5)
		await tw.finished
		queue_free()

# --- CLASSE DO PROJÉTIL ---

class MinibossProjectile extends Area2D:
	var direction := Vector2.ZERO
	var speed := 550.0 
	var lifetime := 3.0

	func _init(dir: Vector2):
		direction = dir
		collision_layer = 0
		collision_mask = 1 

		var poly = Polygon2D.new()
		poly.polygon = PackedVector2Array([Vector2(-6,0), Vector2(0,-6), Vector2(6,0), Vector2(0,6)])
		poly.color = Color.YELLOW
		add_child(poly)
		
		var shape = CollisionShape2D.new()
		var circle = CircleShape2D.new()
		circle.radius = 6.0
		shape.shape = circle
		add_child(shape)

	func _ready():
		body_entered.connect(_on_body_entered)
		area_entered.connect(_on_body_entered) 
		
		await get_tree().create_timer(lifetime).timeout
		queue_free()

	func _process(delta):
		global_position += direction * speed * delta

	func _on_body_entered(body):
		if body == null or body == self: return
		if body.is_in_group("Player") or body.name == "Player":
			if body.has_method("take_damage"):
				body.take_damage(1)
			queue_free()
		elif body is StaticBody2D or body is TileMap:
			queue_free()
