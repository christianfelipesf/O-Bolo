extends Control

@onready var barra_vida = $Vida
@onready var player = $"../../Player"

func _ready() -> void:
	# Aguarda um frame para garantir que os componentes do Player foram criados
	await get_tree().process_frame
	_configurar_interface()

func _process(_delta: float) -> void:
	if is_instance_valid(player):
		# ACESSO CORRETO: player.health_comp.current_health
		if player.health_comp:
			barra_vida.value = player.health_comp.current_health
	else:
		_tentar_reconectar_player()

func _configurar_interface() -> void:
	if is_instance_valid(player) and player.health_comp:
		barra_vida.max_value = player.health_comp.max_health
		barra_vida.value = player.health_comp.current_health
		print("[UI] Interface conectada ao HealthComponent.")

func _tentar_reconectar_player() -> void:
	var novo_player = get_tree().root.find_child("Player", true, false)
	if novo_player:
		player = novo_player
		_configurar_interface()
