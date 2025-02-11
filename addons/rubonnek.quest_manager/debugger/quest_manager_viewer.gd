#============================================================================
#  quest_manager_viewer.gd                                                  |
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

@tool
extends PanelContainer

@export var quest_manager_viewer_manager_selection_line_edit_ : LineEdit
@export var quest_manager_viewer_manager_selection_tree_ : Tree
@export var quest_manager_viewer_quest_entries_tree_ : Tree
@export var quest_manager_viewer_quest_entries_view_warning_label_ : Label
@export var quest_manager_viewer_quest_data_view_text_edit_ : TextEdit
@export var quest_manager_viewer_quest_data_view_warning_label_ : Label
@export var quest_manager_viewer_quest_metadata_view_text_edit_ : TextEdit
@export var quest_manager_viewer_quest_metadata_view_warning_label_ : Label

var _m_original_quest_entry_view_warning_text : String
var _m_original_quest_data_view_warning_text : String
var _m_original_quest_metadata_view_warning_text : String

var _m_remote_quest_manager_id_to_tree_item_map_cache : Dictionary
var _m_quest_id_to_tree_item_map_cache : Array

func _ready() -> void:
	# Connect QuestManager tree signals
	var _success : int = quest_manager_viewer_manager_selection_tree_.item_selected.connect(__on_quest_manager_selection_tree_item_selected)
	_success = quest_manager_viewer_manager_selection_tree_.nothing_selected.connect(__on_quest_manager_selection_tree_nothing_selected)

	# Connect QuestEntry tree signals
	_success = quest_manager_viewer_quest_entries_tree_.item_selected.connect(__on_quest_view_selection_item_selected)
	_success = quest_manager_viewer_quest_entries_tree_.nothing_selected.connect(__on_quest_view_selection_nothing_selected)

	# Connect line edit for filtering the QuestManagers list
	_success = quest_manager_viewer_manager_selection_line_edit_.text_changed.connect(__on_quest_manager_selection_line_edit_text_changed)

	# Grab the original metadata warning text -- we'll need this to restore their state once the debugger session is stopped
	_m_original_quest_entry_view_warning_text = quest_manager_viewer_quest_entries_view_warning_label_.get_text()
	_m_original_quest_data_view_warning_text = quest_manager_viewer_quest_data_view_warning_label_.get_text()
	_m_original_quest_metadata_view_warning_text = quest_manager_viewer_quest_metadata_view_warning_label_.get_text()


