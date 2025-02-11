#============================================================================
#  quest_entry.gd                                                           |
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
## Basic representation of a quest.
##
## A quest entry contains the basic necessary data to support a quest of any type. Must be created with [method QuestManager.add_quest].[br]
## By design, quest entries themselves don't hold any data -- all the data it manipulates is stored within the [QuestManager] it is associated with.[br]
class_name QuestEntry


## Emitted when [method set_active] is called.
signal quest_activated(p_quest : QuestEntry)
## Emitted when [method set_accepted] is called.
signal quest_accepted(p_quest : QuestEntry)
## Emitted when [method set_rejected] is called.
signal quest_rejected(p_quest : QuestEntry)
## Emitted when [method set_canceled] is called.
signal quest_canceled(p_quest : QuestEntry)
## Emitted when [method set_completed] is called.
signal quest_completed(p_quest : QuestEntry)
## Emitted when [method set_failed] is called.
signal quest_failed(p_quest : QuestEntry)
## Emitted when [method set_updated] is called.
signal quest_updated(p_quest : QuestEntry)


var _m_quest_entry_dictionary : Dictionary
var _m_quest_entry_dictionary_id : int
var _m_quest_manager_weakref : WeakRef = null

enum _key {
	TITLE,
	DESCRIPTION,
	PARENT_QUEST_ID,
	SUBQUESTS_IDS,
	METADATA,

	IS_ACTIVE,

	IS_ACCEPTED,
	ACCEPTANCE_CONDITIONS,

	IS_REJECTED,
	REJECTION_CONDITIONS,

	IS_COMPLETED,
	COMPLETION_CONDITIONS,

	IS_FAILED,
	FAILURE_CONDITIONS,

	IS_CANCELED,
	CANCELATION_CONDITIONS,
}


## Adds a subquest to the current quest.
func add_subquest(p_title : String = "", p_description : String = "") -> QuestEntry:
	# Initialize subquest dictionary:
	var subquest_dictionary : Dictionary = {}
	get_manager()._m_quest_dictionaries.push_back(subquest_dictionary)
	subquest_dictionary[_key.PARENT_QUEST_ID] = get_id()
	if not p_title.is_empty():
		subquest_dictionary[_key.TITLE] = p_title
	if not p_description.is_empty():
		subquest_dictionary[_key.DESCRIPTION] = p_description

	# Add the subquest id to the current quest entry
	var subquests_ids : Array = _m_quest_entry_dictionary.get(_key.SUBQUESTS_IDS, [])
	if not _m_quest_entry_dictionary.has(_key.SUBQUESTS_IDS):
		_m_quest_entry_dictionary[_key.SUBQUESTS_IDS] = subquests_ids

	var subquest_id : int = get_manager().size() - 1
	var subquest : QuestEntry = QuestEntry.new(subquest_id, get_manager(), subquest_dictionary)
	get_manager()._m_quest_entries.push_back(subquest)
	subquests_ids.push_back(subquest.get_id())

	# Send both entries to the EngineDebugger
	subquest.__send_entry_to_manager_viewer()
	__send_entry_to_manager_viewer()
	return subquest


## Returns the subquest.
func get_subquest(p_subquest_id : int) -> QuestEntry:
	assert(has_subquests(), "QuestEntry: Entry has no subquest.")
	var subquests_ids : Dictionary = _m_quest_entry_dictionary.get(_key.SUBQUESTS_IDS, {})
	assert(subquests_ids.has(p_subquest_id), "QuestEntry: Subquest ID is not present. Subquest was never added.")
	return get_manager().get_quest(p_subquest_id)


## Returns true if the quest has any subquests.
func has_subquests() -> bool:
	return _m_quest_entry_dictionary.has(_key.SUBQUESTS_IDS)


## Returns an array containing the subquest IDs.
func get_subquests_ids() -> Array:
	var subquests_ids : Array =  _m_quest_entry_dictionary.get(_key.SUBQUESTS_IDS, [])
	return subquests_ids.duplicate(true)


# Returns a reference to the array of internal subquest IDs. Used in [method QuestManager.append] -- needed for updating the subquest IDs within that function.
func __get_subquests_ids() -> Array:
	var subquests_ids : Array =  _m_quest_entry_dictionary.get(_key.SUBQUESTS_IDS, [])
	return subquests_ids


