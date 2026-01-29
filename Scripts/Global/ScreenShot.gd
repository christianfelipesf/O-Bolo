extends Node

# Este script deve ser configurado no Project Settings -> Autoload

func _input(event: InputEvent) -> void:
	# Verifica se apertou o botão configurado como "foto"
	if event.is_action_pressed("foto"):
		take_screenshot()

func take_screenshot():
	# ESSENCIAL: Espera o motor terminar de desenhar o frame atual
	await RenderingServer.frame_post_draw
	
	# Captura o conteúdo da tela atual
	var v_screenshot = get_viewport().get_texture().get_image()
	
	var time = Time.get_datetime_dict_from_system()
	var filename = "user://screenshot_%d%02d%02d_%02d%02d%02d.png" % [
		time.year, time.month, time.day, 
		time.hour, time.minute, time.second
	]
	
	v_screenshot.save_png(filename)
	print("Screenshot salva em: ", OS.get_user_data_dir())
