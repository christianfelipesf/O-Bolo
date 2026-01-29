extends Control

@onready var http_request = $HTTPRequest
@onready var label = $RichTextLabel

func _ready():
	# Substitua pela sua URL raw
	var url = "https://raw.githubusercontent.com/christianfelipesf/O-Bolo/refs/heads/main/README.md"
	http_request.request(url)

func _on_http_request_request_completed(result, response_code, headers, body):
	if response_code == 200:
		# Transforma os bytes do corpo da resposta em texto
		var readme_text = body.get_string_from_utf8()
		label.text = readme_text
	else:
		label.text = "Erro ao carregar README. Código: " + str(response_code)
