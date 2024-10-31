extends Control

var quest_manager : QuestManager = QuestManager.new()

func _ready() -> void:
	# A quest can have as many subquests as needed
	var quest : QuestEntry = quest_manager.add_quest("Main Quest", "Main Quest Description")
	var subquest : QuestEntry = quest.add_subquest("Main Subquest", "Main Subquest Description")
	var _sub_subquest : QuestEntry = subquest.add_subquest("Main Subsubquest", "Main Subsubquest Description")