## Returns true if all the subquests are completed.
func are_subquests_completed() -> bool:
	if not has_subquests():
		return true

	var quest_id_stack : Array = get_subquests_ids()
	while not quest_id_stack.is_empty():
		var quest_id : int = quest_id_stack.pop_back()
		var quest : QuestEntry = get_manager().get_quest(quest_id)
		if not quest.is_completed():
			return false
		if quest.has_subquests():
			quest_id_stack.append_array(quest.get_subquests_ids())
	return true


## Returns true if all the subquests are failed.
func are_subquests_failed() -> bool:
	if not has_subquests():
		return true

	var quest_id_stack : Array = get_subquests_ids()
	while not quest_id_stack.is_empty():
		var quest_id : int = quest_id_stack.pop_back()
		var quest : QuestEntry = get_manager().get_quest(quest_id)
		if not quest.is_failed():
			return false
		if quest.has_subquests():
			quest_id_stack.append_array(quest.get_subquests_ids())
	return true


## Returns true if all the subquests are accepted.
func are_subquests_accepted() -> bool:
	if not has_subquests():
		return true

	var quest_id_stack : Array = get_subquests_ids()
	while not quest_id_stack.is_empty():
		var quest_id : int = quest_id_stack.pop_back()
		var quest : QuestEntry = get_manager().get_quest(quest_id)
		if not quest.is_accepted():
			return false
		if quest.has_subquests():
			quest_id_stack.append_array(quest.get_subquests_ids())
	return true


## Returns true if all the subquests are rejected.
func are_subquests_rejected() -> bool:
	if not has_subquests():
		return true

	var quest_id_stack : Array = get_subquests_ids()
	while not quest_id_stack.is_empty():
		var quest_id : int = quest_id_stack.pop_back()
		var quest : QuestEntry = get_manager().get_quest(quest_id)
		if not quest.is_rejected():
			return false
		if quest.has_subquests():
			quest_id_stack.append_array(quest.get_subquests_ids())
	return true


## Returns true if all the subquests are canceled.
func are_subquests_canceled() -> bool:
	if not has_subquests():
		return true

	var quest_id_stack : Array = get_subquests_ids()
	while not quest_id_stack.is_empty():
		var quest_id : int = quest_id_stack.pop_back()
		var quest : QuestEntry = get_manager().get_quest(quest_id)
		if not quest.is_canceled():
			return false
		if quest.has_subquests():
			quest_id_stack.append_array(quest.get_subquests_ids())
	return true


## Sets the quest title.
func set_title(p_title : String) -> void:
	if p_title.is_empty():
		var _success : bool = _m_quest_entry_dictionary.erase(_key.TITLE)
	else:
		_m_quest_entry_dictionary[_key.TITLE] = p_title
	__send_entry_to_manager_viewer()


## Returns the quest title.
func get_title() -> String:
	return _m_quest_entry_dictionary.get(_key.TITLE, "")


## Returns true if the quest has a title.
func has_title() -> bool:
	return _m_quest_entry_dictionary.has(_key.TITLE)


## Sets the quest description.
func set_description(p_description : String) -> void:
	if p_description.is_empty():
		var _success : bool = _m_quest_entry_dictionary.erase(_key.DESCRIPTION)
	else:
		_m_quest_entry_dictionary[_key.DESCRIPTION] = p_description
	__send_entry_to_manager_viewer()


## Returns the quest description.
func get_description() -> String:
	return _m_quest_entry_dictionary.get(_key.DESCRIPTION, "")


## Returns true if the quest has a description.
func has_description() -> bool:
	return _m_quest_entry_dictionary.has(_key.DESCRIPTION)


## Adds a boolean-returning [Callable] as a completion condition.
func add_completion_condition(p_condition : Callable) -> void:
	var completion_conditions_array : Array = _m_quest_entry_dictionary.get(_key.COMPLETION_CONDITIONS, [])
	if  not _m_quest_entry_dictionary.has(_key.COMPLETION_CONDITIONS):
		_m_quest_entry_dictionary[_key.COMPLETION_CONDITIONS] = completion_conditions_array
	completion_conditions_array.push_back(p_condition)
	__send_entry_to_manager_viewer()
	__sync_why_cant_be_completed_with_debugger()


## Returns a reference to the internal quest completion conditions. Modifying this array will directly modify the data of the quest entry. Use with caution.
func get_completion_conditions() -> Array:
	var completion_conditions_array : Array = _m_quest_entry_dictionary.get(_key.COMPLETION_CONDITIONS, [])
	return completion_conditions_array


