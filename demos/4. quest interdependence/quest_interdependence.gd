extends Control

@export var quest_manager_viewer_ : Control

func _ready() -> void:
	var quest_manager : QuestManager = QuestManager.new()
	var main_quest : QuestEntry = quest_manager.add_quest()
	var main_subquest : QuestEntry = main_quest.add_subquest()

	# Quest interdependence has been implemented as an array of boolean-returning callables.
	# Each of these callables can be installed to test whether a quest:
	# * can be accepted
	# * can be rejected
	# * can be completed
	# * can be failed
	# * can be canceled

	var tautology : Callable = func tautology() -> bool:
		return true

	var contradiction : Callable = func contradiction() -> bool:
		return false

	# When a condition fails, the debugger will show which condition is returning either false or can't be evaluated because it's Callable isn't valid.
	main_subquest.add_acceptance_condition(tautology)
	main_subquest.add_completion_condition(contradiction)
	main_subquest.add_rejection_condition(contradiction)
	main_subquest.add_failure_condition(contradiction)
	main_subquest.add_cancelation_condition(contradiction)
