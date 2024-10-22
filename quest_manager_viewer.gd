extends PanelContainer

@export var quest_manager_viewer_manager_selection_line_edit_ : LineEdit
@export var quest_manager_viewer_manager_selection_tree_ : Tree
@export var quest_manager_viewer_quest_selection_tree_ : Tree
@export var quest_manager_viewer_quest_entries_view_warning_label_ : Label
@export var quest_manager_viewer_quest_metadata_view_text_edit_ : TextEdit
@export var quest_manager_viewer_quest_metadata_view_warning_label_ : Label

var _m_original_quest_view_warning_text : String
var _m_original_quest_metadata_view_warning_text : String


func add_quest_manager(p_quest_manager : QuestManager) -> void:
	var column : int = 0
	# Generate name
	var target_name : String
	var quest_manager_name : String = p_quest_manager.get_name()
	if quest_manager_name.is_empty():
		target_name = "Manager" + ":" + String.num_uint64(p_quest_manager.get_instance_id())
	else:
		target_name = quest_manager_name

	# Create the associated tree_item and add it as metadata against the tree itself so that we can extract it easily when we receive messages from this specific QuestManager instance id
	var quest_manager_tree_item : TreeItem = quest_manager_viewer_manager_selection_tree_.create_item()
	quest_manager_tree_item.set_text(column, target_name)
	var meta_key : StringName = __generate_meta_key(p_quest_manager.get_instance_id())
	quest_manager_viewer_manager_selection_tree_.set_meta(meta_key, quest_manager_tree_item)

	# Store a local QuestManager as metadata -- reuse one if provided.
	quest_manager_tree_item.set_metadata(column, p_quest_manager)

	# Select the added quest manager to populate the quest entries
	quest_manager_tree_item.select.call_deferred(column)



func _ready() -> void:
	# Create the root tree on the quest manager selection tree -- we'll ignore it by default
	var _root : TreeItem = quest_manager_viewer_manager_selection_tree_.create_item()

	# Connect QuestManager tree signals
	var _success : int = quest_manager_viewer_manager_selection_tree_.item_selected.connect(__on_quest_manager_selection_tree_item_selected)
	_success = quest_manager_viewer_manager_selection_tree_.nothing_selected.connect(__on_quest_manager_selection_tree_nothing_selected)

	# Connect QuestEntry tree signals
	_success = quest_manager_viewer_quest_selection_tree_.item_selected.connect(__on_quest_view_selection_item_selected)
	_success = quest_manager_viewer_quest_selection_tree_.nothing_selected.connect(__on_quest_view_selection_nothing_selected)

	# Connect line edit for filtering the QuestManagers list
	_success = quest_manager_viewer_manager_selection_line_edit_.text_changed.connect(__on_quest_manager_selection_line_edit_text_changed)

	# Grab the original metadata warning text -- we'll need this to restore their state once the debugger session is stopped
	_m_original_quest_view_warning_text = quest_manager_viewer_quest_entries_view_warning_label_.get_text()
	_m_original_quest_metadata_view_warning_text = quest_manager_viewer_quest_metadata_view_warning_label_.get_text()


