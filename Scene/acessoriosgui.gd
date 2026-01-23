extends Control

@onready var barra_vida = $Vida
@onready var player = $"../../Player"

# Variável de controle para não repetir logs no _process
var _player_was_valid := true 

func _ready() -> void:
	print("[UI] Sistema de Interface iniciado.")
	if is_instance_valid(player):
		print("[UI] Player detectado no início. Vida: ", player.current_health)
		if barra_vida:
			barra_vida.max_value = player.max_health
			barra_vida.value = player.current_health
	else:
		push_warning("[UI] Player não encontrado no carregamento inicial.")

func _process(_delta: float) -> void:
	if not barra_vida:
		# push_error aparece em vermelho no Debugger
		push_error("[UI] ERRO CRÍTICO: Nó '$Vida' é nulo. Verifique a hierarquia!")
		set_process(false) # Desativa o script para poupar processamento
		return 

	if is_instance_valid(player):
		barra_vida.value = player.current_health
		
		# Log apenas quando o player volta a existir
		if not _player_was_valid:
			print("[UI] Conexão restabelecida com o Player.")
			_player_was_valid = true
	else:
		# Log apenas na primeira vez que o player sumir
		if _player_was_valid:
			print("[UI] Player perdido (null). Definindo vida visual como 0.")
			barra_vida.value = 0
			_player_was_valid = false
		
		# Tenta recuperar a referência
		_tentar_reconectar_player()

func _tentar_reconectar_player() -> void:
	var novo_player = get_tree().root.find_child("Player", true, false)
	if novo_player:
		player = novo_player
		barra_vida.max_value = player.max_health
		print("[UI] Novo Player localizado via busca dinâmica. Max Health: ", player.max_health)
