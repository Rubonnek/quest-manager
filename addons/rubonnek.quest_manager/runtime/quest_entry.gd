#============================================================================
#  quest_entry.gd                                                           |
#============================================================================
#                         This file is part of:                             |
#                            QUEST MANAGER                                  |
#           https://github.com/Rubonnek/quest-manager                       |
#============================================================================
# Copyright (c) 2024 Wilson Enrique Alvarez Torres                          |
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
## A minimalistic representation of a quest.
##
## Must be created with [method QuestManager.add_quest].
class_name QuestEntry


var _m_quest_entry_dictionary : Dictionary
var _m_quest_entry_dictionary_id : int
var _m_quest_manager : QuestManager = null


enum _key {
	TITLE,
	DESCRIPTION,
	ACCEPTANCE_CONDITIONS,
	ACCEPTANCE_COUNT,
	COMPLETION_CONDITIONS,
	COMPLETION_COUNT,
	IS_ACTIVE,
	PARENT_QUEST_ID,
	SUBQUESTS_IDS,
	METADATA,
}


## Adds a subquest to the current quest.
func add_subquest(p_title : String = "", p_description : String = "") -> QuestEntry:
	# Initialize subquest dictionary:
	var subquest_dictionary : Dictionary = {}
	_m_quest_manager.get_data().push_back(subquest_dictionary)
	subquest_dictionary[_key.PARENT_QUEST_ID] = get_id()
	if not p_title.is_empty():
		subquest_dictionary[_key.TITLE] = p_title
	if not p_description.is_empty():
		subquest_dictionary[_key.DESCRIPTION] = p_description

	# Add the subquest id to the current quest entry
	var subquests_ids : Array = _m_quest_entry_dictionary.get(_key.SUBQUESTS_IDS, [])
	if not _m_quest_entry_dictionary.has(_key.SUBQUESTS_IDS):
		_m_quest_entry_dictionary[_key.SUBQUESTS_IDS] = subquests_ids

	var subquest : QuestEntry = _m_quest_manager.get_quest(_m_quest_manager.size() - 1)
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
	return _m_quest_manager.get_quest(p_subquest_id)


## Returns true if the quest has any subquests
func has_subquests() -> bool:
	return _m_quest_entry_dictionary.has(_key.SUBQUESTS_IDS)


## Returns an array of internal subquest IDs.
func get_subquests_ids() -> Array:
	var subquests_ids : Array =  _m_quest_entry_dictionary.get(_key.SUBQUESTS_IDS, [])
	return subquests_ids.duplicate(true)


# Returns a reference to the array of internal subquest IDs. Used in [method QuestManager.append].
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
		var quest : QuestEntry = _m_quest_manager.get_quest(quest_id)
		if not quest.is_completed():
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
		var quest : QuestEntry = _m_quest_manager.get_quest(quest_id)
		if not quest.is_accepted():
			return false
		if quest.has_subquests():
			quest_id_stack.append_array(quest.get_subquests_ids())
	return true


## Sets the Quest title
func set_title(p_title : String) -> void:
	if p_title.is_empty():
		var _success : bool = _m_quest_entry_dictionary.erase(_key.TITLE)
	else:
		_m_quest_entry_dictionary[_key.TITLE] = p_title
	__send_entry_to_manager_viewer()


## Sets the Quest title
func get_title() -> String:
	return _m_quest_entry_dictionary.get(_key.TITLE, "")


## Sets the Quest title
func has_title() -> bool:
	return _m_quest_entry_dictionary.has(_key.TITLE)


## Sets the Quest description
func set_description(p_description : String) -> void:
	if p_description.is_empty():
		var _success : bool = _m_quest_entry_dictionary.erase(_key.DESCRIPTION)
	else:
		_m_quest_entry_dictionary[_key.DESCRIPTION] = p_description
	__send_entry_to_manager_viewer()


## Sets the Quest description
func get_description() -> String:
	return _m_quest_entry_dictionary.get(_key.DESCRIPTION, "")


