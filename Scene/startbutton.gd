extends Button

# Nome da ação que você configurou no Input Map (ex: "interact")
const SCENE_PATH = "res://Scene/mundoaberto.tscn"

func _ready() -> void:
	# Conecta o clique do mouse
	pressed.connect(_on_pressed)

func _process(_delta: float) -> void:
	# Verifica se a tecla de interação foi pressionada
	if Input.is_action_just_pressed("interagir"):
		_change_scene()

func _on_pressed() -> void:
	_change_scene()

# Função única para evitar repetição de código
func _change_scene() -> void:
	get_tree().change_scene_to_file(SCENE_PATH)
