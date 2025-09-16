@tool
extends EditorPlugin

## Exports selected GDScript files from the project into a single text file or the clipboard.
## Provides options to view scripts as a flat list or grouped by folder.

# --- UI Node Variables ---
var window: Window
var status_label: Label
var scripts_list: ItemList
var select_all_checkbox: CheckBox
var group_by_folder_checkbox: CheckBox

# --- State Variables ---
var wrap_in_markdown: bool = false
var group_by_folder: bool = false
var all_script_paths: Array = []
# A dictionary that holds the state (checked, expanded) for each folder and its scripts.
# Structure: { "res://path/to/folder": { "is_expanded": bool, "is_checked": bool, "scripts": { "res://path/to/script.gd": { "is_checked": bool } } } }
var folder_data: Dictionary = {}

# --- Style Constants ---
const SAVE_BUTTON_COLOR = Color("#2e6b2e")
const SAVE_SUCCESS_TEXT_COLOR = Color("#46a946")
const COPY_BUTTON_COLOR = Color("#2e6b69")
const COPY_SUCCESS_TEXT_COLOR = Color("#4ab4b1")
const ERROR_COLOR = Color("#b83b3b")
const WARNING_COLOR = Color("#d4a53a")


#region Godot Lifecycle
#-----------------------------------------------------------------------------

func _enter_tree():
	add_tool_menu_item("Export Scripts...", Callable(self, "open_window"))
	_setup_ui()

func _exit_tree():
	remove_tool_menu_item("Export Scripts...")
	if is_instance_valid(window):
		window.queue_free()

#endregion


#region UI Setup
#-----------------------------------------------------------------------------

# --- CORRECTED FUNCTIONS ---

func _setup_ui():
	# Main Window
	window = Window.new()
	window.title = "Script Exporter"
	window.min_size = Vector2i(500, 600)
	window.size = Vector2i(500, 700)
	window.visible = false
	window.wrap_controls = true
	window.close_requested.connect(window.hide)

	# Main container with background and margins
	var main_vbox = _create_main_layout() # This now returns the VBoxContainer
	
	# The root_panel is now the single child of the window
	window.add_child(main_vbox.get_parent().get_parent())

	# Top controls: "Select All" and "Group by Folder" checkboxes
	_create_header_controls(main_vbox)

	# The main list view for scripts
	_create_script_list_view(main_vbox)

	# Bottom controls: "Markdown" checkbox, export buttons, and status label
	_create_footer_controls(main_vbox)

	get_editor_interface().get_base_control().add_child(window)

func _create_main_layout() -> VBoxContainer:
	var main_style = StyleBoxFlat.new()
	main_style.bg_color = Color("#232323")

	var root_panel = PanelContainer.new()
	root_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_panel.add_theme_stylebox_override("panel", main_style)

	var margin = MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	root_panel.add_child(margin)
	
	var main_vbox = VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(main_vbox)
	
	# This function returns the VBoxContainer that other functions will add children to.
	# The parent of the VBox is the MarginContainer, whose parent is the root_panel.
	# The root_panel will be added to the window in _setup_ui.
	return main_vbox

# --- END OF CORRECTIONS ---
# (The rest of the functions are correct and do not need to be changed)

func _create_header_controls(parent: VBoxContainer):
	var scripts_label = RichTextLabel.new()
	scripts_label.bbcode_enabled = true
	scripts_label.text = "[b][color=#d5eaf2]Select Scripts to Export:[/color][/b]"
	scripts_label.fit_content = true
	parent.add_child(scripts_label)
	
	var options_hbox = HBoxContainer.new()
	parent.add_child(options_hbox)

	select_all_checkbox = CheckBox.new()
	select_all_checkbox.text = "Select All"
	select_all_checkbox.add_theme_color_override("font_color", Color("#7ca6e2"))
	select_all_checkbox.pressed.connect(_on_select_all_toggled)
	options_hbox.add_child(select_all_checkbox)
	
	group_by_folder_checkbox = CheckBox.new()
	group_by_folder_checkbox.text = "Group by Folder"
	group_by_folder_checkbox.toggled.connect(_on_group_by_folder_toggled)
	options_hbox.add_child(group_by_folder_checkbox)
	
func _create_script_list_view(parent: VBoxContainer):
	var list_style = StyleBoxFlat.new()
	list_style.bg_color = Color("#2c3036")
	list_style.corner_radius_top_left = 3
	list_style.corner_radius_top_right = 3
	list_style.corner_radius_bottom_left = 3
	list_style.corner_radius_bottom_right = 3

	var list_panel = PanelContainer.new()
	list_panel.add_theme_stylebox_override("panel", list_style)
	list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(list_panel)

	scripts_list = ItemList.new()
	scripts_list.select_mode = ItemList.SELECT_SINGLE
	scripts_list.allow_reselect = true
	scripts_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scripts_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scripts_list.item_clicked.connect(_on_item_list_clicked)
	list_panel.add_child(scripts_list)

