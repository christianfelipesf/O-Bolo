extends Sprite2D

# --- Configurações de Diálogo ---
@export_group("Diálogos")
@export_multiline var falas_objeto: Array[String] = [
	"Isso parece ser um baú antigo.",
	"Está trancado, mas há um cheiro de bolo vindo de dentro...",
	"Melhor procurar uma chave."
]

var indice_fala: int = 0
var dialogo_ativo: bool = false
var pode_auto_ativar: bool = true
var esta_digitando: bool = false

# --- Configurações de Interação ---
@export var interacao_distancia: float = 45.0
@export var velocidade_digitacao: float = 0.05 # Tempo entre letras
@export var tempo_transicao: float = 0.5 # Tempo para escurecer/clarear
@export var tempo_espera_escuro: float = 1.0 # Tempo que fica tudo preto após teleportar

@onready var player = get_tree().get_first_node_in_group("player")
@onready var audio_player = $audio

# Referências da UI
@onready var ui_canvas = get_tree().root.find_child("CanvasLayer", true, false)
@onready var ui_control = ui_canvas.get_node("Control")
@onready var ui_texto = ui_canvas.get_node("Control/Panel/RichTextLabel")
@onready var ui_transicao = ui_canvas.get_node("Transicao") # Referência ao nó de transição

func _ready() -> void:
	# Garante que a transição comece invisível
	if ui_transicao:
		ui_transicao.modulate.a = 0
		ui_transicao.visible = false

func _process(_delta: float) -> void:
	if player:
		var distancia = global_position.distance_to(player.global_position)
		var olhando = _player_esta_olhando()
		
		if distancia <= interacao_distancia:
			if not dialogo_ativo and pode_auto_ativar:
				exibir_proxima_fala()
			
			if Input.is_action_just_pressed("interagir") and dialogo_ativo:
				if esta_digitando:
					finalizar_digitacao_imediato()
				else:
					gerenciar_dialogo()
		else:
			if dialogo_ativo:
				encerrar_dialogo()
			pode_auto_ativar = true 

func gerenciar_dialogo():
	if indice_fala < falas_objeto.size():
		exibir_proxima_fala()
	else:
		encerrar_dialogo()
		pode_auto_ativar = false 
		
		# Inicia a sequência de teletransporte com efeito visual
		executar_teletransporte_com_fade()

func executar_teletransporte_com_fade():
	if not ui_transicao or not player:
		teleportar_player()
		return

	# 1. Torna o nó de transição visível e escurece a tela rapidamente
	ui_transicao.visible = true
	var tween = create_tween()
	
	# Interpola para totalmente escuro
	await tween.tween_property(ui_transicao, "modulate:a", 1.0, tempo_transicao).finished
	
	# 2. Teleporta o player enquanto a tela está 100% preta
	teleportar_player()
	
	# 3. Espera 1 segundo com a tela preta (atendendo ao pedido)
	await get_tree().create_timer(tempo_espera_escuro).timeout
	
	# 4. Clareia a tela novamente
	var tween_out = create_tween()
	await tween_out.tween_property(ui_transicao, "modulate:a", 0.0, tempo_transicao).finished
	
	# 5. Esconde o nó de transição (fica invisível/desativado)
	ui_transicao.visible = false

func teleportar_player():
	if player:
		var nova_posicao = Vector2(180, -88)
		
		if "velocity" in player:
			player.velocity = Vector2.ZERO
			
		player.global_position = nova_posicao
		player.start_position = nova_posicao
		print("Player teleportado para: ", nova_posicao)

func exibir_proxima_fala():
	dialogo_ativo = true
	ui_control.visible = true
	esta_digitando = true
	
	var texto_completo = falas_objeto[indice_fala]
	ui_texto.text = texto_completo
	ui_texto.visible_characters = 0
	
	indice_fala += 1
	
	for i in range(texto_completo.length() + 1):
		if not esta_digitando or not dialogo_ativo: break
		
		ui_texto.visible_characters = i
		
		if i > 0 and texto_completo[i-1] != " ":
			audio_player.pitch_scale = randf_range(0.9, 1.1)
			audio_player.play()
			
		await get_tree().create_timer(velocidade_digitacao).timeout
	
	esta_digitando = false

func finalizar_digitacao_imediato():
	esta_digitando = false 
	ui_texto.visible_characters = -1 

func encerrar_dialogo():
	ui_control.visible = false
	dialogo_ativo = false
	esta_digitando = false
	indice_fala = 0

func _player_esta_olhando() -> bool:
	if not player or not player.has_node("AnimatedSprite2D"): return false
	var direcao = (global_position - player.global_position).normalized()
	var anim = player.get_node("AnimatedSprite2D").animation
	if anim == "direita" and direcao.x > 0.4: return true
	if anim == "esquerda" and direcao.x < -0.4: return true
	if anim == "baixo" and direcao.y > 0.4: return true
	if anim == "cima" and direcao.y < -0.4: return true
	return false
