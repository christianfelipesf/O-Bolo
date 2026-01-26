extends Area2D

# Configurações do Portal
@export var cooldown_seconds: float = 2.0
@export var tempo_transicao: float = 0.5
@export var tempo_espera_escuro: float = 1.0
@onready var local = $Target.global_position

var is_active: bool = true

func _ready() -> void:
	# Conecta o sinal de entrada de corpo
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	# Verifica se o portal está ativo e se é o jogador
	if is_active and (body.name == "Player" or body.is_in_group("player")):
		executar_teletransporte_com_fade(body)

func executar_teletransporte_com_fade(player: Node2D) -> void:
	is_active = false # Inicia o cooldown imediatamente
	
	# Busca as referências exatamente como no script de diálogo que já funciona
	var ui_canvas = get_tree().root.find_child("CanvasLayer", true, false)
	var ui_transicao = null
	
	if ui_canvas:
		# Tenta pegar pelo nome "Transicao" conforme o script do Sprite2D
		if ui_canvas.has_node("Transicao"):
			ui_transicao = ui_canvas.get_node("Transicao")
		else:
			# Busca alternativa caso o nome seja diferente
			ui_transicao = ui_canvas.find_child("ColorRect", true, false)

	if not ui_transicao:
		push_warning("Aviso: Nó de transição não encontrado. Teleportando sem efeito.")
		aplicar_movimento_teleporte(player)
	else:
		# 1. Configuração inicial (forçar visibilidade e resetar alpha)
		ui_transicao.visible = true
		ui_transicao.modulate.a = 0.0
		
		# 2. Fade In (Escurecer)
		var tween = create_tween()
		await tween.tween_property(ui_transicao, "modulate:a", 1.0, tempo_transicao).finished
		
		# 3. Teleporte (ocorre com a tela 100% preta)
		aplicar_movimento_teleporte(player)
		
		# 4. Pausa com a tela preta
		await get_tree().create_timer(tempo_espera_escuro).timeout
		
		# 5. Fade Out (Clarear)
		var tween_out = create_tween()
		await tween_out.tween_property(ui_transicao, "modulate:a", 0.0, tempo_transicao).finished
		
		# 6. Esconde o nó
		ui_transicao.visible = false

	# 7. Aguarda o tempo de recarga para o portal poder ser usado novamente
	await get_tree().create_timer(cooldown_seconds).timeout
	is_active = true

func aplicar_movimento_teleporte(player: Node2D) -> void:
	# Pega a posição do metadado "pos" (Vector3)
	if has_meta("pos"):
		var target_pos_v3 = get_meta("pos")
		print(target_pos_v3)
		var target_pos_v2 = Vector2(target_pos_v3.x, target_pos_v3.y)
		
		if "velocity" in player:
			player.velocity = Vector2.ZERO
			
		player.global_position = local #target_pos_v2
		print("Portal: Player teleportado para ", local)
	else:
		push_error("ERRO: O Area2D não possui o metadado 'pos' do tipo Vector3!")