func _create_footer_controls(parent: VBoxContainer):
	var markdown_checkbox = CheckBox.new()
	markdown_checkbox.text = "Wrap code in Markdown (```gdscript```)"
	markdown_checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	markdown_checkbox.toggled.connect(_on_markdown_checkbox_toggled)
	parent.add_child(markdown_checkbox)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	hbox.alignment = HBoxContainer.ALIGNMENT_CENTER
	parent.add_child(hbox)
	
	var copy_button = Button.new()
	copy_button.text = "Copy to Clipboard"
	copy_button.custom_minimum_size = Vector2(150, 0)
	var copy_style = StyleBoxFlat.new()
	copy_style.bg_color = COPY_BUTTON_COLOR
	copy_button.add_theme_stylebox_override("normal", copy_style)
	copy_button.pressed.connect(_export_selected.bind(true))
	hbox.add_child(copy_button)
	
	var save_button = Button.new()
	save_button.text = "Save to File"
	save_button.custom_minimum_size = Vector2(150, 0)
	var save_style = StyleBoxFlat.new()
	save_style.bg_color = SAVE_BUTTON_COLOR
	save_button.add_theme_stylebox_override("normal", save_style)
	save_button.pressed.connect(_export_selected.bind(false))
	hbox.add_child(save_button)
	
	status_label = Label.new()
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(status_label)

#endregion


#region Data & Rendering
#-----------------------------------------------------------------------------

## Called when the plugin window is opened. Rescans files and resets state.
func open_window():
	all_script_paths = _find_files_recursive("res://", ".gd")
	all_script_paths.sort()
	_build_initial_data_model()
	_render_item_list()
	
	status_label.remove_theme_color_override("font_color")
	status_label.text = "Waiting for action..."
	window.popup_centered()

## Populates the `folder_data` dictionary based on found script paths.
func _build_initial_data_model():
	folder_data.clear()
	var folders = {}
	for path in all_script_paths:
		var dir = path.get_base_dir()
		if not folders.has(dir):
			folders[dir] = []
		folders[dir].append(path)

	for dir in folders.keys():
		folder_data[dir] = { "is_expanded": true, "is_checked": false, "scripts": {} }
		for script_path in folders[dir]:
			folder_data[dir]["scripts"][script_path] = {"is_checked": false}

## Main render dispatcher. Clears the list and calls the appropriate render method.
func _render_item_list():
	scripts_list.clear()
	if group_by_folder:
		_render_grouped_list()
	else:
		_render_flat_list()

## Renders all scripts as a single, sorted list.
func _render_flat_list():
	for path in all_script_paths:
		var is_checked = false
		var dir = path.get_base_dir()
		if folder_data.has(dir) and folder_data[dir]["scripts"].has(path):
			is_checked = folder_data[dir]["scripts"][path]["is_checked"]

		var checkbox = "☑ " if is_checked else "☐ "
		var display_text = checkbox + path.replace("res://", "")
		
		scripts_list.add_item(display_text)
		var item_index = scripts_list.get_item_count() - 1
		scripts_list.set_item_metadata(item_index, {"type": "script", "path": path})

## Renders scripts nested under their parent folders.
func _render_grouped_list():
	var sorted_folders = folder_data.keys()
	sorted_folders.sort()
	
	for dir in sorted_folders:
		var folder_info = folder_data[dir]
		var display_dir = dir.replace("res://", "")
		if display_dir == "": display_dir = "res://"

		var checkbox = "☑ " if folder_info.is_checked else "☐ "
		var expand_symbol = "▾ " if folder_info.is_expanded else "▸ "
		var display_text = expand_symbol + checkbox + display_dir

		scripts_list.add_item(display_text)
		var folder_index = scripts_list.get_item_count() - 1
		scripts_list.set_item_metadata(folder_index, {"type": "folder", "dir": dir})

		if folder_info.is_expanded:
			var sorted_scripts = folder_info.scripts.keys()
			sorted_scripts.sort()
			for script_path in sorted_scripts:
				var script_info = folder_info.scripts[script_path]
				var script_checkbox = "☑ " if script_info.is_checked else "☐ "
				var display_name = "    " + script_checkbox + script_path.get_file()
				
				scripts_list.add_item(display_name)
				var script_index = scripts_list.get_item_count() - 1
				scripts_list.set_item_metadata(script_index, {"type": "script", "path": script_path})
				
#endregion


#region Signals & Event Handlers
#-----------------------------------------------------------------------------

## Handles clicks on the ItemList to toggle checkboxes or expand/collapse folders.
func _on_item_list_clicked(index: int, at_position: Vector2, mouse_button_index: int):
	# Ignore any clicks that are not the left mouse button (e.g., scroll wheel)
	if mouse_button_index != MOUSE_BUTTON_LEFT:
		return

	var meta = scripts_list.get_item_metadata(index)
	if meta.is_empty(): return

	if meta["type"] == "folder":
		_handle_folder_click(meta, at_position)
	elif meta["type"] == "script":
		_handle_script_click(meta)

	_render_item_list()