## Returns true if all the completion conditions return true. Returns false otherwise.
func can_be_completed() -> bool:
	if not _m_quest_entry_dictionary.has(_key.COMPLETION_CONDITIONS):
		return true
	var completion_conditions_array : Array = _m_quest_entry_dictionary.get(_key.COMPLETION_CONDITIONS, [])
	for condition : Callable in completion_conditions_array:
		if condition.is_valid():
			if not condition.call():
				__sync_why_cant_be_completed_with_debugger()
				return false
		else:
			__sync_why_cant_be_completed_with_debugger()
			condition.call() # call the Callable anyway even when invalid to let it error out and notify the developer
			return false
	return true


# Sends an array of the completion conditions that returned false to the debugger. Only executed when can_be_completed is called and EngineDebugger is active.
func __sync_why_cant_be_completed_with_debugger() -> void:
	if EngineDebugger.is_active():
		var reasons : Array[String] = []
		if not _m_quest_entry_dictionary.has(_key.COMPLETION_CONDITIONS):
			__sync_runtime_data_with_debugger("quest_manager:sync_why_cant_be_completed", reasons)
		var completion_conditions_array : Array = _m_quest_entry_dictionary.get(_key.COMPLETION_CONDITIONS, [])
		for condition : Callable in completion_conditions_array:
			if not condition.is_valid():
				reasons.push_back(str(condition) + ": is an invalid Callable")
			elif condition.is_valid() and not condition.call():
				reasons.push_back(str(condition) + ": returns false")
		__sync_runtime_data_with_debugger("quest_manager:sync_why_cant_be_completed", reasons)


## Returns true if there's at least one completion condition installed. False otherwise.
func has_completion_conditions() -> bool:
	return _m_quest_entry_dictionary.has(_key.COMPLETION_CONDITIONS)


## Clears all the completion conditions.
func clear_completion_conditions() -> void:
	var _success : bool = _m_quest_entry_dictionary.erase(_key.COMPLETION_CONDITIONS)
	__send_entry_to_manager_viewer()


## Sets the quest as completed. This function will emit [signal quest_completed].
func set_completed(p_status : bool = true) -> void:
	if p_status:
		_m_quest_entry_dictionary[_key.IS_COMPLETED] = true
	else:
		var _success : bool = _m_quest_entry_dictionary.erase(_key.IS_COMPLETED)
	quest_completed.emit(self)
	__send_entry_to_manager_viewer()


## Returns true if the quest has been completed. See [method set_completed].
func is_completed() -> bool:
	return _m_quest_entry_dictionary.has(_key.IS_COMPLETED)


## Adds a boolean-returning [Callable] as a failure condition.
func add_failure_condition(p_condition : Callable) -> void:
	var failure_conditions_array : Array = _m_quest_entry_dictionary.get(_key.FAILURE_CONDITIONS, [])
	if  not _m_quest_entry_dictionary.has(_key.FAILURE_CONDITIONS):
		_m_quest_entry_dictionary[_key.FAILURE_CONDITIONS] = failure_conditions_array
	failure_conditions_array.push_back(p_condition)
	__send_entry_to_manager_viewer()
	__sync_why_cant_be_failed_with_debugger()


## Returns a reference to the internal quest failure conditions. Modifying this array will directly modify the data of the quest entry. Use with caution.
func get_failure_conditions() -> Array:
	var failure_conditions_array : Array = _m_quest_entry_dictionary.get(_key.FAILURE_CONDITIONS, [])
	return failure_conditions_array


## Returns true if all the failure conditions return true. Returns false otherwise.
func can_be_failed() -> bool:
	if not _m_quest_entry_dictionary.has(_key.FAILURE_CONDITIONS):
		return true
	var failure_conditions_array : Array = _m_quest_entry_dictionary.get(_key.FAILURE_CONDITIONS, [])
	for condition : Callable in failure_conditions_array:
		if condition.is_valid():
			if not condition.call():
				__sync_why_cant_be_failed_with_debugger()
				return false
		else:
			__sync_why_cant_be_failed_with_debugger()
			condition.call() # call the Callable anyway even when invalid to let it error out and notify the developer
			return false
	return true


