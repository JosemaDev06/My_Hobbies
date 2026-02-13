extends Control

@onready var barra_busqueda = $PrincipalLayout/MarginContainer/LineEdit
@onready var contenedor_lista = $PrincipalLayout/ScrollContainer/Results
@onready var api_libros = $BookAPI 

# --- TUS CLAVES ---
const RAWG_API_KEY = "487b58cad7314b2db55c0663cc2c1fae"
const TMDB_API_KEY = "100600e63dc80d40e405ff5e2307d15c"

const MAX_RESULTADOS = 5 

# --- VARIABLES DE GESTIÓN ---
var resultados_combinados = []
var apis_pendientes = 0
var texto_buscado_actual = ""

# Headers
var headers_chrome = ["User-Agent: Mozilla/5.0", "Accept: application/json"]

# Conectores
var api_juegos = HTTPRequest.new()
var api_series = HTTPRequest.new()
var api_pelis = HTTPRequest.new()
var escena_resultado = preload("res://Scenes/Search/Result_Scene.tscn")

func _ready():
	add_child(api_juegos)
	add_child(api_series)
	add_child(api_pelis)
	
	barra_busqueda.text_submitted.connect(iniciar_busqueda)
	
	api_libros.request_completed.connect(recopilar_libros)
	api_juegos.request_completed.connect(recopilar_juegos)
	api_series.request_completed.connect(recopilar_series)
	api_pelis.request_completed.connect(recopilar_pelis)

func iniciar_busqueda(texto_usuario):
	if texto_usuario == "": return
	
	resultados_combinados = []
	texto_buscado_actual = texto_usuario.to_lower() 
	
	for ficha in contenedor_lista.get_children():
		ficha.queue_free()
	
	var texto_url = texto_usuario.replace(" ", "+")
	
	api_libros.cancel_request()
	api_juegos.cancel_request()
	api_series.cancel_request()
	api_pelis.cancel_request()
	
	apis_pendientes = 4
	
	# 1. Libros
	api_libros.request("http://openlibrary.org/search.json?q=" + texto_url)
	
	# 2. Juegos
	var url_juegos = "https://api.rawg.io/api/games?key=" + RAWG_API_KEY + "&search=" + texto_url + "&page_size=" + str(MAX_RESULTADOS)
	api_juegos.request(url_juegos, headers_chrome)
	
	# 3. Series
	var url_series = "https://api.tvmaze.com/search/shows?q=" + texto_url
	api_series.request(url_series)
	
	# 4. Películas
	if not TMDB_API_KEY.begins_with("PON_AQUI"):
		var url_pelis = "https://api.themoviedb.org/3/search/movie?api_key=" + TMDB_API_KEY + "&query=" + texto_url + "&language=es-ES"
		api_pelis.request(url_pelis)
	else:
		apis_pendientes -= 1

# --- RECOPILADORES CON RATING ---

func recopilar_libros(result, code, headers, body):
	if code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json:
			var lista = json.get("docs", [])
			var count = 0
			for item in lista:
				if count >= MAX_RESULTADOS: break
				var titulo = item.get("title", "Sin título")
				var autor = item.get("author_name", ["Desconocido"])[0]
				
				# Rating de libros (A veces no viene, ponemos 0 por defecto)
				var rating = item.get("ratings_average", 0)
				if rating == null: rating = 0
				
				var cover_id = item.get("cover_i", 0)
				var img = ""
				if cover_id != 0: img = "http://covers.openlibrary.org/b/id/" + str(int(cover_id)) + "-M.jpg"
				
				# Pasamos el rating redondeado a entero
				agregar_resultado(titulo, "Libro - " + autor, float(rating), img)
				count += 1
	chequear_fin_peticion()

func recopilar_juegos(result, code, headers, body):
	if code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json:
			var lista = json.get("results", [])
			for item in lista:
				var titulo = item.get("name", "Juego")
				
				# Rating de Juegos (Viene sobre 5, perfecto)
				var rating = item.get("rating", 0)
				
				var img = item.get("background_image", "")
				if img == null: img = ""
				
				agregar_resultado(titulo, "Videojuego", float(rating), img)
	chequear_fin_peticion()

func recopilar_series(result, code, headers, body):
	if code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json:
			var count = 0
			for item in json:
				if count >= MAX_RESULTADOS: break
				var show = item.get("show", {})
				var titulo = show.get("name", "Serie TV")
				
				# Rating de Series (Viene sobre 10, dividimos entre 2)
				var rating_obj = show.get("rating", {})
				var score = rating_obj.get("average", 0)
				if score == null: score = 0
				var rating_final = score / 2
				
				var imagenes = show.get("image")
				var img = ""
				if imagenes != null and typeof(imagenes) == TYPE_DICTIONARY:
					img = imagenes.get("medium", "")
					
				agregar_resultado(titulo, "Serie TV", float(rating_final), img)
				count += 1
	chequear_fin_peticion()

func recopilar_pelis(result, code, headers, body):
	if code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json:
			var lista = json.get("results", [])
			var count = 0
			for item in lista:
				if count >= MAX_RESULTADOS: break
				var titulo = item.get("title", "Película")
				var fecha = item.get("release_date", "")
				if fecha.length() >= 4: titulo += " (" + fecha.substr(0,4) + ")"
				
				# Rating de Pelis (Viene sobre 10, dividimos entre 2)
				var score = item.get("vote_average", 0)
				var rating_final = score / 2
				
				var poster = item.get("poster_path")
				var img = ""
				if poster != null: img = "https://image.tmdb.org/t/p/w500" + poster
				
				agregar_resultado(titulo, "Película", float(rating_final), img)
				count += 1
	chequear_fin_peticion()

# --- LÓGICA CENTRAL ---

# HEMOS AÑADIDO 'rating' AQUI
func agregar_resultado(titulo, categoria, rating, imagen):
	resultados_combinados.append({
		"titulo": titulo,
		"categoria": categoria,
		"rating": rating, # Guardamos la nota
		"imagen": imagen
	})

func chequear_fin_peticion():
	apis_pendientes -= 1
	
	if apis_pendientes <= 0:
		mostrar_resultados_ordenados()

func mostrar_resultados_ordenados():
	resultados_combinados.sort_custom(ordenar_por_similitud)
	
	for dato in resultados_combinados:
		# Pasamos los 4 datos a la función de crear
		crear_ficha(dato["titulo"], dato["categoria"], dato["rating"], dato["imagen"])

func ordenar_por_similitud(a, b):
	var sim_a = a["titulo"].to_lower().similarity(texto_buscado_actual)
	var sim_b = b["titulo"].to_lower().similarity(texto_buscado_actual)
	
	if a["titulo"].to_lower().begins_with(texto_buscado_actual): sim_a += 0.5
	if b["titulo"].to_lower().begins_with(texto_buscado_actual): sim_b += 0.5
	
	return sim_a > sim_b

# HEMOS AÑADIDO 'rating' AQUI TAMBIEN
func crear_ficha(titulo, categoria, rating, url_imagen):
	var nueva_ficha = escena_resultado.instantiate()
	contenedor_lista.add_child(nueva_ficha)
	# Y AQUI ES DONDE DABA EL ERROR ANTES:
	nueva_ficha.configurar_datos(titulo, categoria, rating, url_imagen)
