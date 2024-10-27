extends Control

var quest_manager : QuestManager = QuestManager.new()

func _ready() -> void:
	# Quest creation will automatically be synchronized with the debugger -- check the QuestManager tab.
	var _quest : QuestEntry = quest_manager.add_quest("Main Quest", "Main Quest Description")
