extends MarginContainer

# --- REFERENCIAS ---
@onready var titulo_label = $HBoxContainer/VBoxContainer/Name
@onready var categoria_label = $HBoxContainer/VBoxContainer/Category
@onready var foto = $HBoxContainer/TextureRect
@onready var descargador_img = $ImageRequest

func configurar_datos(titulo_texto, categoria_texto, cover_id):
	titulo_label.text = titulo_texto
	categoria_label.text = categoria_texto
	
	if cover_id != 0 and cover_id != null:
		var id_limpio = str(int(cover_id))
		var url_imagen = "https://covers.openlibrary.org/b/id/" + id_limpio + "-M.jpg"
		
		# Limpiamos conexiones viejas
		if descargador_img.request_completed.is_connected(_on_imagen_descargada):
			descargador_img.request_completed.disconnect(_on_imagen_descargada)
		
		descargador_img.request_completed.connect(_on_imagen_descargada)
		
		# --- LA SOLUCIÓN AL ERROR -9984 ---
		# Le decimos a Godot que sea permisivo con la seguridad (SSL) para esta descarga
		descargador_img.set_tls_options(TLSOptions.client_unsafe())
		
		descargador_img.request(url_imagen)

func _on_imagen_descargada(result, response_code, headers, body):
	# Si falló la descarga o no hay datos, adiós
	if result != HTTPRequest.RESULT_SUCCESS or body.size() < 100:
		return 

	var imagen = Image.new()
	var error = OK
	
	# Intentamos abrir con todas las llaves posibles
	if imagen.load_jpg_from_buffer(body) != OK:
		if imagen.load_png_from_buffer(body) != OK:
			if imagen.load_webp_from_buffer(body) != OK:
				return # Si nada funcionó, nos rendimos

	# Si llegamos aquí, ¡éxito!
	var textura = ImageTexture.create_from_image(imagen)
	foto.texture = textura
