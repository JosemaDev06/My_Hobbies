extends Control

# --- REFERENCIAS ---
@onready var view_container = $ViewContainer
@onready var menu_sidebar = $ViewContainer/SideMenu
@onready var content_area = $ViewContainer/ContentArea
@onready var btn_hamburguesa = $Menu
@onready var menu_spacer = $ViewContainer/MenuSpacer

# --- CONFIGURACIÓN ---
var menu_abierto = true
var ancho_menu = 300.0
var tiempo_animacion = 0.3

# --- PRECARGA DE ESCENAS ---
var escena_search = preload("res://Scenes/Search/SearchScene.tscn")
var escena_profile = preload("res://Scenes/Profile/ProfileScene.tscn")

func _ready():
	# Configuración inicial del menú
	menu_sidebar.custom_minimum_size.x = ancho_menu
	menu_sidebar.clip_contents = true 

	# Conectar botón búsqueda
	var btn_search = menu_sidebar.find_child("Sear")
	if btn_search:
		btn_search.pressed.connect(_on_search_pressed)

	# Conectar botón profile
	var btn_profile = menu_sidebar.find_child("Profile")
# -------------------------
# MENÚ LATERAL
# -------------------------

func _on_hamburguesa_pressed():
	if menu_abierto:
		cerrar_menu()
	else:
		abrir_menu()

func cerrar_menu():
	var tween = create_tween().set_parallel(true)
	
	tween.tween_property(
		menu_sidebar,
		"custom_minimum_size:x",
		0,
		tiempo_animacion
	).set_trans(Tween.TRANS_SINE)
	
	tween.tween_property(
		menu_spacer,
		"custom_minimum_size:x",
		80,
		tiempo_animacion
	).set_trans(Tween.TRANS_SINE)
	
	tween.tween_callback(func(): view_container.queue_sort())
	menu_abierto = false

func abrir_menu():
	var tween = create_tween().set_parallel(true)
	
	tween.tween_property(
		menu_sidebar,
		"custom_minimum_size:x",
		ancho_menu,
		tiempo_animacion
	).set_trans(Tween.TRANS_SINE)
	
	tween.tween_property(
		menu_spacer,
		"custom_minimum_size:x",
		0,
		tiempo_animacion
	).set_trans(Tween.TRANS_SINE)
	
	tween.tween_callback(func(): view_container.queue_sort())
	menu_abierto = true


# -------------------------
# NAVEGACIÓN
# -------------------------

func limpiar_content_area():
	for hijo in content_area.get_children():
		hijo.queue_free()

func cargar_escena(escena):
	limpiar_content_area()
	
	var instancia = escena.instantiate()
	content_area.add_child(instancia)
	
	if instancia is Control:
		instancia.set_anchors_and_offsets_preset(
			Control.PRESET_FULL_RECT,
			Control.PRESET_MODE_MINSIZE,
			0
		)

	if menu_abierto:
		cerrar_menu()


func _on_search_pressed():
	cargar_escena(escena_search)


func _on_profile_pressed():
	cargar_escena(escena_profile)