# ==== EDITOR DEBUGGER PLUGIN PASSTHROUGH FUNCTIONS BEGIN ======
func on_editor_debugger_plugin_capture(p_message : String, p_data : Array) -> bool:
	var column : int = 0
	match p_message:
		"quest_manager:register_manager":
			var quest_manager_id : int = p_data[0]
			var quest_manager_name : String = p_data[1]
			var quest_manager_path : String = p_data[2]

			# Generate name
			var target_name : String
			if not quest_manager_name.is_empty():
				target_name = quest_manager_name
			else:
				if not quest_manager_path.is_empty():
					target_name = quest_manager_path.trim_prefix(quest_manager_path.get_base_dir().path_join("/"))
				else:
					target_name = "Manager"
			target_name = target_name + ":" + String.num_uint64(quest_manager_id)

			# Create the associated tree_item and add it as metadata against the tree itself so that we can extract it easily when we receive messages from this specific QuestManager instance id
			var quest_manager_tree_item : TreeItem = quest_manager_viewer_manager_selection_tree_.create_item()
			quest_manager_tree_item.set_text(column, target_name)
			_m_remote_quest_manager_id_to_tree_item_map_cache[quest_manager_id] = quest_manager_tree_item

			# Store a local QuestManager as metadata -- reuse one if provided.
			var quest_manager : QuestManager = QuestManager.new()
			quest_manager_tree_item.set_metadata(column, quest_manager)
			return true

		"quest_manager:set_name":
			var quest_manager_id : int = p_data[0]
			var quest_manager_tree_item : TreeItem = _m_remote_quest_manager_id_to_tree_item_map_cache[quest_manager_id]
			var remote_name : String = p_data[1]
			quest_manager_tree_item.set_text(column, remote_name)
			return true

		"quest_manager:sync_entry":
			var quest_manager_id : int = p_data[0]
			var quest_manager_tree_item : TreeItem = _m_remote_quest_manager_id_to_tree_item_map_cache[quest_manager_id]
			var stored_quest_manager : QuestManager = quest_manager_tree_item.get_metadata(column)

			# Inject the remote quest entry data:
			var remote_quest_entry_id : int = p_data[1]
			var remote_quest_entry_data : Dictionary = p_data[2]
			stored_quest_manager.__inject(remote_quest_entry_id, remote_quest_entry_data)

			# Refresh the quest entries if needed:
			__refresh_quest_entries_if_needed(stored_quest_manager)
			return true

		"quest_manager:sync_why_cant_be_accepted":
			var quest_manager_id : int = p_data[0]
			var quest_manager_tree_item : TreeItem = _m_remote_quest_manager_id_to_tree_item_map_cache[quest_manager_id]
			var stored_quest_manager : QuestManager = quest_manager_tree_item.get_metadata(column)
			var remote_quest_entry_id : int = p_data[1]
			var remote_reasons : Array = p_data[2]

			# Inject the remote reasons as metadata within the QuestManager so that we can extract these later if required
			var why_cant_be_accepted_meta_key : StringName = StringName("_quest_id_%d_why_cant_be_accepted" % remote_quest_entry_id)
			stored_quest_manager.set_meta(why_cant_be_accepted_meta_key, remote_reasons)

			# Refresh the quest entries if needed:
			__refresh_quest_entries_if_needed(stored_quest_manager)
			return true

		"quest_manager:sync_why_cant_be_rejected":
			var quest_manager_id : int = p_data[0]
			var quest_manager_tree_item : TreeItem = _m_remote_quest_manager_id_to_tree_item_map_cache[quest_manager_id]
			var stored_quest_manager : QuestManager = quest_manager_tree_item.get_metadata(column)
			var remote_quest_entry_id : int = p_data[1]
			var remote_reasons : Array = p_data[2]

			# Inject the remote reasons as metadata within the QuestManager so that we can extract these later if required
			var why_cant_be_rejected_meta_key : StringName = StringName("_quest_id_%d_why_cant_be_rejected" % remote_quest_entry_id)
			stored_quest_manager.set_meta(why_cant_be_rejected_meta_key, remote_reasons)

			# Refresh the quest entries if needed:
			__refresh_quest_entries_if_needed(stored_quest_manager)
			return true

		"quest_manager:sync_why_cant_be_completed":
			var quest_manager_id : int = p_data[0]
			var quest_manager_tree_item : TreeItem = _m_remote_quest_manager_id_to_tree_item_map_cache[quest_manager_id]
			var stored_quest_manager : QuestManager = quest_manager_tree_item.get_metadata(column)
			var remote_quest_entry_id : int = p_data[1]
			var remote_reasons : Array = p_data[2]

			# Inject the remote reasons as metadata within the QuestManager so that we can extract these later if required
			var why_cant_be_completed_meta_key : StringName = StringName("_quest_id_%d_why_cant_be_completed" % remote_quest_entry_id)
			stored_quest_manager.set_meta(why_cant_be_completed_meta_key, remote_reasons)

			# Refresh the quest entries if needed:
			__refresh_quest_entries_if_needed(stored_quest_manager)
			return true

		"quest_manager:sync_why_cant_be_failed":
			var quest_manager_id : int = p_data[0]
			var quest_manager_tree_item : TreeItem = _m_remote_quest_manager_id_to_tree_item_map_cache[quest_manager_id]
			var stored_quest_manager : QuestManager = quest_manager_tree_item.get_metadata(column)
			var remote_quest_entry_id : int = p_data[1]
			var remote_reasons : Array = p_data[2]

			# Inject the remote reasons as metadata within the QuestManager so that we can extract these later if required
			var why_cant_be_failed_meta_key : StringName = StringName("_quest_id_%d_why_cant_be_failed" % remote_quest_entry_id)
			stored_quest_manager.set_meta(why_cant_be_failed_meta_key, remote_reasons)

			# Refresh the quest entries if needed:
			__refresh_quest_entries_if_needed(stored_quest_manager)
			return true

		"quest_manager:sync_why_cant_be_canceled":
			var quest_manager_id : int = p_data[0]
			var quest_manager_tree_item : TreeItem = _m_remote_quest_manager_id_to_tree_item_map_cache[quest_manager_id]
			var stored_quest_manager : QuestManager = quest_manager_tree_item.get_metadata(column)
			var remote_quest_entry_id : int = p_data[1]
			var remote_reasons : Array = p_data[2]

			# Inject the remote reasons as metadata within the QuestManager so that we can extract these later if required
			var why_cant_be_canceled_meta_key : StringName = StringName("_quest_id_%d_why_cant_be_canceled" % remote_quest_entry_id)
			stored_quest_manager.set_meta(why_cant_be_canceled_meta_key, remote_reasons)

			# Refresh the quest entries if needed:
			__refresh_quest_entries_if_needed(stored_quest_manager)
			return true
	push_warning("QuestManagerViewer: This should not happen. Unmanaged capture: %s %s" % [p_message, p_data])
	return false