## Sets the Quest title
func has_description() -> bool:
	return _m_quest_entry_dictionary.has(_key.DESCRIPTION)


## Adds a boolean-returning [Callable] as a completion condition
func add_completion_condition(p_condition : Callable) -> void:
	var completion_conditions_array : Array = _m_quest_entry_dictionary.get(_key.COMPLETION_CONDITIONS, [])
	if  not _m_quest_entry_dictionary.has(_key.COMPLETION_CONDITIONS):
		_m_quest_entry_dictionary[_key.COMPLETION_CONDITIONS] = completion_conditions_array
	completion_conditions_array.push_back(p_condition)
	__send_entry_to_manager_viewer()
	__sync_why_cant_be_completed_with_debugger()


# Returns a reference to the internal quest completion conditions
func __get_completion_conditions() -> Array:
	var completion_conditions_array : Array = _m_quest_entry_dictionary.get(_key.ACCEPTANCE_CONDITIONS, [])
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


## Clears all the completion conditions
func clear_completion_conditions() -> void:
	var _success : bool = _m_quest_entry_dictionary.erase(_key.COMPLETION_CONDITIONS)
	__send_entry_to_manager_viewer()


## Sets the quest as completed by increasing an internal quest completion count by 1. This function will emit [signal QuestManager.quest_completed].
func set_completed() -> void:
	var count : int = _m_quest_entry_dictionary.get(_key.COMPLETION_COUNT, 0) + 1
	_m_quest_entry_dictionary[_key.COMPLETION_COUNT] = count
	_m_quest_manager.__quest_completed(self)
	__send_entry_to_manager_viewer()


## Returns true if the quest completion count is greater than 0. See [method set_completed].
func is_completed() -> bool:
	var status : bool = _m_quest_entry_dictionary.get(_key.COMPLETION_COUNT, 0) > 0
	return status


## Returns the number of times the quest has been completed.
func get_completion_count() -> int:
	var count : int = _m_quest_entry_dictionary.get(_key.COMPLETION_COUNT, 0)
	return count


## Adds a boolean-returning [Callable] as a acceptance condition
func add_acceptance_condition(p_condition : Callable) -> void:
	var acceptance_conditions_array : Array = _m_quest_entry_dictionary.get(_key.ACCEPTANCE_CONDITIONS, [])
	if  not _m_quest_entry_dictionary.has(_key.ACCEPTANCE_CONDITIONS):
		_m_quest_entry_dictionary[_key.ACCEPTANCE_CONDITIONS] = acceptance_conditions_array
	acceptance_conditions_array.push_back(p_condition)
	__send_entry_to_manager_viewer()
	__sync_why_cant_be_accepted_with_debugger()


# Returns a reference to the internal quest acceptance conditions
func __get_acceptance_conditions() -> Array:
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


## Clears all the acceptance conditions
func clear_acceptance_conditions() -> void:
	var _success : bool = _m_quest_entry_dictionary.erase(_key.ACCEPTANCE_CONDITIONS)
	__send_entry_to_manager_viewer()


## Sets the quest as accepted by increasing an internal quest acceptance count by 1. This function will emit [signal QuestManager.quest_accepted].
func set_accepted() -> void:
	var count : int = _m_quest_entry_dictionary.get(_key.ACCEPTANCE_COUNT, 0) + 1
	_m_quest_entry_dictionary[_key.ACCEPTANCE_COUNT] = count
	_m_quest_manager.__quest_accepted(self)
	__send_entry_to_manager_viewer()


## Returns true if the quest acceptance count is greater than 0. See [method set_accepted].
func is_accepted() -> bool:
	var status : bool = _m_quest_entry_dictionary.get(_key.ACCEPTANCE_COUNT, 0) > 0
	return status


## Returns the number of times the quest has been accepted.
func get_acceptance_count() -> int:
	var count : int = _m_quest_entry_dictionary.get(_key.ACCEPTANCE_COUNT, 0)
	return count