# Sends an array of the failure conditions that returned false to the debugger. Only executed when can_be_failed is called and EngineDebugger is active.
func __sync_why_cant_be_failed_with_debugger() -> void:
	if EngineDebugger.is_active():
		var reasons : Array[String] = []
		if not _m_quest_entry_dictionary.has(_key.FAILURE_CONDITIONS):
			__sync_runtime_data_with_debugger("quest_manager:sync_why_cant_be_failed", reasons)
		var failure_conditions_array : Array = _m_quest_entry_dictionary.get(_key.FAILURE_CONDITIONS, [])
		for condition : Callable in failure_conditions_array:
			if not condition.is_valid():
				reasons.push_back(str(condition) + ": is an invalid Callable")
			elif condition.is_valid() and not condition.call():
				reasons.push_back(str(condition) + ": returns false")
		__sync_runtime_data_with_debugger("quest_manager:sync_why_cant_be_failed", reasons)


## Returns true if there's at least one failure condition installed. False otherwise.
func has_failure_conditions() -> bool:
	return _m_quest_entry_dictionary.has(_key.FAILURE_CONDITIONS)


## Clears all the failure conditions.
func clear_failure_conditions() -> void:
	var _success : bool = _m_quest_entry_dictionary.erase(_key.FAILURE_CONDITIONS)
	__send_entry_to_manager_viewer()


## Sets the quest as failed. This function will emit [signal quest_failed].
func set_failed(p_status : bool = true) -> void:
	if p_status:
		_m_quest_entry_dictionary[_key.IS_FAILED] = true
	else:
		var _success : bool = _m_quest_entry_dictionary.erase(_key.IS_FAILED)
	quest_failed.emit(self)
	__send_entry_to_manager_viewer()


## Returns true if the quest has been failed. See [method set_failed].
func is_failed() -> bool:
	return _m_quest_entry_dictionary.has(_key.IS_FAILED)


## Adds a boolean-returning [Callable] as a cancelation condition.
func add_cancelation_condition(p_condition : Callable) -> void:
	var cancelation_conditions_array : Array = _m_quest_entry_dictionary.get(_key.CANCELATION_CONDITIONS, [])
	if  not _m_quest_entry_dictionary.has(_key.CANCELATION_CONDITIONS):
		_m_quest_entry_dictionary[_key.CANCELATION_CONDITIONS] = cancelation_conditions_array
	cancelation_conditions_array.push_back(p_condition)
	__send_entry_to_manager_viewer()
	__sync_why_cant_be_canceled_with_debugger()


## Returns a reference to the internal quest cancelation conditions. Modifying this array will directly modify the data of the quest entry. Use with caution.
func get_cancelation_conditions() -> Array:
	var cancelation_conditions_array : Array = _m_quest_entry_dictionary.get(_key.CANCELATION_CONDITIONS, [])
	return cancelation_conditions_array


## Returns true if all the cancelation conditions return true. Returns false otherwise.
func can_be_canceled() -> bool:
	if not _m_quest_entry_dictionary.has(_key.CANCELATION_CONDITIONS):
		return true
	var cancelation_conditions_array : Array = _m_quest_entry_dictionary.get(_key.CANCELATION_CONDITIONS, [])
	for condition : Callable in cancelation_conditions_array:
		if condition.is_valid():
			if not condition.call():
				__sync_why_cant_be_canceled_with_debugger()
				return false
		else:
			__sync_why_cant_be_canceled_with_debugger()
			condition.call() # call the Callable anyway even when invalid to let it error out and notify the developer
			return false
	return true


# Sends an array of the cancelation conditions that returned false to the debugger. Only executed when can_be_canceled is called and EngineDebugger is active.
func __sync_why_cant_be_canceled_with_debugger() -> void:
	if EngineDebugger.is_active():
		var reasons : Array[String] = []
		if not _m_quest_entry_dictionary.has(_key.CANCELATION_CONDITIONS):
			__sync_runtime_data_with_debugger("quest_manager:sync_why_cant_be_canceled", reasons)
		var cancelation_conditions_array : Array = _m_quest_entry_dictionary.get(_key.CANCELATION_CONDITIONS, [])
		for condition : Callable in cancelation_conditions_array:
			if not condition.is_valid():
				reasons.push_back(str(condition) + ": is an invalid Callable")
			elif condition.is_valid() and not condition.call():
				reasons.push_back(str(condition) + ": returns false")
		__sync_runtime_data_with_debugger("quest_manager:sync_why_cant_be_canceled", reasons)


## Returns true if there's at least one cancelation condition installed. False otherwise.
func has_cancelation_conditions() -> bool:
	return _m_quest_entry_dictionary.has(_key.CANCELATION_CONDITIONS)


## Clears all the cancelation conditions.
func clear_cancelation_conditions() -> void:
	var _success : bool = _m_quest_entry_dictionary.erase(_key.CANCELATION_CONDITIONS)
	__send_entry_to_manager_viewer()


