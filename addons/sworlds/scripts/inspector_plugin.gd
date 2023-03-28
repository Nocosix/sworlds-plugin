#Copyright (c) 2023 ewo gameing
#Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
@tool
extends EditorInspectorPlugin

var update_mesh_button: Button = Button.new()
var import_sworld_button: Button = Button.new()
var export_sworld_button: Button = Button.new()
var on_update_mesh: Callable = func(): pass
var on_import_sworld: Callable = func(): pass
var on_export_sworld: Callable = func(): pass

func _init():
	update_mesh_button.text = "Update Mesh"
	import_sworld_button.text = "Import SWorld"
	export_sworld_button.text = "Export Sworld"
	#update_mesh_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	#update_mesh_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER

func _can_handle(object: Object) -> bool:
	if object is SWorld:
		return true
	if object is Placeable:
		return true
	return false


func _parse_begin(object: Object):
	if object is Placeable:
		var button: Button = update_mesh_button.duplicate()
		button.pressed.connect(on_update_mesh)
		add_custom_control(button)
#	if object is SWorld:
#		var import_button: Button = import_sworld_button.duplicate()
#		import_button.pressed.connect(on_import_sworld)
#		add_custom_control(import_button)
#		var export_button: Button = export_sworld_button.duplicate()
#		export_button.pressed.connect(on_export_sworld)
#		add_custom_control(export_button)
