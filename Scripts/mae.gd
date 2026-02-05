extends CharacterBody2D

# --- Diálogos ---
@export_group("Diálogos")
@export_multiline var falas_do_npc: Array[String] = [
	"Olá!", 
	"Precisa de ajuda?", 
	"Tem bolo em cima da mesa, come um pouco."
]

var indice_fala: int = 0
var dialogo_ativo: bool = false 
var esta_digitando: bool = false
var player_dentro: bool = false # NOVO: rastreia se o player está na área

# --- Configurações de Texto e Áudio ---
@export var velocidade_digitacao: float = 0.05
@onready var audio_player = $audio
@onready var area_interacao = $Area2D # Referência ao Area2D filho

# Referências da UI
@onready var player = get_tree().get_first_node_in_group("player")
@onready var ui_canvas = get_tree().root.find_child("CanvasLayer", true, false)
@onready var ui_control = ui_canvas.get_node("Control")
@onready var ui_texto = ui_canvas.get_node("Control/Panel/RichTextLabel")
@onready var sprite = $Sprite2D # Referência ao sprite filho

func _ready() -> void:
	# Conecta os sinais do Area2D
	if area_interacao:
		area_interacao.body_entered.connect(_on_body_entered)
		area_interacao.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_dentro = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_dentro = false
		# Força encerramento do diálogo quando player sai da área
		encerrar_dialogo_completo()

func _process(_delta: float) -> void:
	if player and player_dentro:
		var olhando = _player_esta_olhando()
		
		# Feedback visual (Shader Outline) no Sprite2D
		if sprite and sprite.material and olhando:
			sprite.material.set_shader_parameter("line_thickness", 1.5)
		elif sprite and sprite.material:
			sprite.material.set_shader_parameter("line_thickness", 0.0)
			
			if dialogo_ativo and not olhando:
				encerrar_dialogo()
		
		# INTERAÇÃO
		if Input.is_action_just_pressed("interagir") and olhando:
			if esta_digitando:
				finalizar_digitacao_imediato()
			else:
				gerenciar_dialogo()
	else:
		# Remove outline quando player não está na área
		if sprite and sprite.material:
			sprite.material.set_shader_parameter("line_thickness", 0.0)

func gerenciar_dialogo():
	if indice_fala < falas_do_npc.size():
		exibir_proxima_fala()
	else:
		encerrar_dialogo()

func exibir_proxima_fala():
	dialogo_ativo = true
	ui_control.visible = true
	esta_digitando = true
	
	var texto_completo = falas_do_npc[indice_fala]
	ui_texto.text = texto_completo
	ui_texto.visible_characters = 0
	
	indice_fala += 1
	
	# Loop de digitação com áudio
	for i in range(texto_completo.length() + 1):
		if not esta_digitando or not dialogo_ativo or not player_dentro: 
			ui_texto.visible_characters = 0
			return
		
		ui_texto.visible_characters = i
		
		# Toca o áudio se não for espaço
		if i > 0 and texto_completo[i-1] != " ":
			if audio_player:
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

# Função reforçada para garantir que tudo pare ao sair da área
func encerrar_dialogo_completo():
	dialogo_ativo = false
	esta_digitando = false
	ui_control.visible = false
	ui_texto.text = ""
	indice_fala = 0

func _player_esta_olhando() -> bool:
	if not player or not player.has_node("AnimatedSprite2D"): 
		return false
	
	var direcao = (global_position - player.global_position).normalized()
	var anim = player.get_node("AnimatedSprite2D").animation
	
	if anim == "direita" and direcao.x > 0.4: return true
	if anim == "esquerda" and direcao.x < -0.4: return true
	if anim == "baixo" and direcao.y > 0.4: return true
	if anim == "cima" and direcao.y < -0.4: return true
	
	return false
