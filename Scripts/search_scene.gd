extends Control

# --- REFERENCIAS UI ---
@onready var barra_busqueda = $PrincipalLayout/HBoxContainer/MarginContainer/LineEdit
@onready var btn_filtros = $PrincipalLayout/HBoxContainer/Button
@onready var contenedor_lista = $PrincipalLayout/ScrollContainer/Results

@onready var filter_panel = $FilterPanel
@onready var rating_label = $FilterPanel/VBoxContainer/Label2
@onready var rating_slider = $FilterPanel/VBoxContainer/HSlider

@onready var chk_game = $FilterPanel/VBoxContainer/HBoxContainer/CheckGames
@onready var chk_book = $FilterPanel/VBoxContainer/HBoxContainer/CheckBooks
@onready var chk_serie = $FilterPanel/VBoxContainer/HBoxContainer2/CheckSeries
@onready var chk_movie = $FilterPanel/VBoxContainer/HBoxContainer2/CheckMovies

@onready var api_libros = $BookAPI 

const RAWG_API_KEY = "487b58cad7314b2db55c0663cc2c1fae"
const TMDB_API_KEY = "100600e63dc80d40e405ff5e2307d15c"
const MAX_RESULTADOS = 5 

var resultados_combinados = []
var apis_pendientes = 0
var texto_buscado_actual = ""

var headers_chrome = ["User-Agent: Mozilla/5.0", "Accept: application/json"]

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
	
	btn_filtros.toggled.connect(func(p): filter_panel.visible = p)
	filter_panel.visible = false
	
	chk_game.button_pressed = true
	chk_book.button_pressed = true
	chk_serie.button_pressed = true
	chk_movie.button_pressed = true
	
	chk_game.toggled.connect(aplicar_filtros.unbind(1))
	chk_book.toggled.connect(aplicar_filtros.unbind(1))
	chk_serie.toggled.connect(aplicar_filtros.unbind(1))
	chk_movie.toggled.connect(aplicar_filtros.unbind(1))
	rating_slider.value_changed.connect(_on_slider_changed)

func _on_slider_changed(valor):
	rating_label.text = "Nota mínima: " + str(valor)
	aplicar_filtros()

func aplicar_filtros():
	mostrar_resultados_ordenados()

# --- BÚSQUEDA ---
func iniciar_busqueda(texto_usuario):
	if texto_usuario == "":
		return
	
	resultados_combinados.clear()
	texto_buscado_actual = texto_usuario.to_lower()
	
	for ficha in contenedor_lista.get_children():
		ficha.queue_free()
	
	var texto_url = texto_usuario.replace(" ", "+")
	
	api_libros.cancel_request()
	api_juegos.cancel_request()
	api_series.cancel_request()
	api_pelis.cancel_request()
	
	apis_pendientes = 4
	
	# HTTPS FORZADO
	api_libros.request("https://openlibrary.org/search.json?q=" + texto_url)
	
	var url_juegos = "https://api.rawg.io/api/games?key=" + RAWG_API_KEY + "&search=" + texto_url + "&page_size=" + str(MAX_RESULTADOS)
	api_juegos.request(url_juegos, headers_chrome)
	
	var url_series = "https://api.tvmaze.com/search/shows?q=" + texto_url
	api_series.request(url_series)
	
	if not TMDB_API_KEY.begins_with("PON_AQUI"):
		var url_pelis = "https://api.themoviedb.org/3/search/movie?api_key=" + TMDB_API_KEY + "&query=" + texto_url + "&language=es-ES"
		api_pelis.request(url_pelis)
	else:
		apis_pendientes -= 1

# --- RECOPILADORES ---
func recopilar_libros(result, code, headers, body):
	if code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json:
			var lista = json.get("docs", [])
			var count = 0
			for item in lista:
				if count >= MAX_RESULTADOS:
					break
				
				var titulo = item.get("title", "Sin título")
				var autor = item.get("author_name", ["Desconocido"])[0]
				var rating = float(item.get("ratings_average", 0.0))
				
				var cover_id = item.get("cover_i", 0)
				var img = ""
				if cover_id != 0:
					img = "https://covers.openlibrary.org/b/id/" + str(int(cover_id)) + "-M.jpg"
				
				agregar_resultado(titulo, "Libro - " + autor, rating, img)
				count += 1
	
	chequear_fin_peticion()