func _handle_folder_click(meta: Dictionary, at_position: Vector2):
	var dir = meta["dir"]
	# A click on the far left of the item toggles expand/collapse.
	if at_position.x < 20:
		folder_data[dir].is_expanded = not folder_data[dir].is_expanded
	# A click anywhere else toggles the checkbox for the folder and all its children.
	else:
		folder_data[dir].is_checked = not folder_data[dir].is_checked
		for script_path in folder_data[dir].scripts:
			folder_data[dir].scripts[script_path].is_checked = folder_data[dir].is_checked
			
func _handle_script_click(meta: Dictionary):
	var path = meta["path"]
	var dir = path.get_base_dir()
	folder_data[dir].scripts[path].is_checked = not folder_data[dir].scripts[path].is_checked

	# If in grouped mode, update the parent folder's checkbox state.
	# It should be checked only if all its children are checked.
	if group_by_folder:
		var all_children_checked = true
		for script_path_in_folder in folder_data[dir].scripts:
			if not folder_data[dir].scripts[script_path_in_folder].is_checked:
				all_children_checked = false
				break
		folder_data[dir].is_checked = all_children_checked

func _on_group_by_folder_toggled(button_pressed: bool):
	group_by_folder = button_pressed
	_render_item_list()

func _on_select_all_toggled():
	var is_checked = select_all_checkbox.button_pressed
	for dir in folder_data:
		folder_data[dir].is_checked = is_checked
		for script_path in folder_data[dir].scripts:
			folder_data[dir].scripts[script_path].is_checked = is_checked
	_render_item_list()

func _on_markdown_checkbox_toggled(pressed: bool):
	wrap_in_markdown = pressed

#endregion


#region Export Logic
#-----------------------------------------------------------------------------

## Main export function, triggered by "Copy" or "Save" buttons.
func _export_selected(to_clipboard: bool):
	var selected_paths = _get_selected_script_paths()

	if selected_paths.is_empty():
		status_label.add_theme_color_override("font_color", WARNING_COLOR)
		status_label.text = "No scripts selected."
		return
		
	var content_text = _build_export_content(selected_paths)
	
	# Calculate stats for the final output
	var total_lines = content_text.split("\n").size()
	var total_chars = content_text.length()
	var stats_line = "\nTotal: %d lines, %d characters" % [total_lines, total_chars]

	if to_clipboard:
		DisplayServer.clipboard_set(content_text)
		status_label.add_theme_color_override("font_color", COPY_SUCCESS_TEXT_COLOR)
		var success_message = "Success! %d script(s) copied." % selected_paths.size()
		status_label.text = success_message + stats_line
	else:
		var output_path = "res://output_scripts.txt"
		var file = FileAccess.open(output_path, FileAccess.WRITE)
		if file:
			file.store_string(content_text)
			status_label.add_theme_color_override("font_color", SAVE_SUCCESS_TEXT_COLOR)
			var success_message = "Success! %d script(s) exported to %s" % [selected_paths.size(), output_path]
			status_label.text = success_message + stats_line
		else:
			status_label.add_theme_color_override("font_color", ERROR_COLOR)
			status_label.text = "Error writing to file!"

## Iterates through the data model to find all checked scripts.
func _get_selected_script_paths() -> Array:
	var selected_paths = []
	for dir in folder_data:
		for script_path in folder_data[dir].scripts:
			if folder_data[dir].scripts[script_path].is_checked:
				selected_paths.append(script_path)
	selected_paths.sort()
	return selected_paths

## Reads the content of each selected script and concatenates them into a single string.
func _build_export_content(paths: Array) -> String:
	var content_text = ""
	for file_path in paths:
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var content = file.get_as_text()
			content_text += "--- SCRIPT: " + file_path + " ---\n\n"
			if wrap_in_markdown:
				content_text += "```gdscript\n" + content + "\n```\n\n"
			else:
				content_text += content + "\n\n"
	return content_text

#endregion


#region Utilities
#-----------------------------------------------------------------------------

## Recursively finds all files with a given extension in a directory.
## Skips the "addons" folder to avoid including plugin scripts.
func _find_files_recursive(path: String, extension: String) -> Array:
	var files = []
	if path.begins_with("res://addons"): return files
	
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var item_name = dir.get_next()
		while item_name != "":
			if item_name == "." or item_name == "..":
				item_name = dir.get_next()
				continue
			
			var full_path = path.path_join(item_name)
			if dir.current_is_dir():
				files.append_array(_find_files_recursive(full_path, extension))
			elif item_name.ends_with(extension):
				files.append(full_path)
			
			item_name = dir.get_next()
	return files

#endregion