# ==== EDITOR DEBUGGER PLUGIN PASSTHROUGH FUNCTIONS ENDS ======


# ===== VISUALIZATION FUNCTIONS BEGIN ====
func __on_session_started() -> void:
	# Clear all the caches
	_m_remote_quest_manager_id_to_tree_item_map_cache.clear()
	_m_quest_id_to_tree_item_map_cache.clear()

	# Clear the quest manager tree
	quest_manager_viewer_manager_selection_tree_.clear()
	var _root : TreeItem = quest_manager_viewer_manager_selection_tree_.create_item() # need to recreate the root TreeItem which gets ignored

	# Clear the quest entry tree view
	quest_manager_viewer_quest_entries_tree_.clear()
	quest_manager_viewer_quest_entries_view_warning_label_.set_text("Select a QuestManager to display its quest entries.")
	quest_manager_viewer_quest_entries_view_warning_label_.show()

	# Clear the data view
	quest_manager_viewer_quest_data_view_text_edit_.set_text("")
	quest_manager_viewer_quest_data_view_warning_label_.set_text("Select a QuestEntry to display its data.")
	quest_manager_viewer_quest_data_view_warning_label_.show()

	# Clear the metadata view
	quest_manager_viewer_quest_metadata_view_text_edit_.set_text("")
	quest_manager_viewer_quest_metadata_view_warning_label_.set_text("Select a QuestEntry to display its metadata.")
	quest_manager_viewer_quest_metadata_view_warning_label_.show()

func __on_session_stopped() -> void:
	if not is_instance_valid(quest_manager_viewer_manager_selection_tree_.get_root()) or quest_manager_viewer_manager_selection_tree_.get_root().get_child_count() == 0:
		quest_manager_viewer_quest_entries_view_warning_label_.set_text(_m_original_quest_entry_view_warning_text)
	if not is_instance_valid(quest_manager_viewer_quest_entries_tree_.get_root()) or quest_manager_viewer_quest_entries_tree_.get_root().get_child_count() == 0:
		quest_manager_viewer_quest_metadata_view_warning_label_.set_text(_m_original_quest_metadata_view_warning_text)


func __on_quest_manager_selection_line_edit_text_changed(p_filter : String) -> void:
	# Hide the TreeItem that don't match the filter
	var root : TreeItem = quest_manager_viewer_manager_selection_tree_.get_root()
	var column : int = 0
	for child : TreeItem in root.get_children():
		if p_filter.is_empty() or p_filter in child.get_text(column):
			child.set_visible(true)
		else:
			child.set_visible(false)

	# Select an item (if any):
	quest_manager_viewer_manager_selection_tree_.deselect_all()
	var did_select_item : bool = false
	for child : TreeItem in root.get_children():
		if child.is_visible():
			quest_manager_viewer_manager_selection_tree_.set_selected(child, column) # emits item_selected signal
			child.select(column) # highlights the item on the Tree
			did_select_item = true
			break
	if not did_select_item:
		__on_quest_manager_selection_tree_nothing_selected()


func __on_quest_manager_selection_tree_nothing_selected() -> void:
	# Deselect
	quest_manager_viewer_manager_selection_tree_.deselect_all()

	# Clear the quest view
	quest_manager_viewer_quest_entries_tree_.clear()
	quest_manager_viewer_quest_entries_view_warning_label_.set_text("Select a QuestManager to display its quest entries.")
	quest_manager_viewer_quest_entries_view_warning_label_.show()

	# Clear the data view
	quest_manager_viewer_quest_data_view_text_edit_.set_text("")
	quest_manager_viewer_quest_data_view_warning_label_.set_text("Select a QuestEntry to display its data.")
	quest_manager_viewer_quest_data_view_warning_label_.show()

	# Clear the metadata view
	quest_manager_viewer_quest_metadata_view_text_edit_.set_text("")
	quest_manager_viewer_quest_metadata_view_warning_label_.set_text("Select a QuestEntry to display its metadata.")
	quest_manager_viewer_quest_metadata_view_warning_label_.show()


