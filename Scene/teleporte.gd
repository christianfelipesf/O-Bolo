extends StaticBody2D

# Referência à Area2D que detectará o jogador
@onready var teleport_area: Area2D = $TeleportArea

func _ready() -> void:
	# Conecta o sinal de entrada na área
	teleport_area.body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Verifica se quem entrou foi o Player (ajuste o nome se necessário)
	if body.name == "Player" or body.is_in_group("player"):
		
		# 1. Pegar os metadados
		if has_meta("pos"):
			var target_pos_v3 = get_meta("pos")
			# Converte Vector3 para Vector2 (pegando X e Y)
			var target_pos_v2 = Vector2(target_pos_v3.x, target_pos_v3.y)
			
			# 2. Iniciar o delay de 2 segundos
			await get_tree().create_timer(2.0).timeout
			
			# 3. Teleportar o jogador
			# Se for CharacterBody2D, usamos global_position
			body.global_position = target_pos_v2
			
			print("Ema foi transportada pela magia da Bruxa!")
		else:
			print("Erro: Metadado 'pos' não encontrado no StaticBody2D.")
