extends Control

# --- REFERENCIAS ---
# Buscamos los nodos por los nombres que acabas de poner
@onready var menu_sidebar = $SideMenu
@onready var btn_hamburguesa = $Menu

# --- CONFIGURACIÓN ---
var menu_abierto = true  # Empezamos asumiendo que está abierto porque así lo tienes en el editor
var ancho_menu = 291     # Ajusta esto al ancho que le diste a tu zona gris
var tiempo_animacion = 0.3

func _ready():
	btn_hamburguesa.pressed.connect(_on_hamburguesa_pressed)

func _on_hamburguesa_pressed():
	if menu_abierto:
		cerrar_menu()
	else:
		abrir_menu()

func cerrar_menu():
	var tween = create_tween()
	# Movemos el menú hacia la izquierda (negativo) para esconderlo
	tween.tween_property(menu_sidebar, "position:x", -ancho_menu, tiempo_animacion)
	menu_abierto = false

func abrir_menu():
	var tween = create_tween()
	# Lo devolvemos a la posición 0
	tween.tween_property(menu_sidebar, "position:x", 0, tiempo_animacion)
	menu_abierto = true

func cerrar_menu_instantaneo():
	menu_sidebar.position.x = -ancho_menu
	menu_abierto = false
