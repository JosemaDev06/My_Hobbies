extends Control

@onready var username_input =$CenterContainer/Panel/MarginContainer/VBoxContainer/Username 
@onready var email_input = $CenterContainer/Panel/MarginContainer/VBoxContainer/Email
@onready var password_input = $CenterContainer/Panel/MarginContainer/VBoxContainer/Password
@onready var confirm_input = $CenterContainer/Panel/MarginContainer/VBoxContainer/ConfirmPassword
@onready var status_label =$CenterContainer/Panel/MarginContainer/VBoxContainer/StatusLabel 

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

func _on_RegisterBtn_pressed():
	var username = username_input.text.strip_edges()
	var email = email_input.text.strip_edges()
	var password = password_input.text.strip_edges()
	var confirm = confirm_input.text.strip_edges()
	
	if username == "" or email == "" or password == "" or confirm == "":
		status_label.text = "Completa todos los campos"
		return
	
	if not email.contains("@") or not email.contains("."):
		status_label.text = "Correo no válido"
		return
	
	if password != confirm:
		status_label.text = "Las contraseñas no coinciden"
		return
	
	if users_data.has(username):
		status_label.text = "Usuario ya existe"
		return
	
	users_data[username] = {
		"email": email,
		"password": password,
		"reviews": [],
		"favorites": []
	}
	
	save_users()
	status_label.text = "Cuenta creada correctamente"
	
	await get_tree().create_timer(1.5).timeout
	get_tree().change_scene_to_file("res://Scenes/login_scene.tscn")


func _on_BackBtn_pressed():
	get_tree().change_scene_to_file("res://Scenes/login_scene.tscn")
