extends Control

# --- REFERENCIAS UI ---
@onready var titulo_label = $HBoxContainer/VBoxContainer/Name
@onready var categoria_label = $HBoxContainer/VBoxContainer/Category
@onready var imagen_rect = $HBoxContainer/TextureRect
@onready var stars_container = $HBoxContainer/VBoxContainer/StarContainer

# HTTP persistente (IMPORTANTE)
@onready var http := HTTPRequest.new()

# --- VARIABLES ---
var mi_puntuacion: float = 0.0
var mi_categoria: String = ""

func _ready():
	# Config visual
	imagen_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	imagen_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	imagen_rect.custom_minimum_size = Vector2(80, 120)
	
	# Añadimos HTTPRequest UNA sola vez
	add_child(http)
	http.request_completed.connect(_on_descarga)

func configurar_datos(titulo, categoria, rating, url_imagen):
	mi_categoria = categoria
	mi_puntuacion = float(rating)
	
	titulo_label.text = titulo
	categoria_label.text = categoria
	
	actualizar_estrellas(mi_puntuacion)
	
	# No borramos la textura (se mantiene la imagen por defecto del editor)
	
	if url_imagen != "" and url_imagen != null:
		await get_tree().create_timer(randf_range(0.05, 0.2)).timeout
		descargar_imagen(url_imagen)

func actualizar_estrellas(rating):
	var indice_estrella = 0
	
	for hijo in stars_container.get_children():
		if hijo is TextureProgressBar:
			hijo.max_value = 1.0
			
			if rating >= indice_estrella + 1:
				hijo.value = 1.0
			elif rating > indice_estrella:
				hijo.value = rating - indice_estrella
			else:
				hijo.value = 0.0
			
			indice_estrella += 1

# --- DESCARGA ESTABLE ---
func descargar_imagen(url):
	if not is_instance_valid(self):
		return
	
	# Cancelamos petición anterior si existe
	if http.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		http.cancel_request()
	
	var headers = [
		"User-Agent: Mozilla/5.0",
		"Accept: image/*"
	]
	
	var error = http.request(url, headers)
	if error != OK:
		print("Error al pedir imagen:", error)

func _on_descarga(result, response_code, headers, body):
	if not is_instance_valid(imagen_rect):
		return
	
	if response_code != 200:
		print("Fallo descarga imagen:", response_code)
		return
	
	var image = Image.new()
	var ok = false
	
	if image.load_jpg_from_buffer(body) == OK:
		ok = true
	elif image.load_png_from_buffer(body) == OK:
		ok = true
	elif image.load_webp_from_buffer(body) == OK:
		ok = true
	
	if ok:
		imagen_rect.texture = ImageTexture.create_from_image(image)
	else:
		print("Formato imagen no reconocido")
