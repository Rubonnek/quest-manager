#============================================================================
#  quest_manager.gd                                                         |
#============================================================================
#                         This file is part of:                             |
#                            QUEST MANAGER                                  |
#           https://github.com/Rubonnek/quest-manager                       |
#============================================================================
# Copyright (c) 2024-2025 Wilson Enrique Alvarez Torres                     |
#                                                                           |
# Permission is hereby granted, free of charge, to any person obtaining     |
# a copy of this software and associated documentation files (the           |
# "Software"), to deal in the Software without restriction, including       |
# without limitation the rights to use, copy, modify, merge, publish,       |
# distribute, sublicense, andor sell copies of the Software, and to         |
# permit persons to whom the Software is furnished to do so, subject to     |
# the following conditions:                                                 |
#                                                                           |
# The above copyright notice and this permission notice shall be            |
# included in all copies or substantial portions of the Software.           |
#                                                                           |
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,           |
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF        |
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.    |
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY      |
# CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,      |
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE         |
# SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                    |
#============================================================================


extends RefCounted
## A minimalistic quest manager for tracking the quests progress and completion.
##
## QuestManager provides an API for creating quest line trees and walking them.
## The manager internally manages an array of dictionaries each of which can be accessed as a [QuestEntry].
## [br]
## [b]Quickstart[/b]:
## [codeblock]
## var quest_manager : QuestManager = QuestManager.new()
## var quest_entry : QuestEntry = quest_manager.add_quest("Quest Title", "Quest Description")
## var subquest_entry : QuestEntry = quest_entry.add_subquest("Subquest Title", "Subquest Description")
## print(JSON.stringify(quest_manager.prettify(), "\t"))
## [/codeblock]
class_name QuestManager


var _m_quest_dictionaries : Array[Dictionary] = []
var _m_quest_entries : Array[QuestEntry] = []


## Adds a topmost quest entry.
func add_quest(p_title : String = "", p_description : String = "") -> QuestEntry:
	var quest_id : int = _m_quest_dictionaries.size()
	var quest_entry : QuestEntry = QuestEntry.new(quest_id, self, {}, p_title, p_description)
	_m_quest_dictionaries.push_back(quest_entry.get_data())
	_m_quest_entries.push_back(quest_entry)
	quest_entry.__send_entry_to_manager_viewer()
	return quest_entry


## Returns a quest entry given its ID.
func get_quest(p_quest_id : int) -> QuestEntry:
	assert(p_quest_id < _m_quest_dictionaries.size() && p_quest_id >= 0, "QuestManager: QuestEntry ID is not present.")
	return _m_quest_entries[p_quest_id]


## Returns true if a quest ID is present.
func has_quest(p_quest_id : int) -> bool:
	return p_quest_id < _m_quest_dictionaries.size()


## Returns the number of quest entries.
func size() -> int:
	return _m_quest_dictionaries.size()


## Returns a number between 0 and 1 representing the percent of overall accepted and completed tasks.
func get_progress() -> float:
	if _m_quest_dictionaries.is_empty():
		return 1.0
	var total_steps : float = _m_quest_dictionaries.size() * 2
	var steps_taken : float = 0
	for quest_entry : QuestEntry in _m_quest_entries:
		if quest_entry.is_accepted():
			steps_taken += 1
		if quest_entry.is_completed():
			steps_taken += 1
	return steps_taken / total_steps


## Appends all the quests available in another QuestManager.[br]
## [br]
## [color=yellow]Warning:[/color] Appending quests from a source quest manager will duplicate the quests data, meaning that updating any data in the source quest entry or quest manager won't automatically update the quest in both places at the same time.
func append(p_quest_manager : QuestManager) -> void:
	var id_offset : int = _m_quest_dictionaries.size()
	_m_quest_dictionaries.append_array(p_quest_manager.get_data().duplicate(true))
	for index : int in range(id_offset, _m_quest_dictionaries.size()):
		# Update the ID on each of the appended quest entries
		var quest_entry : QuestEntry = get_quest(index)
		if quest_entry.has_parent():
			quest_entry.__set_parent(id_offset)
		if quest_entry.has_subquests():
			var internal_subquest_array : Array = quest_entry.__get_subquests_ids()
			for subquest_id_index : int in internal_subquest_array.size():
				var original_id : int = internal_subquest_array[subquest_id_index]
				internal_subquest_array[subquest_id_index] = original_id + id_offset

		# Synchronize the entry with the debugger
		quest_entry.__send_entry_to_manager_viewer()


