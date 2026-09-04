extends Node

const SAVE_PATH := "user://save.json"

var data := {
	"last_completed_level": 0,
	"highest_unlocked_level": 1,
	"selected_background_id": 1,
	"chosen_buffs": {
		"level5": 0,
		"level10": 0,
		"level15": 0
	}
}

func load_save():
	if not FileAccess.file_exists(SAVE_PATH):
		save()
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	var text = file.get_as_text()
	var result = JSON.parse_string(text)
	if result is Dictionary:
		data.merge(result, true)
		var saved_buffs = result.get("chosen_buffs", {})
		var default_buffs := {
			"level5": 0,
			"level10": 0,
			"level15": 0,
		}
		if saved_buffs is Dictionary:
			default_buffs.merge(saved_buffs, true)
		data.chosen_buffs = default_buffs
		data.selected_background_id = clampi(int(data.get("selected_background_id", 1)), 1, 5)

func save():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
