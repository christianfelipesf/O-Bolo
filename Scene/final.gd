extends MeshInstance3D

# Variáveis para ajustar o movimento no Inspetor
@export var amplitude: float = 0.1  # A altura máxima que ele sobe/desce
@export var velocidade: float = 1.0   # A rapidez do movimento
@export var rotacionar: bool = false  # Se ele deve girar enquanto flutua
@export var vel_rotacao: float = 1.0  # Velocidade da rotação

var posicao_inicial: Vector3
var tempo: float = 0.0

func _ready():
	# Guarda a posição onde você colocou o objeto no editor
	posicao_inicial = position

func _process(delta):
	tempo += delta
	
	# Cálculo da flutuação usando SENO
	# A fórmula básica é: posição_original + sin(tempo * velocidade) * amplitude
	var nova_altura = sin(tempo * velocidade) * amplitude
	position.y = posicao_inicial.y + nova_altura
	
	# Opcional: Adiciona uma rotação para dar mais vida ao objeto
	if rotacionar:
		rotate_y(vel_rotacao * delta)