func __refresh_quest_entries_if_needed(p_updated_quest_manager : QuestManager) -> void:
	var selected_tree_item : TreeItem = quest_manager_viewer_manager_selection_tree_.get_selected()
	if is_instance_valid(selected_tree_item):
		var column : int = 0
		var stored_quest_manager : QuestManager = selected_tree_item.get_metadata(column)
		if p_updated_quest_manager == stored_quest_manager:
			__refresh_quest_entries()


func __refresh_quest_entries() -> void:
	# Populate quest entries

	# Update quest view warning label:
	if quest_manager_viewer_quest_entries_view_warning_label_.is_visible():
		quest_manager_viewer_quest_entries_view_warning_label_.hide()

	# Grab the selected tree item and quest manager:
	var quest_manager_selected_tree_item : TreeItem = quest_manager_viewer_manager_selection_tree_.get_selected()
	var column : int = 0
	var quest_manager : QuestManager = quest_manager_selected_tree_item.get_metadata(column)

	# Clear the quest selection tree as well
	var selected_quest_id : int = -1 # -1 is used as a sentinel value -- quest IDs begin at 0
	if not _m_quest_id_to_tree_item_map_cache.is_empty():
		var quest_entry_selected_tree_item : TreeItem = quest_manager_viewer_quest_entries_tree_.get_selected()
		if is_instance_valid(quest_entry_selected_tree_item):
			selected_quest_id = _m_quest_id_to_tree_item_map_cache.find(quest_entry_selected_tree_item)
	quest_manager_viewer_quest_entries_tree_.clear()
	var _root : TreeItem = quest_manager_viewer_quest_entries_tree_.create_item()

	# Traverse all the top level quests and add them to the tree:
	var _new_size : int = _m_quest_id_to_tree_item_map_cache.resize(quest_manager.size())
	for topmost_quest_id : int in quest_manager.size():
		var quest_entry : QuestEntry = quest_manager.get_quest(topmost_quest_id)
		if not quest_entry.has_parent():
			# Recursively inject each subquest reference with its data if any:
			var quest_id_stack : Array = [topmost_quest_id]
			while not quest_id_stack.is_empty():
				# Process loop variable:
				var quest_id : int = quest_id_stack.pop_back()
				var quest : QuestEntry = quest_manager.get_quest(quest_id)
				if quest.has_subquests():
					var subquests_ids : Array = quest.get_subquests_ids()
					subquests_ids.reverse() # Reverse the order so that the TreeItems show in the right order
					quest_id_stack.append_array(subquests_ids)

				# Get the associated tree item
				var quest_tree_item : TreeItem
				if not quest.has_parent():
					# Need to create a new TreeItem at the root level -- this is a topmost quest
					var parent_tree_item : TreeItem = quest_manager_viewer_quest_entries_tree_.get_root()
					quest_tree_item = quest_manager_viewer_quest_entries_tree_.create_item(parent_tree_item)
				else:
					# The parent has been previously installed due to how the quest IDs are defined (they start at 0 and increment from there, and parent quests always appear before their children) -- fetch the associated TreeItem
					var parent_id : int = quest.get_parent().get_id()
					var parent_tree_item : TreeItem = _m_quest_id_to_tree_item_map_cache[parent_id]
					quest_tree_item = quest_manager_viewer_quest_entries_tree_.create_item(parent_tree_item)

				# Install the quest tooltip:
				var quest_title : String = quest.get_title()
				if quest_title.is_empty():
					quest_title = "(Empty Title)"
				var quest_description : String = quest.get_description()
				if quest_description.is_empty():
					quest_description = "(Empty Description)"
				quest_tree_item.set_text(column, quest_title)
				var tooltip_string : String = "ID: %d\n" % quest_id
				tooltip_string += "Description: %s\n" % quest_description
				tooltip_string += "Is Active %s\n" % quest.is_active()
				tooltip_string += "Is Accepted: %s\n" % quest.is_accepted()
				tooltip_string += "Is Rejected: %s\n" % quest.is_rejected()
				tooltip_string += "Is Completed: %s\n" % quest.is_completed()
				tooltip_string += "Is Failed: %s\n" % quest.is_failed()
				tooltip_string += "Is Canceled: %s\n" % quest.is_canceled()
				quest_tree_item.set_tooltip_text(column, tooltip_string)

				# Store the quest manager and quest ID on its tree item so that we can retrieve its data easily later.
				# We shouldn't store the QuestEntry directly as metadata because the quest entry data will get deprecated/detached upon a quest_manager:sync_entry message
				var quest_tree_item_metadata : Array = [quest_manager, quest_id]
				quest_tree_item.set_metadata(column, quest_tree_item_metadata)

				# Also map the quest id to their tree items - we need this to figure out the TreeItems parent/child relationships
				_m_quest_id_to_tree_item_map_cache[quest_id] = quest_tree_item

	# Store the quest_id_to_tree_item_map -- this will be needed the next time we refresh the quest entries
	if selected_quest_id >= 0:
		if _m_quest_id_to_tree_item_map_cache.has(selected_quest_id):
			var tree_item_to_select : TreeItem = _m_quest_id_to_tree_item_map_cache[selected_quest_id]
			tree_item_to_select.select(column)
		else:
			__on_quest_view_selection_nothing_selected()


