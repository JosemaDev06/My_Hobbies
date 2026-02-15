extends Control

@onready var username_input = $CenterContainer/Panel/MarginContainer/VBoxContainer/Username
@onready var password_input = $CenterContainer/Panel/MarginContainer/VBoxContainer/Password
@onready var status_label = $CenterContainer/Panel/MarginContainer/VBoxContainer/Error

const SAVE_PATH = "user://users.json"

var users_data = {}

func _ready():
	load_users()

func load_users():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		
		if content != "":
			users_data = JSON.parse_string(content)
	else:
		users_data = {}

func save_users():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(users_data, "\t"))
	file.close()



func _on_LoginBtn_pressed():
	var username = username_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	
	if not users_data.has(username):
		status_label.text = "Usuario no encontrado"
		return
	
	if users_data[username]["password"] != password:
		status_label.text = "Contraseña incorrecta"
		return
	
	# ✅ LOGIN CORRECTO
	status_label.text = "Login correcto"
	Global.current_user = username 
	get_tree().change_scene_to_file("res://Scenes/Main/MainApp.tscn")


func _on_register_pressed():
	get_tree().change_scene_to_file("res://Scenes/Register_Scene.tscn")
