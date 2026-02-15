extends Node

var current_user : String = ""

const USERS_FILE = "user://users.json"

func _ready():
	if not FileAccess.file_exists(USERS_FILE):
		var file = FileAccess.open(USERS_FILE, FileAccess.WRITE)
		file.store_string(JSON.stringify({"users": []}))
		file.close()


func register(username: String, password: String) -> bool:
	var data = load_users()

	for user in data["users"]:
		if user["username"] == username:
			return false
	
	data["users"].append({
		"username": username,
		"password": password
	})

	save_users(data)
	return true


func login(username: String, password: String) -> bool:
	var data = load_users()

	for user in data["users"]:
		if user["username"] == username and user["password"] == password:
			current_user = username
			return true
	
	return false


func load_users():
	var file = FileAccess.open(USERS_FILE, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	return JSON.parse_string(content)


func save_users(data):
	var file = FileAccess.open(USERS_FILE, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