## Clears every condition from every quest entry. Useful when saving quests to disk since some conditions may become invalid upon loading.
func clear_conditions() -> void:
	for index : int in _m_quest_dictionaries.size():
		# Clear all the conditions
		var quest_entry : QuestEntry = get_quest(index)
		quest_entry.clear_acceptance_conditions()
		quest_entry.clear_rejection_conditions()
		quest_entry.clear_completion_conditions()
		quest_entry.clear_failure_conditions()
		quest_entry.clear_cancelation_conditions()


## Returns a reference to the internal data.
func get_data() -> Array[Dictionary]:
	return _m_quest_dictionaries


## Overwrites the quest manager data.
func set_data(p_data : Array[Dictionary]) -> void:
	_m_quest_dictionaries = p_data
	for quest_id : int in p_data.size():
		var quest_data : Dictionary = p_data[quest_id]
		var quest_entry : QuestEntry = QuestEntry.new(quest_id, self, quest_data)
		_m_quest_entries.push_back(quest_entry)
		if EngineDebugger.is_active():
			quest_entry.__send_entry_to_manager_viewer()


## Returns a duplicated quests array in a tree-like format with internal keys replaced with strings for easier reading/debugging.[br]
## [br]
## [b]Example[/b]:
## [codeblock]
## var quest_manager : QuestManager = QuestManager.new()
## var quest_entry : QuestEntry = quest_manager.add_quest("Quest Title", "Quest Description")
## var subquest_entry : QuestEntry = quest_entry.add_subquest("Subquest Title", "Subquest Description")
## print(JSON.stringify(quest_manager.prettify(), "\t"))
## [/codeblock]
func prettify() -> Array:
	var prettified_data : Array = []
	for quest_id : int in _m_quest_dictionaries.size():
		# Prettify the top level quests only:
		var quest_entry : QuestEntry = get_quest(quest_id)
		if quest_entry.has_parent():
			continue
		prettified_data.push_back(quest_entry.prettify())
	return prettified_data


## Sets a name to the manager in debug builds only. The manager name is only used for display by the quest manager viewer in the debugger.
func set_name(p_name : String) -> void:
	if OS.is_debug_build():
		set_meta(&"name", p_name)
	if EngineDebugger.is_active():
		EngineDebugger.send_message("quest_manager:set_name", [get_instance_id(), p_name])


## Gets the name of the manager. Returns an empty string in release buidls. The manager name is only used for display by the quest manager viewer in the debugger.
func get_name() -> String:
	return get_meta(&"name", "")


# ==== ITERATOR ====
# Iterates over the topmost quest entries only
var _m_iter_needle : int = 0

func __should_continue() -> bool:
	return (_m_iter_needle < _m_quest_dictionaries.size())

func _iter_init(_p_args : Array) -> bool:
	_m_iter_needle = 0
	return __should_continue()

func _iter_next(_p_args : Array) -> bool:
	_m_iter_needle += 1
	while __should_continue():
		var quest_entry : QuestEntry = get_quest(_m_iter_needle)
		if not quest_entry.has_parent():
			break
		_m_iter_needle += 1
	return __should_continue()

func _iter_get(_p_args : Variant) -> QuestEntry:
	return get_quest(_m_iter_needle)
# ==== ITERATOR ====

# Injects a quest dictionary given a quest ID. This is used in the debugger to synchronize QuestEntries.
func __inject(p_quest_id : int, p_quest_dictionary : Dictionary) -> void:
	if _m_quest_dictionaries.size()  <= p_quest_id:
		if _m_quest_dictionaries.resize(p_quest_id + 1) != OK:
			push_warning("QuestManager: Unable to inject quest data array! The array won't be visualized properly.")
			return
		if _m_quest_entries.resize(p_quest_id + 1) != OK:
			push_warning("QuestManager: Unable to inject quest entries array! The array won't be visualized properly.")
			return
	_m_quest_dictionaries[p_quest_id] = p_quest_dictionary
	var quest_entry : QuestEntry = QuestEntry.new(p_quest_id, self, p_quest_dictionary)
	_m_quest_entries[p_quest_id] = quest_entry


func _init() -> void:
	if EngineDebugger.is_active():
		# Register with the debugger
		var current_script : Resource = get_script()
		var path : String = current_script.get_path()
		var name : String = get_name()
		EngineDebugger.send_message("quest_manager:register_manager", [get_instance_id(), name, path])