## Sets the quest as canceled. This function will emit [signal quest_canceled].
func set_canceled(p_status : bool = true) -> void:
	if p_status:
		_m_quest_entry_dictionary[_key.IS_CANCELED] = true
	else:
		var _success : bool = _m_quest_entry_dictionary.erase(_key.IS_CANCELED)
	quest_canceled.emit(self)
	__send_entry_to_manager_viewer()


## Returns true if the quest has been canceled. See [method set_canceled].
func is_canceled() -> bool:
	return _m_quest_entry_dictionary.has(_key.IS_CANCELED)


## Adds a boolean-returning [Callable] as a acceptance condition.
func add_acceptance_condition(p_condition : Callable) -> void:
	var acceptance_conditions_array : Array = _m_quest_entry_dictionary.get(_key.ACCEPTANCE_CONDITIONS, [])
	if  not _m_quest_entry_dictionary.has(_key.ACCEPTANCE_CONDITIONS):
		_m_quest_entry_dictionary[_key.ACCEPTANCE_CONDITIONS] = acceptance_conditions_array
	acceptance_conditions_array.push_back(p_condition)
	__send_entry_to_manager_viewer()
	__sync_why_cant_be_accepted_with_debugger()


## Returns a reference to the internal quest acceptance conditions. Modifying this array will directly modify the data of the quest entry. Use with caution.
func get_acceptance_conditions() -> Array:
	var acceptance_conditions_array : Array = _m_quest_entry_dictionary.get(_key.ACCEPTANCE_CONDITIONS, [])
	return acceptance_conditions_array


## Returns true if all the acceptance conditions return true. Returns false otherwise.
func can_be_accepted() -> bool:
	if not _m_quest_entry_dictionary.has(_key.ACCEPTANCE_CONDITIONS):
		return true
	var acceptance_conditions_array : Array = _m_quest_entry_dictionary.get(_key.ACCEPTANCE_CONDITIONS, [])
	for condition : Callable in acceptance_conditions_array:
		if condition.is_valid():
			if not condition.call():
				__sync_why_cant_be_accepted_with_debugger()
				return false
		else:
			__sync_why_cant_be_accepted_with_debugger()
			condition.call() # call the Callable anyway even when invalid to let it error out and notify the developer
			return false
	return true


# Sends an array of the acceptance conditions that returned false to the debugger. Only executed when can_be_accepted is called and EngineDebugger is active.
func __sync_why_cant_be_accepted_with_debugger() -> void:
	if EngineDebugger.is_active():
		var reasons : Array[String] = []
		if not _m_quest_entry_dictionary.has(_key.ACCEPTANCE_CONDITIONS):
			__sync_runtime_data_with_debugger("quest_manager:sync_why_cant_be_accepted", reasons)
			return
		var acceptance_conditions_array : Array = _m_quest_entry_dictionary.get(_key.ACCEPTANCE_CONDITIONS, [])
		for condition : Callable in acceptance_conditions_array:
			if not condition.is_valid():
				reasons.push_back(str(condition) + ": is an invalid Callable")
			elif condition.is_valid() and not condition.call():
				reasons.push_back(str(condition) + ": returns false")
		__sync_runtime_data_with_debugger("quest_manager:sync_why_cant_be_accepted", reasons)


## Returns true if there's at least one acceptance condition installed. False otherwise.
func has_acceptance_conditions() -> bool:
	return _m_quest_entry_dictionary.has(_key.ACCEPTANCE_CONDITIONS)


## Clears all the acceptance conditions.
func clear_acceptance_conditions() -> void:
	var _success : bool = _m_quest_entry_dictionary.erase(_key.ACCEPTANCE_CONDITIONS)
	__send_entry_to_manager_viewer()


## Sets the quest as accepted. This function will emit [signal quest_accepted].
func set_accepted(p_status : bool = true) -> void:
	if p_status:
		_m_quest_entry_dictionary[_key.IS_ACCEPTED] = true
	else:
		var _success : bool = _m_quest_entry_dictionary.erase(_key.IS_ACCEPTED)
	quest_accepted.emit(self)
	__send_entry_to_manager_viewer()


## Returns true if the quest has been accepted. See [method set_accepted].
func is_accepted() -> bool:
	return _m_quest_entry_dictionary.has(_key.IS_ACCEPTED)


