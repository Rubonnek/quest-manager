#============================================================================
#  editor_debugger_plugin.gd                                                |
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
extends EditorDebuggerPlugin


var session_id_to_quest_manager_viewer : Dictionary = {}


func _setup_session(p_session_id : int) -> void:
	# Instantiate the quest manager viewer and grab the debugger session
	var quest_manager_viewer : Control = preload("./quest_manager_viewer.tscn").instantiate()
	var editor_debugger_session : EditorDebuggerSession = get_session(p_session_id)

	# Listen to the debugger session started signal.
	@warning_ignore("unsafe_property_access", "unsafe_call_argument")
	var _success : int = editor_debugger_session.started.connect(quest_manager_viewer.__on_session_started)
	@warning_ignore("unsafe_property_access", "unsafe_call_argument")
	_success = editor_debugger_session.stopped.connect(quest_manager_viewer.__on_session_stopped)

	# Add the quest manager viewer to the debugger tabs
	editor_debugger_session.add_session_tab(quest_manager_viewer)

	# Track sessions so that we can push the data from _capture into the right session
	session_id_to_quest_manager_viewer[p_session_id] = quest_manager_viewer


func _has_capture(p_prefix : String) -> bool:
	return p_prefix == "quest_manager"


func _capture(p_message : String, p_data : Array, p_session_id : int) -> bool:
	var quest_manager_viewer : Control = session_id_to_quest_manager_viewer[p_session_id]
	@warning_ignore("unsafe_method_access")
	return quest_manager_viewer.on_editor_debugger_plugin_capture(p_message, p_data)