func __on_quest_manager_selection_tree_item_selected() -> void:
	var selected_tree_item : TreeItem = quest_manager_viewer_manager_selection_tree_.get_selected()
	if is_instance_valid(selected_tree_item):
		__refresh_quest_entries()


func __on_quest_view_selection_nothing_selected() -> void:
	if quest_manager_viewer_quest_entries_tree_.get_selected_column() != -1:
		# Deselect the quest
		quest_manager_viewer_quest_entries_tree_.deselect_all()

		# Clear the data view
		quest_manager_viewer_quest_data_view_text_edit_.set_text("")
		quest_manager_viewer_quest_data_view_warning_label_.set_text("Select a QuestEntry to display its data.")
		quest_manager_viewer_quest_data_view_warning_label_.show()

		# Clear the metadata view
		quest_manager_viewer_quest_metadata_view_text_edit_.set_text("")
		quest_manager_viewer_quest_metadata_view_warning_label_.set_text("Select a QuestEntry to display its metadata.")
		quest_manager_viewer_quest_metadata_view_warning_label_.show()


func __on_quest_view_selection_item_selected() -> void:
	var selected_tree_item : TreeItem = quest_manager_viewer_quest_entries_tree_.get_selected()
	if is_instance_valid(selected_tree_item):
		if quest_manager_viewer_quest_data_view_warning_label_.is_visible():
			quest_manager_viewer_quest_data_view_warning_label_.hide()

		var column : int = 0
		var quest_tree_item_metadata : Array = selected_tree_item.get_metadata(column)
		var quest_manager : QuestManager = quest_tree_item_metadata[0]
		var quest_id : int = quest_tree_item_metadata[1]
		var quest : QuestEntry = quest_manager.get_quest(quest_id)

		# Update the data view
		var data_view : String = ""
		data_view += "ID: %d\n" % quest_id
		data_view += "Description: %s\n" % quest.get_description()
		data_view += "\n"
		data_view += "Is Active: %s\n" % quest.is_active()
		data_view += "\n"

		data_view += "Is Accepted: %s\n" % quest.is_accepted()
		var why_cant_be_accepted_meta_key : StringName = StringName("_quest_id_%d_why_cant_be_accepted" % quest_id)
		var not_accepted_reasons : Array = quest_manager.get_meta(why_cant_be_accepted_meta_key, [])
		data_view += "Can Be Accepted: %s\n" % str(not_accepted_reasons.is_empty())
		var acceptance_conditions : Array = quest.get_acceptance_conditions()
		if not acceptance_conditions.is_empty():
			data_view += "Acceptance Conditions: %s\n" % JSON.stringify(acceptance_conditions, "\t").strip_edges(true,true)
		if not not_accepted_reasons.is_empty():
			data_view += "Why can't be accepted?: %s\n" % JSON.stringify(not_accepted_reasons, "\t").strip_edges(true,true)
		data_view += "\n"

		data_view += "Is Rejected: %s\n" % str(quest.is_rejected())
		var why_cant_be_rejected_meta_key : StringName = StringName("_quest_id_%d_why_cant_be_rejected" % quest_id)
		var not_rejected_reasons : Array = quest_manager.get_meta(why_cant_be_rejected_meta_key, [])
		data_view += "Can Be Rejected: %s\n" % str(not_rejected_reasons.is_empty())
		var rejection_conditions : Array = quest.get_rejection_conditions()
		if not rejection_conditions.is_empty():
			data_view += "Rejection Conditions: %s\n" % JSON.stringify(rejection_conditions, "\t").strip_edges(true,true)
		if not not_rejected_reasons.is_empty():
			data_view += "Why can't be rejected?: %s\n" % JSON.stringify(not_rejected_reasons, "\t").strip_edges(true,true)
		data_view += "\n"

		data_view += "Is Completed: %s\n" % str(quest.is_completed())
		var why_cant_be_completed_meta_key : StringName = StringName("_quest_id_%d_why_cant_be_completed" % quest_id)
		var not_completed_reasons : Array = quest_manager.get_meta(why_cant_be_completed_meta_key, [])
		data_view += "Can Be Completed: %s\n" % str(not_completed_reasons.is_empty())
		var completion_conditions : Array = quest.get_completion_conditions()
		if not completion_conditions.is_empty():
			data_view += "Completion Conditions: %s\n" % JSON.stringify(completion_conditions, "\t").strip_edges(true,true)
		if not not_completed_reasons.is_empty():
			data_view += "Why can't be completed?: %s\n" % JSON.stringify(not_completed_reasons, "\t").strip_edges(true,true)
		data_view += "\n"

		data_view += "Is Failed: %s\n" % str(quest.is_failed())
		var why_cant_be_failed_meta_key : StringName = StringName("_quest_id_%d_why_cant_be_failed" % quest_id)
		var not_failed_reasons : Array = quest_manager.get_meta(why_cant_be_failed_meta_key, [])
		data_view += "Can Be Failed: %s\n" % str(not_failed_reasons.is_empty())
		var failure_conditions : Array = quest.get_failure_conditions()
		if not failure_conditions.is_empty():
			data_view += "Failure Conditions: %s\n" % JSON.stringify(failure_conditions, "\t").strip_edges(true,true)
		if not not_failed_reasons.is_empty():
			data_view += "Why can't be failed?: %s\n" % JSON.stringify(not_failed_reasons, "\t").strip_edges(true,true)
		data_view += "\n"

		data_view += "Is Canceled: %s\n" % str(quest.is_canceled())
		var why_cant_be_canceled_meta_key : StringName = StringName("_quest_id_%d_why_cant_be_canceled" % quest_id)
		var not_canceled_reasons : Array = quest_manager.get_meta(why_cant_be_canceled_meta_key, [])
		data_view += "Can Be Canceled: %s\n" % str(not_canceled_reasons.is_empty())
		var cancelation_conditions : Array = quest.get_cancelation_conditions()
		if not cancelation_conditions.is_empty():
			data_view += "Cancelation Conditions: %s\n" % JSON.stringify(cancelation_conditions, "\t").strip_edges(true,true)
		if not not_canceled_reasons.is_empty():
			data_view += "Why can't be canceled?: %s\n" % JSON.stringify(not_canceled_reasons, "\t").strip_edges(true,true)

		quest_manager_viewer_quest_data_view_text_edit_.set_text(data_view.strip_edges(true,true))

		# Update the metadata view
		if not quest.has_metadata():
			quest_manager_viewer_quest_metadata_view_text_edit_.set_text("")
			quest_manager_viewer_quest_metadata_view_warning_label_.set_text("(Empty Metadata)")
			quest_manager_viewer_quest_metadata_view_warning_label_.show()
		else:
			quest_manager_viewer_quest_metadata_view_warning_label_.hide()
			var quest_metadata : Dictionary = quest.get_metadata_data()
			var prettified_metadata : String = JSON.stringify(quest_metadata, "\t").strip_edges(true,true)
			quest_manager_viewer_quest_metadata_view_text_edit_.set_text(prettified_metadata)
# ===== VISUALIZATION FUNCTIONS END ====