## Adds a boolean-returning [Callable] as a rejection condition.
func add_rejection_condition(p_condition : Callable) -> void:
	var rejection_conditions_array : Array = _m_quest_entry_dictionary.get(_key.REJECTION_CONDITIONS, [])
	if  not _m_quest_entry_dictionary.has(_key.REJECTION_CONDITIONS):
		_m_quest_entry_dictionary[_key.REJECTION_CONDITIONS] = rejection_conditions_array
	rejection_conditions_array.push_back(p_condition)
	__send_entry_to_manager_viewer()
	__sync_why_cant_be_rejected_with_debugger()


## Returns a reference to the internal quest rejection conditions. Modifying this array will directly modify the data of the quest entry. Use with caution.
func get_rejection_conditions() -> Array:
	var rejection_conditions_array : Array = _m_quest_entry_dictionary.get(_key.REJECTION_CONDITIONS, [])
	return rejection_conditions_array


## Returns true if all the rejection conditions return true. Returns false otherwise.
func can_be_rejected() -> bool:
	if not _m_quest_entry_dictionary.has(_key.REJECTION_CONDITIONS):
		return true
	var rejection_conditions_array : Array = _m_quest_entry_dictionary.get(_key.REJECTION_CONDITIONS, [])
	for condition : Callable in rejection_conditions_array:
		if condition.is_valid():
			if not condition.call():
				__sync_why_cant_be_rejected_with_debugger()
				return false
		else:
			__sync_why_cant_be_rejected_with_debugger()
			condition.call() # call the Callable anyway even when invalid to let it error out and notify the developer
			return false
	return true


# Sends an array of the rejection conditions that returned false to the debugger. Only executed when can_be_rejected is called and EngineDebugger is active.
func __sync_why_cant_be_rejected_with_debugger() -> void:
	if EngineDebugger.is_active():
		var reasons : Array[String] = []
		if not _m_quest_entry_dictionary.has(_key.REJECTION_CONDITIONS):
			__sync_runtime_data_with_debugger("quest_manager:sync_why_cant_be_rejected", reasons)
			return
		var rejection_conditions_array : Array = _m_quest_entry_dictionary.get(_key.REJECTION_CONDITIONS, [])
		for condition : Callable in rejection_conditions_array:
			if not condition.is_valid():
				reasons.push_back(str(condition) + ": is an invalid Callable")
			elif condition.is_valid() and not condition.call():
				reasons.push_back(str(condition) + ": returns false")
		__sync_runtime_data_with_debugger("quest_manager:sync_why_cant_be_rejected", reasons)


## Returns true if there's at least one rejection condition installed. False otherwise.
func has_rejection_conditions() -> bool:
	return _m_quest_entry_dictionary.has(_key.REJECTION_CONDITIONS)


## Clears all the rejection conditions.
func clear_rejection_conditions() -> void:
	var _success : bool = _m_quest_entry_dictionary.erase(_key.REJECTION_CONDITIONS)
	__send_entry_to_manager_viewer()


## Sets the quest as rejected. This function will emit [signal quest_rejected].
func set_rejected(p_status : bool = true) -> void:
	if p_status:
		_m_quest_entry_dictionary[_key.IS_REJECTED] = true
	else:
		var _success : bool = _m_quest_entry_dictionary.erase(_key.IS_REJECTED)
	quest_rejected.emit(self)
	__send_entry_to_manager_viewer()


## Returns true if the quest has been rejected. See [method set_rejected].
func is_rejected() -> bool:
	return _m_quest_entry_dictionary.has(_key.IS_REJECTED)


## Sets the quest as active. This function will emit [signal quest_activated].
func set_active(p_status : bool = true) -> void:
	if p_status:
		_m_quest_entry_dictionary[_key.IS_ACTIVE] = true
	else:
		var _success : bool = _m_quest_entry_dictionary.erase(_key.IS_ACTIVE)
	quest_activated.emit(self)
	__send_entry_to_manager_viewer()


## Returns true if the quest is active.
func is_active() -> bool:
	return _m_quest_entry_dictionary.has(_key.IS_ACTIVE)


## Returns true if the quest has a parent quest.
func has_parent() -> bool:
	return _m_quest_entry_dictionary.has(_key.PARENT_QUEST_ID)


## Returns the parent quest. Returns [code]null[/code] when there is no parent.
func get_parent() -> QuestEntry:
	if has_parent():
		var parent_id : int = _m_quest_entry_dictionary.get(_key.PARENT_QUEST_ID)
		return get_manager().get_quest(parent_id)
	else:
		return null


# Sets the parent quest.
func __set_parent(p_quest_id : int) -> void:
	_m_quest_entry_dictionary[_key.PARENT_QUEST_ID] = p_quest_id


