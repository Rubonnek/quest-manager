extends Control

var quest_manager : QuestManager = QuestManager.new()

func _ready() -> void:
	var quest : QuestEntry = quest_manager.add_quest("Main Quest", "Main Quest Description")

	# There are six independent states that can be actively tracked.
	quest.set_active()
	quest.set_inactive()

	quest.set_completed()
	quest.set_failed()

	quest.set_accepted()
	quest.set_rejected()

	# And you can also add your own metadata to each quest
	quest.set_metadata("some_key", "some_value")
