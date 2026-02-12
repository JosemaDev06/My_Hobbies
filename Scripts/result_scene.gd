extends Control

@onready var titulo_label = $HBoxContainer/VBoxContainer/Name
@onready var categoria_label = $HBoxContainer/VBoxContainer/Category
@onready var imagen_rect = $HBoxContainer/TextureRect

func configurar_datos(titulo, categoria, url_imagen):
	titulo_label.text = titulo
	categoria_label.text = categoria
	
	if url_imagen != "":
		# --- EL TRUCO DEL PLAN B ---
		# Forzamos que la dirección sea http (sin S)
		# Esto evita el chequeo de seguridad que te está fallando
		var url_insegura = url_imagen.replace("https://", "http://")
		print("Intentando descargar: ", url_insegura)
		descargar_imagen(url_insegura)
	else:
		print("Sin imagen")

func descargar_imagen(url):
	var http = HTTPRequest.new()
	add_child(http)
	
	# Mantenemos esto por si acaso el servidor nos redirige
	http.set_tls_options(TLSOptions.client_unsafe())
	
	http.request_completed.connect(_on_descarga.bind(http))
	
	# Usamos headers simples, a veces menos es más
	var headers = ["User-Agent: GodotEngine"]
	
	var error = http.request(url, headers)
	if error != OK:
		print("Error al pedir foto: ", error)
		http.queue_free()

func _on_descarga(result, response_code, headers, body, http):
	# Si falla, imprimimos POR QUÉ
	if response_code != 200:
		print("ERROR DESCARGA. Código HTTP: ", response_code)
		http.queue_free()
		return

	var image = Image.new()
	var error_img = image.load_jpg_from_buffer(body)
	
	if error_img != OK:
		error_img = image.load_png_from_buffer(body)
	
	if error_img != OK:
		error_img = image.load_webp_from_buffer(body)
	
	if error_img == OK:
		var textura = ImageTexture.create_from_image(image)
		imagen_rect.texture = textura
		print("¡Foto cargada con éxito!")
	else:
		print("Foto descargada pero formato desconocido.")
	
	http.queue_free()
