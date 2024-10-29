extends Control

var quest_manager : QuestManager = QuestManager.new()
const save_path : String = "user://quests.cfg"

func _ready() -> void:
	var config_file : ConfigFile = ConfigFile.new()
	var quest_id : int = -1

	if FileAccess.file_exists(save_path):
		config_file.load(save_path)
		var data : Array = config_file.get_value("quest_manager", "data")
		quest_manager.set_data(data)
		quest_id = config_file.get_value("quest_ids", "first_quest")
	else:
		quest_id = quest_manager.add_quest("Counters Keep Going UP", "Keep launching this scene to see the counters going up").get_id()

	var quest : QuestEntry = quest_manager.get_quest(quest_id)

	quest.set_active()
	quest.set_inactive()
	print("Activation Count: ", quest.get_activation_count())
	print("Inactivation Count: ", quest.get_inactivation_count())


	quest.set_accepted()
	quest.set_rejected()
	print("Acceptance Count: ", quest.get_acceptance_count())
	print("Rejection Count: ", quest.get_rejection_count())


	quest.set_completed()
	quest.set_failed()
	quest.set_canceled()
	print("Completion Count: ", quest.get_completion_count())
	print("Failure Count: ", quest.get_failure_count())
	print("Cancelation Count: ", quest.get_cancelation_count())

	config_file.set_value("quest_ids", "first_quest", quest_id)

	# WARNING: On an actual project you might want to clear the quest conditions before saving the quest to disk and reinstall those conditions at runtime after loading the data from disk.
	# quest_manager.clear_conditions() # can also be called to clear the conditions of all the quests.
	config_file.set_value("quest_manager","data", quest_manager.get_data())
	config_file.save(save_path)
