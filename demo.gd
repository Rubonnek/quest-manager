extends Control

@export var quest_manager_viewer_ : Control

func _ready() -> void:
	var main_quest_manager : QuestManager = QuestManager.new()
	main_quest_manager.set_name("Main")
	var quest : QuestEntry = main_quest_manager.add_quest("Main Quest Line", "Quest Description")
	quest.set_metadata("data1", "value1")
	quest.set_metadata("data2", "value2")
	quest.set_accepted()
	quest.set_completed()
	var subquest : QuestEntry = quest.add_subquest("Subquest", "Subquest Description")
	subquest.set_metadata("subdata1", "subvalue1")
	subquest.set_metadata("subdata2", "subvalue2")

	var secondary_quest_manager : QuestManager = QuestManager.new()
	var secondary_quest : QuestEntry = secondary_quest_manager.add_quest("Secondary Quest Line", "Description")
	var _subquest : QuestEntry = secondary_quest.add_subquest("Subquest", "Description")
	secondary_quest_manager.set_name("Secondary")

	var global_quest_manager : QuestManager = QuestManager.new()
	global_quest_manager.append(main_quest_manager)
	global_quest_manager.append(secondary_quest_manager)
	global_quest_manager.set_name("Global")


	# Populate the UI
	@warning_ignore(&"unsafe_method_access")
	quest_manager_viewer_.add_quest_manager(global_quest_manager)
	@warning_ignore(&"unsafe_method_access")
	quest_manager_viewer_.add_quest_manager(main_quest_manager)
	@warning_ignore(&"unsafe_method_access")
	quest_manager_viewer_.add_quest_manager(secondary_quest_manager)
