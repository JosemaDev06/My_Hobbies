extends Control

# --- REFERENCIAS UI ---
@onready var titulo_label = $HBoxContainer/VBoxContainer/Name
@onready var categoria_label = $HBoxContainer/VBoxContainer/Category
@onready var imagen_rect = $HBoxContainer/TextureRect

# Contenedor de las estrellas
@onready var stars_container = $HBoxContainer/VBoxContainer/StarContainer

# Referencia al nuevo Label numérico (Asegúrate de crearlo en la escena dentro de StarContainer)
# Si lo has puesto fuera, ajusta esta ruta.
@onready var rating_number_label = $HBoxContainer/VBoxContainer/StarContainer/RatingNumber 

# --- VARIABLES PARA EL FILTRO ---
var mi_puntuacion: float = 0.0
var mi_categoria: String = ""

func configurar_datos(titulo, categoria, rating, url_imagen):
	# 1. Guardamos datos (Forzamos float para decimales)
	mi_categoria = categoria
	mi_puntuacion = float(rating)
	
	# 2. Actualizamos textos
	titulo_label.text = titulo
	categoria_label.text = categoria
	
	# 3. Pintamos las estrellas (Lógica nueva)
	actualizar_estrellas(mi_puntuacion)
	
	# 4. Lógica de imagen
	if url_imagen != "":
		var url_insegura = url_imagen.replace("https://", "http://")
		descargar_imagen(url_insegura)
	else:
		print("Sin imagen URL provista")

func actualizar_estrellas(rating):
	print("RECIBIDO Rating: ", rating, " | TIPO: ", typeof(rating))  # <--- AÑADE ESTO
	# A) Actualizamos el número de texto (ej: "4.5")
	# "%.1f" significa "Formatea el float con solo 1 decimal"
	if rating_number_label:
		rating_number_label.text = "%.1f" % rating
	
	# B) Actualizamos las barras de las estrellas
	var hijos = stars_container.get_children()
	
	# Creamos un índice aparte para las estrellas, ignorando el Label si está dentro
	var indice_estrella = 0
	
	for hijo in hijos:
		# Solo actuamos si el hijo es una Barra de Progreso (la estrella)
		if hijo is TextureProgressBar:
			var barra = hijo
			
			# Lógica matemática:
			# Si rating es 3.7:
			# Estrella 0 (valor 1) -> rating > 1 -> LLENA (1.0)
			# Estrella 1 (valor 2) -> rating > 2 -> LLENA (1.0)
			# Estrella 2 (valor 3) -> rating > 3 -> LLENA (1.0)
			# Estrella 3 (valor 4) -> rating no > 4, pero > 3 -> PARCIAL (3.7 - 3 = 0.7)
			
			if rating >= indice_estrella + 1:
				barra.value = 1.0 # Llena al 100%
			elif rating > indice_estrella:
				barra.value = rating - indice_estrella # Parte decimal
			else:
				barra.value = 0.0 # Vacía
			
			indice_estrella += 1

# --- TU LÓGICA DE DESCARGA ORIGINAL (INTACTA) ---

func descargar_imagen(url):
	var http = HTTPRequest.new()
	add_child(http)
	
	http.set_tls_options(TLSOptions.client_unsafe())
	http.request_completed.connect(_on_descarga.bind(http))
	
	var headers = ["User-Agent: GodotEngine"]
	var error = http.request(url, headers)
	if error != OK:
		print("Error al pedir foto: ", error)
		http.queue_free()

func _on_descarga(result, response_code, headers, body, http):
	if response_code != 200:
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
	else:
		print("Formato de imagen no reconocido.")
	
	http.queue_free()
