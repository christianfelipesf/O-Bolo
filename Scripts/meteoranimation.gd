extends Node2D

# --- Configurações de Diálogo ---
@export_group("Configurações")
@export_multiline var falas: Array[String] = [
	"Acorde, viajante...",
	"O mundo lá fora mudou muito desde a sua partida.",
	"Vá para a cidade e encontre o ancião."
]

var indice_fala: int = 0
var esta_digitando: bool = false # Nova trava de segurança

# --- Referências da UI ---
@onready var ui_control = $CanvasLayer/Control
@onready var ui_texto = $CanvasLayer/Control/Panel/RichTextLabel

func _ready() -> void:
	# Inicia o sistema
	iniciar_dialogo()

# Detecta a tecla de interação
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interagir") and ui_control.visible:
		exibir_proxima_fala()

func iniciar_dialogo():
	indice_fala = 0
	ui_control.visible = true
	exibir_proxima_fala()

func exibir_proxima_fala():
	# Se ainda estiver animando o texto, podemos pular a animação (opcional)
	if esta_digitando:
		return 

	if indice_fala < falas.size():
		ui_texto.text = falas[indice_fala]
		
		# Efeito de digitar com trava de segurança
		esta_digitando = true
		ui_texto.visible_ratio = 0.0
		var t = create_tween()
		t.tween_property(ui_texto, "visible_ratio", 1.0, 0.5)
		t.finished.connect(func(): esta_digitando = false)
		
		indice_fala += 1
	else:
		ir_para_mundo_aberto()

func ir_para_mundo_aberto():
	ui_control.visible = false
	get_tree().change_scene_to_file("res://Scene/mundoaberto.tscn")
