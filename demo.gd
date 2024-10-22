extends Control

@export var quest_manager_viewer_ : Control

func _ready() -> void:
	# Single Quest
	var main_quest_manager : QuestManager = QuestManager.new()
	var quest : QuestEntry = main_quest_manager.add_quest("Main Quest", "Quest Description")
	quest.set_metadata("data1", "value1")

	var subquest : QuestEntry = quest.add_subquest("Main Subquest", "Main Subquest Description")
	subquest.add_acceptance_condition(condition)
	subquest.add_completion_condition(condition)
	subquest.set_metadata("subdata1", "subvalue1")
	subquest.set_accepted()
	subquest.set_completed()
	main_quest_manager.set_name("Main") # Used to identify the manager in the debugger

	var secondary_quest_manager : QuestManager = QuestManager.new()
	var secondary_quest : QuestEntry = secondary_quest_manager.add_quest("Secondary Quest Line", "Description")
	var _subquest : QuestEntry = secondary_quest.add_subquest("Subquest", "Description")
	secondary_quest_manager.set_name("Secondary")
