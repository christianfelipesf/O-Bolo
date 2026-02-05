extends Node

# --- CONFIGURAÇÕES ---
# Certifique-se de que "foto" está definido no Input Map (Project Settings).

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("foto"):
		take_screenshot()

func take_screenshot():
	# 1. CAPTURA A IMAGEM PRIMEIRO
	# Esperamos o final do desenho do frame atual para pegar a imagem limpa
	await RenderingServer.frame_post_draw
	var v_screenshot = get_viewport().get_texture().get_image()
	
	# 2. DISPARA O EFEITO VISUAL DEPOIS DA CAPTURA
	# Como a captura já está na variável v_screenshot, o flash não aparecerá nela
	create_flash_effect()
	
	# Gerar nome do arquivo baseado no tempo
	var time = Time.get_datetime_dict_from_system()
	var file_name = "screenshot_%d%02d%02d_%02d%02d%02d.png" % [
		time.year, time.month, time.day, 
		time.hour, time.minute, time.second
	]

	# 3. TRATAMENTO POR PLATAFORMA
	if OS.has_feature("web"):
		# No Navegador: Converte para buffer e força o download via JavaScript
		var buffer = v_screenshot.save_png_to_buffer()
		JavaScriptBridge.download_buffer(buffer, file_name)
		print("Web: Download iniciado.")
	else:
		# No PC/Desktop: Salva na pasta de usuário (AppData/Roaming no Windows)
		var dir_path = "user://screenshots/"
		
		if not DirAccess.dir_exists_absolute(dir_path):
			DirAccess.make_dir_absolute(dir_path)
			
		var full_path = dir_path + file_name
		var err = v_screenshot.save_png(full_path)
		
		if err == OK:
			print("Desktop: Salvo em " + ProjectSettings.globalize_path(full_path))
		else:
			push_error("Erro ao salvar imagem: ", err)

func create_flash_effect():
	# Criar estrutura de nós para o flash
	var canvas = CanvasLayer.new()
	canvas.layer = 128 # Valor alto para garantir que fique acima de tudo
	
	var rect = ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.color = Color(1, 1, 1, 1) # Branco total
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	add_child(canvas)
	canvas.add_child(rect)
	
	# Animação: Esmaecer o branco (alpha de 1 para 0)
	var tween = get_tree().create_tween()
	tween.tween_property(rect, "color:a", 0.0, 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	
	# Limpar os nós da memória após o efeito
	tween.tween_callback(canvas.queue_free)