## Returns the topmost parent quest.
func get_topmost_parent() -> QuestEntry:
	var root_quest : QuestEntry = self
	while root_quest.has_parent():
		root_quest = root_quest.get_parent()
	return root_quest


## Returns the quest ID.
func get_id() -> int:
	return _m_quest_entry_dictionary_id


## Attaches the specified metadata to the quest entry.
func set_metadata(p_key : Variant, p_value : Variant) -> void:
	var metadata : Dictionary = _m_quest_entry_dictionary.get(_key.METADATA, {})
	metadata[p_key] = p_value
	if not _m_quest_entry_dictionary.has(_key.METADATA):
		_m_quest_entry_dictionary[_key.METADATA] = metadata
	__send_entry_to_manager_viewer()


## Returns the specified metadata from the quest entry.
func get_metadata(p_key : Variant, p_default_value : Variant = null) -> Variant:
	var metadata : Dictionary = _m_quest_entry_dictionary.get(_key.METADATA, {})
	return metadata.get(p_key, p_default_value)



## Returns a reference to the internal metadata dictionary.
func get_metadata_data() -> Dictionary:
	var metadata : Dictionary = _m_quest_entry_dictionary.get(_key.METADATA, {})
	if not _m_quest_entry_dictionary.has(_key.METADATA):
		# There's a chance the user wants to modify it externally and have it update the QuestEntry automatically -- make sure we store a reference of that metadata:
		_m_quest_entry_dictionary[_key.METADATA] = metadata
	return metadata


## Returns true if the quest has some metadata.
func has_metadata() -> bool:
	var metadata : Dictionary = _m_quest_entry_dictionary.get(_key.METADATA, {})
	return not metadata.is_empty()


## Returns a reference to the internal dictionary where quest entry data is stored.[br]
## [br]
## [color=yellow]Warning:[/color] Use with caution. Modifying this dictionary will directly modify the quest entry data.
func get_data() -> Dictionary:
	return _m_quest_entry_dictionary


## Returns a duplicated quest dictionary in which its data keys have been replaced with strings and its subquests with their respective data for a simpler text-based visualization.
func prettify() -> Dictionary:
	# Lambda function for making the data readable:
	var make_readable : Callable = func (p_quest_entry_dictionary_id : int, p_quest_entry_dictionary : Dictionary) -> void:
		p_quest_entry_dictionary["quest_id"] = p_quest_entry_dictionary_id
		for key : int in _key.values():
			if key in p_quest_entry_dictionary:
				var value : Variant = p_quest_entry_dictionary[key]
				var _ignore : bool = p_quest_entry_dictionary.erase(key)
				var key_as_string : String = _key.keys()[key]
				key_as_string = key_as_string.to_lower()
				p_quest_entry_dictionary[key_as_string] = value

	# Recursively inject each subquest reference with its data if any:
	var quest_id_stack : Array = [_m_quest_entry_dictionary_id]
	var quest_id_to_new_subquest_data : Dictionary = {}
	while not quest_id_stack.is_empty():
		# Process loop variable:
		var quest_id : int = quest_id_stack.pop_back()
		var quest : QuestEntry = get_manager().get_quest(quest_id)
		if quest.has_subquests():
			quest_id_stack.append_array(quest.get_subquests_ids())

		# Get the modified quest data
		var modified_quest_data : Dictionary
		if quest_id in quest_id_to_new_subquest_data:
			modified_quest_data = quest_id_to_new_subquest_data[quest_id]
		else:
			modified_quest_data = quest.get_data().duplicate(true)
			quest_id_to_new_subquest_data[quest_id] = modified_quest_data

		# Inject subquest ID data in-place of the original subquest ids
		var modified_subquest_ids_array : Array = modified_quest_data.get(_key.SUBQUESTS_IDS, [])
		for subquest_id_index : int in modified_subquest_ids_array.size():
			# Since each quest ID is unique, it's necessary to always duplicate the source data:
			var subquest_id : int = modified_subquest_ids_array[subquest_id_index]
			var source_subquest_data : Dictionary = get_manager().get_data()[subquest_id]
			var subquest_data : Dictionary = source_subquest_data.duplicate(true)

			# Track it the dictionary in case it has more subquests
			quest_id_to_new_subquest_data[subquest_id] = subquest_data

			# And replace the quest id with its actual data:
			modified_subquest_ids_array[subquest_id_index] = subquest_data

	# We are done modifying the data - we can now replace the keys with strings at each of the dictionaries we've tracked:
	for quest_id : int in quest_id_to_new_subquest_data:
		make_readable.call(quest_id, quest_id_to_new_subquest_data[quest_id])

	return quest_id_to_new_subquest_data[_m_quest_entry_dictionary_id]


