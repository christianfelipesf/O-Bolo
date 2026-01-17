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

# --- Configurações de Interação ---
@export var interacao_distancia: float = 30.0
@onready var player = get_tree().get_first_node_in_group("player")
@onready var attach_node = $Attach

# Referências da UI
@onready var ui_canvas = get_tree().root.find_child("CanvasLayer", true, false)
@onready var ui_texto = ui_canvas.get_node("Control/Panel/RichTextLabel")

func _process(_delta: float) -> void:
	if player and attach_node:
		var distancia = attach_node.global_position.distance_to(player.global_position)
		var olhando = _player_esta_olhando()
		
		# Lógica do Contorno (Shader)
		if distancia <= interacao_distancia and olhando:
			material.set_shader_parameter("line_thickness", 1.5)
			
			# BOTÃO DE INTERAÇÃO (F)
			if Input.is_action_just_pressed("interagir"):
				gerenciar_dialogo()
		else:
			material.set_shader_parameter("line_thickness", 0.0)
			
			# Fecha se o player se afastar enquanto lê
			if dialogo_ativo:
				encerrar_dialogo()

func gerenciar_dialogo():
	if indice_fala < falas_objeto.size():
		exibir_proxima_fala()
	else:
		encerrar_dialogo()

func exibir_proxima_fala():
	dialogo_ativo = true
	ui_canvas.visible = true
	ui_texto.text = falas_objeto[indice_fala]
	
	# Efeito de digitar
	ui_texto.visible_ratio = 0.0
	var t = create_tween()
	t.tween_property(ui_texto, "visible_ratio", 1.0, 0.4)
	
	# Efeito de flash no Sprite2D (Pai)
	var tw_flash = create_tween()
	tw_flash.tween_property(material, "shader_parameter/flash_modifier", 1.0, 0.1)
	tw_flash.tween_property(material, "shader_parameter/flash_modifier", 0.0, 0.1)
	
	indice_fala += 1

func encerrar_dialogo():
	# Proteção para não fechar diálogo de outro NPC/Objeto
	if ui_texto.text in falas_objeto:
		ui_canvas.visible = false
		dialogo_ativo = false
		indice_fala = 0

func _player_esta_olhando() -> bool:
	var direcao_para_attach = (attach_node.global_position - player.global_position).normalized()
	var anim_player = player.get_node("AnimatedSprite2D").animation
	
	if anim_player == "direita" and direcao_para_attach.x > 0.4: return true
	if anim_player == "esquerda" and direcao_para_attach.x < -0.4: return true
	if anim_player == "baixo" and direcao_para_attach.y > 0.4: return true
	if anim_player == "cima" and direcao_para_attach.y < -0.4: return true
	
	return false
