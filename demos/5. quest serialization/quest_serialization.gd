extends Control

var quest_manager : QuestManager = QuestManager.new()
const save_path : String = "user://quests.cfg"

func _ready() -> void:
	var config_file : ConfigFile = ConfigFile.new()
	var quest_id : int = -1

	if FileAccess.file_exists(save_path):
		config_file.load(save_path)
		var data : Array[Dictionary] = config_file.get_value("quest_manager", "data")
		quest_manager.set_data(data)
		quest_id = config_file.get_value("quest_manager", "first_quest")
	else:
		quest_id = quest_manager.add_quest("Increased counter upon creation", "Keep launching this scene to see the counters going up").get_id()

	var quest : QuestEntry = quest_manager.get_quest(quest_id)
	var count : int = quest.get_metadata("count", -1)
	count += 1
	quest.set_metadata("count", count)
	quest.set_completed()

	print("Count: ", count)

	# The order in which each quest is added is important.
	# Tracking each quest entry ID is useful when mid-development the order in which the quests are created changes.
	config_file.set_value("quest_manager", "first_quest", quest_id)

	# WARNING: On an actual project you might want to clear the quest conditions before saving the quest to disk and reinstall those conditions at runtime after loading the data from disk.
	# quest_manager.clear_conditions() can also be called to clear the conditions of all the quests before saving its data.
	config_file.set_value("quest_manager","data", quest_manager.get_data())
	config_file.save(save_path)

