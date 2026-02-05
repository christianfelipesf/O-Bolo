extends Area2D

# --- Configurações de Diálogo ---
@export_group("Diálogos")
@export var auto_start: bool = false # Opção para começar sozinho ao chegar perto
@export_multiline var falas_objeto: Array[String] = [
	"Isso parece ser um baú antigo.",
	"Está trancado, mas há um cheiro de bolo vindo de dentro...",
	"Melhor procurar uma chave."
]

var indice_fala: int = 0
var dialogo_ativo: bool = false
var esta_digitando: bool = false
var ja_rodou_auto: bool = false # Para evitar loop no auto_start
var is_teleporting: bool = false # Trava de segurança para o teletransporte
var player_dentro: bool = false # NOVO: rastreia se o player está na área

# --- Configurações Visuais/Teleporte ---
@export var velocidade_digitacao: float = 0.05 
@export var tempo_transicao: float = 0.5 
@export var tempo_espera_escuro: float = 1.0 

@onready var audio_player = $audio # Certifique-se que existe um AudioStreamPlayer como filho

# Referências da UI
@onready var ui_canvas = get_tree().root.find_child("CanvasLayer", true, false)
@onready var ui_control = ui_canvas.get_node("Control")
@onready var ui_texto = ui_canvas.get_node("Control/Panel/RichTextLabel")
@onready var ui_transicao = ui_canvas.get_node("Transicao")

func _ready() -> void:
	if ui_transicao:
		ui_transicao.modulate.a = 0
		ui_transicao.visible = false
	
	# Conecta os sinais para o funcionamento do auto_start e fechamento automático
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	# Se estiver a teleportar, ignora qualquer nova entrada
	if is_teleporting: return
	
	if body.is_in_group("player"):
		player_dentro = true
		
		# CORREÇÃO: Inicia o diálogo automaticamente se auto_start estiver ativo
		if auto_start and not ja_rodou_auto and not dialogo_ativo:
			ja_rodou_auto = true
			# Aguarda um frame para garantir que tudo está pronto
			await get_tree().process_frame
			interact()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_dentro = false
		# Se o player sair da área, forçamos o encerramento do diálogo
		encerrar_dialogo_completo()
		# Só reseta o auto_start se não estivermos no meio de um teletransporte
		if not is_teleporting:
			ja_rodou_auto = false

# O PLAYER CHAMA ESTA FUNÇÃO OU O AUTO_START
func interact():
	if is_teleporting: return # Bloqueia interação se estiver a teleportar
	
	if esta_digitando:
		finalizar_digitacao_imediato()
		return
		
	if not dialogo_ativo:
		iniciar_dialogo()
	else:
		gerenciar_dialogo()

func iniciar_dialogo():
	dialogo_ativo = true
	indice_fala = 0
	ui_control.visible = true
	exibir_proxima_fala()

func gerenciar_dialogo():
	if indice_fala < falas_objeto.size():
		exibir_proxima_fala()
	else:
		encerrar_dialogo()
		executar_teletransporte_com_fade()

func exibir_proxima_fala():
	esta_digitando = true
	var texto_completo = falas_objeto[indice_fala]
	ui_texto.text = texto_completo
	ui_texto.visible_characters = 0
	indice_fala += 1
	
	for i in range(texto_completo.length() + 1):
		# Verifica se o diálogo ainda está ativo ou se o teletransporte começou
		if not esta_digitando or not dialogo_ativo or is_teleporting: 
			ui_texto.visible_characters = 0
			return
			
		ui_texto.visible_characters = i
		if i > 0 and texto_completo[i-1] != " " and audio_player:
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

# Função reforçada para garantir que tudo pare ao sair da área
func encerrar_dialogo_completo():
	dialogo_ativo = false
	esta_digitando = false
	ui_control.visible = false
	ui_texto.text = ""
	indice_fala = 0

func executar_teletransporte_com_fade():
	if not ui_transicao or is_teleporting: return
	
	is_teleporting = true # Ativa a trava de segurança
	ja_rodou_auto = true 

	ui_transicao.visible = true
	var tween = create_tween()
	await tween.tween_property(ui_transicao, "modulate:a", 1.0, tempo_transicao).finished
	
	# Garante que o diálogo esteja fechado durante o teletransporte
	encerrar_dialogo_completo()
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var nova_posicao = Vector2(180, -88)
		player.global_position = nova_posicao
		if "start_position" in player:
			player.start_position = nova_posicao
	
	await get_tree().create_timer(tempo_espera_escuro).timeout
	
	var tween_out = create_tween()
	await tween_out.tween_property(ui_transicao, "modulate:a", 0.0, tempo_transicao).finished
	ui_transicao.visible = false
	
	# Pequeno atraso antes de permitir novas interações para o motor de física estabilizar
	await get_tree().create_timer(0.2).timeout
	is_teleporting = false