## Sets the quest as active.
func set_active(p_should_activate : bool = true) -> void:
	if p_should_activate:
		_m_quest_entry_dictionary[_key.IS_ACTIVE] = true
	else:
		var _ignore : bool = _m_quest_entry_dictionary.erase(_key.IS_ACTIVE)
	_m_quest_manager.__quest_activation_changed(self)


## Sets the quest as inactive.
func set_inactive() -> void:
	set_active(false)


## Returns true if the quest is active.
func is_active() -> bool:
	return _m_quest_entry_dictionary.has(_key.IS_ACTIVE)


## Returns true if the quest has a parent quest.
func has_parent() -> bool:
	return _m_quest_entry_dictionary.has(_key.PARENT_QUEST_ID)


## Returns the parent quest.
func get_parent() -> QuestEntry:
	if has_parent():
		var parent_id : int = _m_quest_entry_dictionary.get(_key.PARENT_QUEST_ID)
		return _m_quest_manager.get_quest(parent_id)
	else:
		push_warning("QuestEntry: entry has no parent. Returning the same quest.")
		return self


# Sets the parent quest.
func __set_parent(p_quest_id : int) -> void:
	_m_quest_entry_dictionary[_key.PARENT_QUEST_ID] = p_quest_id


## Returns the topmost parent quest.
func get_topmost_parent() -> QuestEntry:
	var root_quest : QuestEntry = self
	while root_quest.has_parent():
		root_quest = root_quest.get_parent()
	return root_quest


## Returns the quest ID
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


## Returns a duplicated quest dictionary in which its data keys have been replaced with strings and its subquests with their respective data for easy visualization/debugging/displaying.
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
		var quest : QuestEntry = _m_quest_manager.get_quest(quest_id)
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
			var source_subquest_data : Dictionary = _m_quest_manager.get_data()[subquest_id]
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
		var quest_manager_id : int = _m_quest_manager.get_instance_id()
		EngineDebugger.send_message(p_message, [quest_manager_id, _m_quest_entry_dictionary_id, p_reasons])


func __send_entry_to_manager_viewer() -> void:
	if EngineDebugger.is_active():
		# NOTE: Do not use the quest_entry API directly here when setting values to avoid sending unnecessary data to the debugger about the duplicated quest entry being sent to display

		# The debugger viewer requires certain objects to be stringified before sending -- duplicate the QuestEntry data to avoid overriding the runtime data:
		var duplicated_quest_entry_data : Dictionary = get_data().duplicate(true)

		# Stringify all the callables
		var duplicated_acceptance_conditions_array : Array = duplicated_quest_entry_data.get(_key.ACCEPTANCE_CONDITIONS, [])
		for index : int in duplicated_acceptance_conditions_array.size():
			var callable : Callable = duplicated_acceptance_conditions_array[index]
			duplicated_acceptance_conditions_array[index] = str(callable)
		var duplicated_completion_conditions_array : Array = duplicated_quest_entry_data.get(_key.COMPLETION_CONDITIONS, [])
		for index : int in duplicated_completion_conditions_array.size():
			var callable : Callable = duplicated_completion_conditions_array[index]
			duplicated_completion_conditions_array[index] = str(callable)

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

		var quest_manager_id : int = _m_quest_manager.get_instance_id()
		EngineDebugger.send_message("quest_manager:sync_entry", [quest_manager_id, _m_quest_entry_dictionary_id, duplicated_quest_entry_data])


func _init(p_quest_entry_dictionary_id : int, p_quest_manager : QuestManager, p_quest_entry_dictionary : Dictionary = {}, p_title : String = "", p_description : String = "") -> void:
	_m_quest_entry_dictionary_id  = p_quest_entry_dictionary_id
	_m_quest_entry_dictionary = p_quest_entry_dictionary
	_m_quest_manager = p_quest_manager
	if not p_title.is_empty():
		_m_quest_entry_dictionary[_key.TITLE] = p_title
	if not p_description.is_empty():
		_m_quest_entry_dictionary[_key.DESCRIPTION] = p_description
