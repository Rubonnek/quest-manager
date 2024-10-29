extends Control

var quest_manager : QuestManager = QuestManager.new()

func _ready() -> void:
	var quest : QuestEntry = quest_manager.add_quest("Main Quest", "Main Quest Description")

	# There's built-in support for quests to be active/inactive
	quest.set_active()
	quest.set_inactive()

	# Accepted or rejected
	quest.set_accepted()
	quest.set_rejected()

	# Completed, failed or cancelled
	quest.set_completed()
	quest.set_failed()
	quest.set_canceled()

	# As well as your own metadata
	quest.set_metadata("some_key", "some_value")
