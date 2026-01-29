extends Node2D

# --- Configurações de Diálogo ---
@export_group("Configurações")
@export_multiline var falas: Array[String] = [
	"Acorde, viajante...",
	"O mundo lá fora mudou muito desde a sua partida.",
	"Vá para a cidade e encontre o ancião."
]

var indice_fala: int = 0

# --- Referências da UI ---
@onready var ui_control = $CanvasLayer/Control
@onready var ui_texto = $CanvasLayer/Control/Panel/RichTextLabel
@onready var botao_avancar = $CanvasLayer/Control/AVANCAR

func _ready() -> void:
	# Conecta o botão de avançar
	botao_avancar.pressed.connect(_on_botao_avancar_pressed)
	
	# Inicia o sistema
	iniciar_dialogo()

func iniciar_dialogo():
	indice_fala = 0
	ui_control.visible = true
	exibir_proxima_fala()

func exibir_proxima_fala():
	# Verifica se ainda existem falas no Array
	if indice_fala < falas.size():
		ui_texto.text = falas[indice_fala]
		
		# Efeito de digitar
		ui_texto.visible_ratio = 0.0
		var t = create_tween()
		t.tween_property(ui_texto, "visible_ratio", 1.0, 0.5)
		
		indice_fala += 1
	else:
		# Quando as falas acabam, muda para o mundo aberto
		ir_para_mundo_aberto()

func _on_botao_avancar_pressed():
	exibir_proxima_fala()

func ir_para_mundo_aberto():
	# Esconde a UI antes de mudar para não bugar visualmente
	ui_control.visible = false
	# Muda para a cena do mundo aberto
	get_tree().change_scene_to_file("res://Scene/mundoaberto.tscn")
