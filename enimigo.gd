extends CharacterBody2D

@export_group("Configurações")
@export var MAX_SPEED := 100.0 
@export var ACCELERATION := 500.0
@export var STOP_DISTANCE := 60.0 
@export var health := 3
@export var damage_cooldown := 1.0
@export var knockback_force := 500.0 # Força do empurrão que o player sentirá

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var col_shape: CollisionShape2D = $CollisionShape2D

var target: Node2D 
var is_stunned := false
var can_damage := true

func _ready():
	target = get_tree().root.find_child("Player", true, false)
	await get_tree().process_frame

func _physics_process(delta: float) -> void:
	if is_stunned or not is_instance_valid(target):
		velocity = velocity.move_toward(Vector2.ZERO, ACCELERATION * delta)
		move_and_slide()
		return

	nav_agent.target_position = target.global_position
	var dist = global_position.distance_to(target.global_position)
	
	if dist < STOP_DISTANCE + 10 and can_damage: 
		_causar_dano_player()
	
	if dist > STOP_DISTANCE and not nav_agent.is_navigation_finished():
		var dir = global_position.direction_to(nav_agent.get_next_path_position())
		velocity = velocity.move_toward(dir * MAX_SPEED, ACCELERATION * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, ACCELERATION * delta)
	
	move_and_slide()

func _causar_dano_player():
	if target.has_method("take_damage"):
		# Calcula a direção do inimigo para o player
		var knockback_dir = global_position.direction_to(target.global_position)
		var força_final = knockback_dir * knockback_force # Aumentei para 800 para ser bem visível
		
		# IMPORTANTE: Passar os dois parâmetros
		target.take_damage(1, força_final)
		
		can_damage = false
		await get_tree().create_timer(damage_cooldown).timeout
		can_damage = true

func take_damage():
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
		# Knockback que o inimigo sofre ao ser atingido
		velocity = target.global_position.direction_to(global_position) * 400.0
		is_stunned = true
		await get_tree().create_timer(0.4).timeout
		is_stunned = false
