#Copyright (c) 2023 ewo gameing
#Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
@tool
extends Window

var database_entry: Button = load("res://addons/sworlds/ui/database_entry.tscn").instantiate()
var button_group := ButtonGroup.new()

signal open_path(filename: String)
signal save_path(filename: String)

func button_selected(button: BaseButton):
	var line_edit: LineEdit = $Panel/VBoxContainer/HBoxContainer/SideButtons/Title
	line_edit.text = button.title

func open_database():
	var file := FileAccess.open(ProjectSettings.get_setting("sworlds/sokworlds_folder") + "/local.sok", FileAccess.READ)
	if(file == null):
		push_error("Unable to open database file")
	var database := JSON.parse_string(file.get_as_text())
	if(database == null):
		push_error("Unable to parse database file")
	if not (button_group.pressed.is_connected(button_selected)):
		button_group.pressed.connect(button_selected)
	var item_list := $Panel/VBoxContainer/HBoxContainer/ItemList/VBoxContainer
	#make sure there are no entries in there already
	for trash in item_list.get_children():
		trash.queue_free()
	for world in database["Worlds"]:
		var button := database_entry.duplicate()
		button.button_group = button_group
		button.set_title(world["Title"])
		button.set_modified(world["ModifiedAt"])
		button.filename = world["LocalFileName"]
		button.set_thumbnail(world["ThumbnailData"])
		item_list.add_child(button)
#		button.parent = item_list
	popup_centered()

func _emit_filename(selection: BaseButton, emitted:Signal) -> Error:
	if(selection == null):
		push_error("No entry selected.")
		return FAILED
	if(selection.filename == null):
		push_error("No filename in entry.")
		return FAILED
	emitted.emit(ProjectSettings.get_setting("sworlds/sokworlds_folder") + "/" + selection.filename)
	return OK

func _on_open_pressed():
	if(_emit_filename(button_group.get_pressed_button(), open_path) == OK):
		self.hide()

func _on_save_pressed():
	if(_emit_filename(button_group.get_pressed_button(), save_path) == OK):
		self.hide()
