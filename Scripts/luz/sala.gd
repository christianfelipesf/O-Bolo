extends PointLight2D

@export var velocidade: float = 4.0      # Velocidade da mudança orgânica
@export var intensidade_base: float = 0.8 # Brilho médio da luz
@export var amplitude: float = 0.2       # O "tamanho" da variação (0.2 = 20% para mais ou menos)

var noise = FastNoiseLite.new()
var tempo: float = 0.0

func _ready() -> void:
	# Configura o gerador de ruído para ser suave
	noise.seed = randi() # Semente aleatória para cada luz ser diferente
	noise.frequency = 0.5 

func _process(delta: float) -> void:
	tempo += delta * velocidade
	
	# O noise.get_noise_1d retorna um valor entre -1 e 1 de forma suave
	var variacao_organica = noise.get_noise_1d(tempo)
	
	# Aplica o valor à energia da luz
	energy = intensidade_base + (variacao_organica * amplitude)
