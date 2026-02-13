extends Control

# --- REFERENCIAS ---
# Asegúrate de que las rutas a los nodos sean correctas según tu árbol
@onready var view_container = $ViewContainer
@onready var menu_sidebar = $ViewContainer/SideMenu
@onready var content_area = $ViewContainer/ContentArea
@onready var btn_hamburguesa = $Menu

# --- CONFIGURACIÓN ---
var menu_abierto = true
var ancho_menu = 300.0  # El ancho que tiene tu zona gris
var tiempo_animacion = 0.3

# Precarga de escenas para evitar tirones
var escena_search = preload("res://Scenes/Search/SearchScene.tscn")

func _ready():
	# Forzamos el ancho inicial y activamos el recorte para que no se desborde al cerrar
	menu_sidebar.custom_minimum_size.x = ancho_menu
	menu_sidebar.clip_contents = true 
	
	btn_hamburguesa.pressed.connect(_on_hamburguesa_pressed)
	
	# Si el botón de búsqueda está dentro del SideMenu, lo conectamos:
	var btn_search = menu_sidebar.find_child("Sear") # Ajusta el nombre si es distinto
	if btn_search:
		btn_search.pressed.connect(_on_search_pressed)

func _on_hamburguesa_pressed():
	if menu_abierto:
		cerrar_menu()
	else:
		abrir_menu()

@onready var menu_spacer = $ViewContainer/MenuSpacer # El nuevo nodo invisible

func cerrar_menu():
	var tween = create_tween().set_parallel(true)
	# 1. Cerramos el menú (lo que ya tenías)
	tween.tween_property(menu_sidebar, "custom_minimum_size:x", 0, tiempo_animacion).set_trans(Tween.TRANS_SINE)
	
	# 2. En lugar de offset, abrimos el "espacio de seguridad" para el botón
	# Pon el ancho que necesites para que no choque (ej: 80)
	tween.tween_property(menu_spacer, "custom_minimum_size:x", 80, tiempo_animacion).set_trans(Tween.TRANS_SINE)
	
	tween.tween_callback(func(): view_container.queue_sort())
	menu_abierto = false

func abrir_menu():
	var tween = create_tween().set_parallel(true)
	# 1. Abrimos el menú
	tween.tween_property(menu_sidebar, "custom_minimum_size:x", ancho_menu, tiempo_animacion).set_trans(Tween.TRANS_SINE)
	
	# 2. Cerramos el espacio de seguridad (ya no hace falta porque está el menú)
	tween.tween_property(menu_spacer, "custom_minimum_size:x", 0, tiempo_animacion).set_trans(Tween.TRANS_SINE)
	
	tween.tween_callback(func(): view_container.queue_sort())
	menu_abierto = true
# --- NAVEGACIÓN ---

func _on_search_pressed():
	# 1. Limpiar el ContentArea (cuadro blanco)
	for hijo in content_area.get_children():
		hijo.queue_free()
	
	# 2. Instanciar la escena de búsqueda
	var instancia = escena_search.instantiate()
	content_area.add_child(instancia)
	
	# 3. Forzar a que ocupe todo el espacio del cuadro blanco
	if instancia is Control:
		instancia.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 0)