func __generate_meta_key(p_id : int) -> StringName:
	return StringName("_" + String.num_uint64(p_id))


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
	quest_manager_viewer_quest_selection_tree_.clear()

	# Clear the metadata view
	quest_manager_viewer_quest_metadata_view_text_edit_.clear()

	# Show warnings/hints
	quest_manager_viewer_quest_entries_view_warning_label_.show()
	quest_manager_viewer_quest_metadata_view_warning_label_.set_text(_m_original_quest_metadata_view_warning_text)
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
	if quest_manager_viewer_quest_selection_tree_.has_meta(&"quest_id_to_tree_item_map"):
		var quest_entry_selected_tree_item : TreeItem = quest_manager_viewer_quest_selection_tree_.get_selected()
		if is_instance_valid(quest_entry_selected_tree_item):
			var previous_quest_id_to_tree_item_map : Array = quest_manager_viewer_quest_selection_tree_.get_meta(&"quest_id_to_tree_item_map")
			selected_quest_id = previous_quest_id_to_tree_item_map.find(quest_entry_selected_tree_item)
	quest_manager_viewer_quest_selection_tree_.clear()
	var _root : TreeItem = quest_manager_viewer_quest_selection_tree_.create_item()

	# Traverse all the top level quests and add them to the tree:
	var quest_id_to_tree_item_map : Array = []
	var _new_size : int = quest_id_to_tree_item_map.resize(quest_manager.size())
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
					var parent_tree_item : TreeItem = quest_manager_viewer_quest_selection_tree_.get_root()
					quest_tree_item = quest_manager_viewer_quest_selection_tree_.create_item(parent_tree_item)
				else:
					# The parent has been previously installed due to how the quest IDs are defined (they start at 0 and increment from there, and parent quests always appear before their children) -- fetch the associated TreeItem
					var parent_id : int = quest.get_parent().get_id()
					var parent_tree_item : TreeItem = quest_manager_viewer_quest_selection_tree_.get_meta(__generate_meta_key(parent_id))
					quest_tree_item = quest_manager_viewer_quest_selection_tree_.create_item(parent_tree_item)

				# Install the quest:
				var quest_title : String = quest.get_title()
				if quest_title.is_empty():
					quest_title = "(Empty Title)"
				#quest_title = "ID %d: " % quest_id + quest_title # for debugging purposes
				var quest_description : String = quest.get_description()
				if quest_description.is_empty():
					quest_description = "(Empty Description)"
				quest_tree_item.set_text(column, quest_title)
				quest_tree_item.set_tooltip_text(column, quest_description)
				var target_metadata : Dictionary = {}
				if quest.has_metadata():
					target_metadata = quest.get_metadata_data()
				quest_tree_item.set_metadata(column, target_metadata)

				# Add the quest ID as a meta value so that we can find the quest IDs who are parents later
				quest_manager_viewer_quest_selection_tree_.set_meta(__generate_meta_key(quest_id), quest_tree_item)

				# Also map the quest id to their tree items
				quest_id_to_tree_item_map[quest_id] = quest_tree_item

	# Store the quest_id_to_tree_item_map -- this will be needed the next time we refresh the quest entries
	quest_manager_viewer_quest_selection_tree_.set_meta(&"quest_id_to_tree_item_map", quest_id_to_tree_item_map)

	# Reselect the tree item if needed:
	if quest_id_to_tree_item_map.has(selected_quest_id):
		var tree_item_to_select : TreeItem = quest_id_to_tree_item_map[selected_quest_id]
		tree_item_to_select.select(column)
	else:
		__on_quest_view_selection_nothing_selected()


func __on_quest_manager_selection_tree_item_selected() -> void:
	var selected_tree_item : TreeItem = quest_manager_viewer_manager_selection_tree_.get_selected()
	if is_instance_valid(selected_tree_item):
		__refresh_quest_entries()


func __on_quest_view_selection_nothing_selected() -> void:
	if quest_manager_viewer_quest_selection_tree_.get_selected_column() != -1:
		quest_manager_viewer_quest_selection_tree_.deselect_all()
		quest_manager_viewer_quest_metadata_view_text_edit_.clear()
		quest_manager_viewer_quest_metadata_view_warning_label_.set_text("Select a QuestEntry to display its metadata.")
		quest_manager_viewer_quest_metadata_view_warning_label_.show()


func __on_quest_view_selection_item_selected() -> void:
	var selected_tree_item : TreeItem = quest_manager_viewer_quest_selection_tree_.get_selected()
	if is_instance_valid(selected_tree_item):
		var column : int = 0
		var quest_metadata : Dictionary = selected_tree_item.get_metadata(column)
		if quest_metadata.is_empty():
			quest_manager_viewer_quest_metadata_view_text_edit_.set_text("")
			quest_manager_viewer_quest_metadata_view_warning_label_.set_text("(Empty Metadata)")
			quest_manager_viewer_quest_metadata_view_warning_label_.show()
		else:
			quest_manager_viewer_quest_metadata_view_warning_label_.hide()
			var prettified_metadata : String = JSON.stringify(quest_metadata, "\t")
			quest_manager_viewer_quest_metadata_view_text_edit_.set_text(prettified_metadata.strip_edges(true, true))
