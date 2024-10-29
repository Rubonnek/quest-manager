extends Control

@export var quest_manager_viewer_ : Control

func _ready() -> void:
	var quest_manager : QuestManager = QuestManager.new()
	var quest : QuestEntry = quest_manager.add_quest("Quest")
	var subquest : QuestEntry = quest.add_subquest("Subquest")

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

	subquest.add_acceptance_condition(tautology)
	subquest.add_completion_condition(contradiction)
	subquest.add_rejection_condition(contradiction)
	subquest.add_failure_condition(contradiction)
	subquest.add_cancelation_condition(contradiction)

	# There are also helper functions for testing the states of all the subquests.
	# For example:
	quest.are_subquests_completed()
	# Which can be used as a completion condition:
	quest.add_completion_condition(quest.are_subquests_completed)