func __sync_runtime_data_with_debugger(p_message : String, p_reasons : Array[String]) -> void:
	if EngineDebugger.is_active():
		var quest_manager_id : int = get_manager().get_instance_id()
		EngineDebugger.send_message(p_message, [quest_manager_id, _m_quest_entry_dictionary_id, p_reasons])


func __send_entry_to_manager_viewer() -> void:
	if EngineDebugger.is_active():
		# NOTE: Do not use the quest_entry API directly here when setting values to avoid sending unnecessary data to the debugger about the duplicated quest entry being sent to display

		# The debugger viewer requires certain objects to be stringified before sending -- duplicate the QuestEntry data to avoid overriding the runtime data:
		var duplicated_quest_entry_data : Dictionary = get_data().duplicate(true)

		# Stringify all the callables
		var stringify_callables_and_install_in_duplicated_entry_data : Callable = func (p_key : int) -> void:
			var duplicated_acceptance_conditions_array : Array = duplicated_quest_entry_data.get(p_key, [])
			for index : int in duplicated_acceptance_conditions_array.size():
				var callable : Callable = duplicated_acceptance_conditions_array[index]
				duplicated_acceptance_conditions_array[index] = str(callable)
		stringify_callables_and_install_in_duplicated_entry_data.call(_key.ACCEPTANCE_CONDITIONS)
		stringify_callables_and_install_in_duplicated_entry_data.call(_key.REJECTION_CONDITIONS)
		stringify_callables_and_install_in_duplicated_entry_data.call(_key.COMPLETION_CONDITIONS)
		stringify_callables_and_install_in_duplicated_entry_data.call(_key.FAILURE_CONDITIONS)
		stringify_callables_and_install_in_duplicated_entry_data.call(_key.CANCELATION_CONDITIONS)

		# Stringify all the metadata keys and values where needed to display them in text form in the viewer
		var metadata : Dictionary = _m_quest_entry_dictionary.get(_key.METADATA, {})
		if not metadata.is_empty():
			var stringified_metadata : Dictionary = {}
			for key : Variant in metadata:
				var value : Variant = metadata[key]
				if key is Callable or key is Object:
					stringified_metadata[str(key)] = str(value)
				else:
					stringified_metadata[key] = str(value)
			# Replaced the source metadata with the stringified version that can be displayed remotely:
			duplicated_quest_entry_data[_key.METADATA] = stringified_metadata

		var quest_manager_id : int = get_manager().get_instance_id()
		EngineDebugger.send_message("quest_manager:sync_entry", [quest_manager_id, _m_quest_entry_dictionary_id, duplicated_quest_entry_data])


## Utility function for emitting [signal quest_updated] when a quest is updated.
func set_updated() -> void:
	quest_updated.emit(self)


## Clears all the conditions installed on the quest.
func clear_conditions() -> void:
	var _success : bool = _m_quest_entry_dictionary.erase(_key.ACCEPTANCE_CONDITIONS)
	_success = _m_quest_entry_dictionary.erase(_key.REJECTION_CONDITIONS)
	_success = _m_quest_entry_dictionary.erase(_key.COMPLETION_CONDITIONS)
	_success = _m_quest_entry_dictionary.erase(_key.FAILURE_CONDITIONS)
	_success = _m_quest_entry_dictionary.erase(_key.CANCELATION_CONDITIONS)
	__send_entry_to_manager_viewer()


## Returns the [QuestManager] instance associated with the quest entry.
func get_manager() -> QuestManager:
	return _m_quest_manager_weakref.get_ref()


func _init(p_quest_entry_dictionary_id : int, p_quest_manager : QuestManager, p_quest_entry_dictionary : Dictionary = {}, p_title : String = "", p_description : String = "") -> void:
	_m_quest_entry_dictionary_id  = p_quest_entry_dictionary_id
	_m_quest_entry_dictionary = p_quest_entry_dictionary
	_m_quest_manager_weakref = weakref(p_quest_manager)
	if not p_title.is_empty():
		_m_quest_entry_dictionary[_key.TITLE] = p_title
	if not p_description.is_empty():
		_m_quest_entry_dictionary[_key.DESCRIPTION] = p_description
