extends Node

func get_user_file(username: String) -> String:
	return "user://data_%s.json" % username


func create_user_data(username: String):
	var path = get_user_file(username)
	if not FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.WRITE)
		file.store_string(JSON.stringify({
			"favorites": [],
			"reviews": []
		}, "\t"))
		file.close()


func load_user_data(username: String):
	var path = get_user_file(username)
	if not FileAccess.file_exists(path):
		create_user_data(username)

	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	return JSON.parse_string(content)


func save_user_data(username: String, data):
	var path = get_user_file(username)
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()


func add_review(username: String, review_data: Dictionary):
	var data = load_user_data(username)
	data["reviews"].append(review_data)
	save_user_data(username, data)
