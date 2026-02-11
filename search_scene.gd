extends Control

# --- REFERENCIAS ---
@onready var barra_busqueda = $PrincipalLayout/LineEdit
@onready var contenedor_lista = $PrincipalLayout/ScrollContainer/Results
@onready var api_libros = $BookAPI 

# Cargamos la escena de la ficha (Asegúrate de que la ruta sea correcta)
var escena_resultado = preload("res://Scenes/Search/Result_Scene.tscn")

func _ready():
	# Conectamos las señales
	barra_busqueda.text_submitted.connect(buscar_libros)
	api_libros.request_completed.connect(recibir_respuesta)

func buscar_libros(texto_usuario):
	if texto_usuario == "":
		return
	
	print("Buscando: " + texto_usuario)
	
	# 1. Limpiamos resultados anteriores
	for ficha in contenedor_lista.get_children():
		ficha.queue_free()
	
	# 2. Preparamos la URL
	var url = "https://openlibrary.org/search.json?q=" + texto_usuario.replace(" ", "+")
	
	# 3. Lanzamos la petición
	api_libros.request(url)

func recibir_respuesta(result, response_code, headers, body):
	if response_code != 200:
		print("Error en la API")
		return

	# Parseamos el JSON
	var json = JSON.parse_string(body.get_string_from_utf8())
	var lista_libros = json.get("docs", [])
	
	var contador = 0
	for libro in lista_libros:
		if contador >= 10: break
		
		# --- INSTANCIAR ---
		var nueva_ficha = escena_resultado.instantiate()
		
		# --- AÑADIR A PANTALLA PRIMERO (CRUCIAL PARA EVITAR ERRORES) ---
		contenedor_lista.add_child(nueva_ficha)
		
		# --- SACAR DATOS ---
		var titulo = libro.get("title", "Sin título")
		var autores = libro.get("author_name", ["Desconocido"])
		var autor = autores[0]
		
		# Sacamos el ID de la portada (si no hay, devuelve 0)
		var cover_id = libro.get("cover_i", 0)
		
		# --- CONFIGURAR LA FICHA ---
		nueva_ficha.configurar_datos(titulo, "Libro - " + autor, cover_id)
		
		contador += 1
