extends Control

const SAVE_PATH = "user://users.json"

var users_data = {}

@onready var username_label = $MarginContainer/VBoxContainer/Header/VBoxContainer/Username
@onready var description_edit = $MarginContainer/VBoxContainer/Header/VBoxContainer/DescriptionEdit
@onready var profile_picture = $MarginContainer/VBoxContainer/Header/VBoxContainer2/ProfilePicture
@onready var seen_container = $MarginContainer/VBoxContainer/ScrollContainer/SeenListContainer
@onready var file_dialog = $FileDialog


func _ready():
	load_users()
	load_profile()
	load_seen_list()


# -------------------------
# CARGAR / GUARDAR JSON
# -------------------------

func load_users():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		var content = file.get_as_text()
		file.close()

		if content != "":
			users_data = JSON.parse_string(content)
		else:
			users_data = {}
	else:
		users_data = {}

	print("JSON cargado:", users_data)


func save_users():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(users_data, "\t"))
	file.close()


# -------------------------
# CARGAR PERFIL
# -------------------------

func load_profile():
	var user = Global.current_user

	print("Usuario actual:", user)
	print("Existe en JSON:", users_data.has(user))

	# MOSTRAR SIEMPRE EL NOMBRE
	username_label.text = user

	if user == "" or not users_data.has(user):
		return

	if users_data[user].has("description"):
		description_edit.text = users_data[user]["description"]

	if users_data[user].has("profile_picture"):
		var path = users_data[user]["profile_picture"]
		if FileAccess.file_exists(path):
			var image = Image.new()
			if image.load(path) == OK:
				var texture = ImageTexture.create_from_image(image)
				profile_picture.texture = texture


# -------------------------
# GUARDAR DESCRIPCIÓN
# -------------------------

func _on_SaveProfileBtn_pressed():
	var user = Global.current_user

	if user == "" or not users_data.has(user):
		print("Usuario inválido")
		return

	users_data[user]["description"] = description_edit.text
	save_users()


# -------------------------
# CAMBIAR FOTO
# -------------------------

func _on_ChangePictureBtn_pressed():
	file_dialog.popup_centered()


func _on_FileDialog_file_selected(path):
	var user = Global.current_user

	if user == "" or not users_data.has(user):
		return

	var image = Image.new()
	if image.load(path) != OK:
		print("Error cargando imagen")
		return

	var texture = ImageTexture.create_from_image(image)
	profile_picture.texture = texture

	var save_path = "user://profile_%s.png" % user
	image.save_png(save_path)

	users_data[user]["profile_picture"] = save_path
	save_users()


# -------------------------
# CARGAR LISTA DE VISTOS
# -------------------------

func load_seen_list():
	var user = Global.current_user

	if user == "" or not users_data.has(user):
		return

	if not users_data[user].has("seen"):
		return

	var seen_list = users_data[user]["seen"]

	seen_list.sort_custom(func(a, b):
		return a["personal_rating"] > b["personal_rating"]
	)

	for item in seen_list:
		var label = Label.new()
		label.text = "%s - ⭐ %d" % [item["title"], item["personal_rating"]]
		seen_container.add_child(label)