func recopilar_juegos(result, code, headers, body):
	if code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json:
			for item in json.get("results", []):
				var titulo = item.get("name", "Juego")
				var rating = float(item.get("rating", 0.0))
				var img = item.get("background_image", "")
				if img == null:
					img = ""
				agregar_resultado(titulo, "Videojuego", rating, img)
	
	chequear_fin_peticion()

func recopilar_series(result, code, headers, body):
	if code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json:
			var count = 0
			for item in json:
				if count >= MAX_RESULTADOS:
					break
				
				var show = item.get("show", {})
				var titulo = show.get("name", "Serie TV")
				
				var raw_score = show.get("rating", {}).get("average")
				if raw_score == null:
					raw_score = 0.0
				
				var rating_final = float(raw_score) / 2.0
				
				var img = ""
				var imagenes = show.get("image")
				if imagenes != null:
					img = imagenes.get("medium", "")
				
				agregar_resultado(titulo, "Serie TV", rating_final, img)
				count += 1
	
	chequear_fin_peticion()

func recopilar_pelis(result, code, headers, body):
	if code == 200:
		var json = JSON.parse_string(body.get_string_from_utf8())
		if json:
			var count = 0
			for item in json.get("results", []):
				if count >= MAX_RESULTADOS:
					break
				
				var titulo = item.get("title", "Película")
				var fecha = item.get("release_date", "")
				if fecha.length() >= 4:
					titulo += " (" + fecha.substr(0,4) + ")"
				
				var rating_final = float(item.get("vote_average", 0.0)) / 2.0
				
				var img = ""
				var poster = item.get("poster_path")
				if poster != null:
					img = "https://image.tmdb.org/t/p/w500" + poster
				
				agregar_resultado(titulo, "Película", rating_final, img)
				count += 1
	
	chequear_fin_peticion()

# --- GESTIÓN ---
func agregar_resultado(titulo, categoria, rating, imagen):
	resultados_combinados.append({
		"titulo": titulo,
		"categoria": categoria,
		"rating": rating,
		"imagen": imagen
	})

func chequear_fin_peticion():
	apis_pendientes -= 1
	if apis_pendientes <= 0:
		mostrar_resultados_ordenados()

func ordenar_por_similitud(a, b):
	var sim_a = a["titulo"].to_lower().similarity(texto_buscado_actual)
	var sim_b = b["titulo"].to_lower().similarity(texto_buscado_actual)
	
	if a["titulo"].to_lower().begins_with(texto_buscado_actual):
		sim_a += 0.5
	if b["titulo"].to_lower().begins_with(texto_buscado_actual):
		sim_b += 0.5
	
	return sim_a > sim_b

func mostrar_resultados_ordenados():
	for ficha in contenedor_lista.get_children():
		ficha.queue_free()
	
	resultados_combinados.sort_custom(ordenar_por_similitud)
	
	for dato in resultados_combinados:
		var pasa = false
		
		if chk_game.button_pressed and dato["categoria"] == "Videojuego":
			pasa = true
		elif chk_movie.button_pressed and dato["categoria"] == "Película":
			pasa = true
		elif chk_serie.button_pressed and dato["categoria"] == "Serie TV":
			pasa = true
		elif chk_book.button_pressed and dato["categoria"].begins_with("Libro"):
			pasa = true
		
		if pasa and dato["rating"] >= rating_slider.value:
			var nueva_ficha = escena_resultado.instantiate()
			contenedor_lista.add_child(nueva_ficha)
			nueva_ficha.configurar_datos(
				dato["titulo"],
				dato["categoria"],
				dato["rating"],
				dato["imagen"]
			)
