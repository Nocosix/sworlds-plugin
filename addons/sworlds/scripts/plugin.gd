#Copyright (c) 2023 ewo gameing
#Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
@tool
#known limitations: currently only supports SWorld as the root node
extends EditorPlugin

const DEFAULT_SCENE_DIR: String = "res://scenes"
const DEFAULT_PIXA_DIR: String = "res://textures/pixa"
const DEFAULT_CUSTOM_DIR: String = "res://textures/custom"
const DEFAULT_MESH_DIR: String = "res://textures/meshes"

var database_window: Node = preload("res://addons/sworlds/ui/database_window.scn").instantiate()

var open_file_dialog: EditorFileDialog
var save_file_dialog: EditorFileDialog

var inspector_plugin: EditorInspectorPlugin
var pixa_request: PixaRequest

#this and the next function will probably break if given non number input
func _get_color(dictionary: Dictionary, key: String, default: Color = Color(0, 0, 0)) -> Color:
	if not dictionary.has(key):
		push_warning("Unable to find " + key + ".")
		return default
	var color_dict: Dictionary = dictionary[key]
	if color_dict.has_all(["r","g","b","a"]):
		return Color(color_dict["r"], color_dict["g"], color_dict["b"], color_dict["a"])
	else:
		push_warning("Unable to parse " + key + ".")
		return default

func _get_vector3(dictionary: Dictionary, key: String, default: Vector3 = Vector3(0, 0, 0)) -> Vector3:
	var vector_dict: Dictionary = dictionary[key]
	if vector_dict.has_all(["x","y","z"]):
		return Vector3(vector_dict["x"], vector_dict["y"], vector_dict["z"])
	else:
		return default
	
#sets up an entry in project settings for a directory
func _init_dir_setting(key: String, default: String) -> void:
	if not(ProjectSettings.has_setting("sworlds/" + key)):
		ProjectSettings.set_setting("sworlds/" + key, default)
		if (not DirAccess.dir_exists_absolute(default)):
			DirAccess.make_dir_recursive_absolute(default)
	ProjectSettings.set_initial_value("sworlds/" + key, default)
	var property_info = {
		"name": "sworlds/" + key,
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_DIR
	}
	ProjectSettings.add_property_info(property_info)
		
		
func _get_dir_setting(key: String):
	return ProjectSettings.get_setting("sworlds/" + key)
	
func _force_scan():
	var resource_filesystem: EditorFileSystem = get_editor_interface().get_resource_filesystem()
	resource_filesystem.scan()
	await resource_filesystem.resources_reimported
	
	
#returns a file path to a pixa image, if none exists, returns ""
func _get_pixa_image(pixa_id: String) -> String:
	var prefix: String = _get_dir_setting("pixa_folder") + "/" + pixa_id
	if(FileAccess.file_exists(prefix + ".png")):
		return prefix + ".png"
	if(FileAccess.file_exists(prefix + ".jpg")):
		return prefix + ".jpg"
	return ""
	
#returns a file path to a custom image, if none exists, returns ""
func _get_custom_image(hash: String) -> String:
	var prefix: String = _get_dir_setting("custom_folder") + "/" + hash
	if(FileAccess.file_exists(prefix + ".png")):
		return prefix + ".png"
	if(FileAccess.file_exists(prefix + ".jpg")):
		return prefix + ".jpg"
	return ""

#decodes an image in base64 from a string
func _decode_custom_data(base64_string: String, hash: String) -> String:
	var image: Image = Image.new()
	var buffer: PackedByteArray = Marshalls.base64_to_raw(base64_string)
	var prefix: String = _get_dir_setting("custom_folder") + "/" + hash
	if(image.load_png_from_buffer(buffer) == OK):
		image.save_png(prefix + ".png")
		return prefix + ".png"
	elif(image.load_jpg_from_buffer(buffer) == OK):
		image.save_jpg(prefix + ".jpg")
		return prefix + ".jpg"
	else:
		return ""

func load_sworld(filename: String, sworld: SWorld):
	#turn this into an internal function so the file leaves scope immediately
	var file_access: FileAccess = FileAccess.open(filename, FileAccess.READ)
	if (file_access == null):
		push_error("Unable to read file.")
		return
	var dict: Dictionary = JSON.parse_string(file_access.get_as_text())
	if (dict == null):
		push_error("Unable to parse file.")
		return
	if(dict.has("SoundtrackIndex")):
		sworld.soundtrack_index = dict["SoundtrackIndex"]
	sworld.sky_color = _get_color(dict, "SkyColor", Color(0.97, 0.94, 0.89))
	sworld.floor_color = _get_color(dict, "FloorColor", Color(0.91, 0.85, 0.76))
	
	if not(dict.has("PlaceableInfos")):
		push_warning("Unable to find PlaceableInfos.")
		return
	
	var needs_scan: bool = false
	for placeable in dict["PlaceableInfos"]:
		var node: Placeable = Placeable.new()
		if(placeable.has("PixaId")):
			node.pixa_id = str(placeable["PixaId"])
			if(node.pixa_id == "0" or node.pixa_id == "-1"):
				pass
			elif(_get_pixa_image(node.pixa_id) == ""):
				if (await pixa_request.download_pixa_id(node.pixa_id) == OK):
					needs_scan = true
				else:
					push_warning("Unable to download Pixa ID " + node.pixa_id + ".")
		if(placeable.has("HasCustomData")):
			if(placeable["HasCustomData"]):
				if(placeable.has("CustomData")):
					var hash: String = placeable["CustomData"].md5_text()
					node.custom_data = _get_custom_image(hash)
					if(node.custom_data == ""):
						print("Decoding custom data with hash " + hash + ".")
						node.custom_data = _decode_custom_data(placeable["CustomData"], hash)
						if(node.custom_data == ""):
							push_warning("Unable to decode CustomData")
						else:
							needs_scan = true
				else:
					push_warning("HasCustomData is set, but could not find CustomData.")
		else:
			push_warning("Unable to find HasCustomData, assuming no CustomData.")
			
		if(sworld.has_node(node.pixa_id)):
			var count: int = 2
			while(sworld.has_node(node.pixa_id + " " + str(count))):
				count += 1
			node.name = node.pixa_id + " " + str(count)
		else:
			node.name = node.pixa_id
		
		node.position = _get_vector3(placeable, "Position")
		node.rotation_degrees = _get_vector3(placeable, "Rotation")
		node.scale = _get_vector3(placeable, "Scale", Vector3(1, 1, 1))
		#scale y is set to x in the game
		node.scale.y = node.scale.x
		#and we'll be handling the aspect ratio in the mesh instead
		node.scale.z = node.scale.x
		
		#coordinate system handedness conversion
		#i do not really understand how this works geometry-wise
		#i just kept fiddling with it until it worked correctly
		node.position.z *= -1.0
		node.rotation_degrees.y *= -1.0
		node.rotation_degrees.z *= -1.0
		node.rotation_degrees.y += 180.0
		node.rotation_degrees.z += 180.0
		
		sworld.add_child(node)
		node.owner = sworld
	if(needs_scan):
		await _force_scan()
	for node in sworld.get_children():
		if(node is Placeable):
			node.update_mesh()

func _import_sworld(in_path: String):
	var root_node: SWorld = SWorld.new()
	var id: String = in_path.get_file().get_basename()
	root_node.name = id
	await load_sworld(in_path, root_node)
	var packed_scene: PackedScene = PackedScene.new()
	packed_scene.pack(root_node)
	var out_path: String = _get_dir_setting("scene_folder") + "/" + id + ".scn"
	ResourceSaver.save(packed_scene, out_path)
	get_editor_interface().open_scene_from_path(out_path)
	
#checks the first selected node, then the root node, and
#returns the first sworld it finds, otherwise it returns null
func _get_sworld() -> Node:
	var selected: Array[Node] = get_editor_interface().get_selection().get_selected_nodes()
	if not (selected == []):
		if(selected[0] is SWorld):
			return selected[0]
	var root_node: Node = get_editor_interface().get_edited_scene_root()
	if (root_node is SWorld):
		return root_node
	for node in root_node.get_children(true):
		if(node is SWorld):
			return node
	return null

#recursively goes through node children and appends entry of dict to the list	
func _node_to_dict(node:Node, list:Array, parent_transform := Transform3D.IDENTITY):
	var transform := parent_transform
	if node is Node3D:
		transform *= node.transform
	for child in node.get_children():
		_node_to_dict(child, list, transform)
	if not node is Placeable:
		return
	var placeable = {}
	var squish: float = node.mesh.size.z/node.mesh.size.x
	placeable["PixaId"] = node.pixa_id
	placeable["Position"] = {}
	placeable["Position"]["x"] = transform.origin.x
	placeable["Position"]["y"] = transform.origin.y
	placeable["Position"]["z"] = transform.origin.z * -1.0
	#it took trial and error to figure out to orthonormalize this
	var rotation := transform.basis.orthonormalized().get_euler()
	placeable["Rotation"] = {}
	placeable["Rotation"]["x"] = rad_to_deg(rotation.x)
	placeable["Rotation"]["y"] = -1.0 * rad_to_deg(rotation.y) + 180.0
	placeable["Rotation"]["z"] = -1.0 * rad_to_deg(rotation.z) + 180.0
	placeable["Scale"] = {}
	placeable["Scale"]["x"] = transform.basis.x.length()
	placeable["Scale"]["y"] = transform.basis.y.length()
	placeable["Scale"]["z"] = transform.basis.z.length() * squish
	if (node.custom_data == ""):
		placeable["HasCustomData"] = false
		placeable["CustomData"] = ""
	else:
		placeable["HasCustomData"] = true
		placeable["CustomData"] = Marshalls.raw_to_base64(FileAccess.get_file_as_bytes(node.custom_data))
	list.append(placeable)
	
func _export_sworld(filename: String):
	var root_node: Node = _get_sworld()
	if(root_node == null):
		push_error("No SWorld found")
		return
	var sworld: Dictionary = {}
	sworld["SoundtrackIndex"] = str(root_node.soundtrack_index)
	sworld["SkyColor"] = {"r":root_node.sky_color.r,"g":root_node.sky_color.g,
							"b":root_node.sky_color.b, "a":root_node.sky_color.a}
	sworld["FloorColor"] = {"r":root_node.floor_color.r,"g":root_node.floor_color.g,
							"b":root_node.floor_color.b, "a":root_node.floor_color.a}
	sworld["PlaceableInfos"] = []
	_node_to_dict(root_node, sworld["PlaceableInfos"])
	var file = FileAccess.open(filename, FileAccess.WRITE)
	file.store_string(JSON.stringify(sworld))
	print("done!")
	
func _on_update_mesh():
	var selected: Array[Node]
	selected = get_editor_interface().get_selection().get_selected_nodes()
	for node in selected:
		if not (node is Placeable):
			continue
		if(node.custom_data != ""):
			node.update_mesh()
			continue
		if(node.pixa_id == "0" or node.pixa_id == "-1"):
			node.update_mesh()
			continue
		if(_get_pixa_image(node.pixa_id) == ""):
			var pixa_request: PixaRequest = PixaRequest.new()
			add_child(pixa_request)
			pixa_request.owner = self
			if(await pixa_request.download_pixa_id(node.pixa_id) == OK):
				await _force_scan()
			else:
				push_warning("Pixa ID " + node.pixa_id + " failed to download.")
		node.update_mesh()

func _test():
	pass

func _enter_tree():
	open_file_dialog = EditorFileDialog.new()
	open_file_dialog.size = Vector2(640, 480)
	open_file_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	open_file_dialog.file_mode = EditorFileDialog.FILE_MODE_OPEN_FILE
	get_editor_interface().get_base_control().add_child(open_file_dialog)
	open_file_dialog.file_selected.connect(_import_sworld)
	
	save_file_dialog = EditorFileDialog.new()
	save_file_dialog.size = Vector2(640, 480)
	save_file_dialog.access = EditorFileDialog.ACCESS_FILESYSTEM
	save_file_dialog.file_mode = EditorFileDialog.FILE_MODE_SAVE_FILE
	get_editor_interface().get_base_control().add_child(save_file_dialog)
	save_file_dialog.file_selected.connect(_export_sworld)
	
	get_editor_interface().get_base_control().add_child(database_window)
	database_window.open_path.connect(_import_sworld)
	database_window.save_path.connect(_export_sworld)
	
	pixa_request = PixaRequest.new()
	pixa_request.name = "PixaRequest"
	add_child(pixa_request)
	pixa_request.owner = self
	
	inspector_plugin = preload("res://addons/sworlds/scripts/inspector_plugin.gd").new()
	add_inspector_plugin(inspector_plugin)
	inspector_plugin.on_update_mesh = _on_update_mesh
#	inspector_plugin.on_import_sworld = open_file_dialog.popup_centered
#	inspector_plugin.on_export_sworld = save_file_dialog.popup_centered
	
	_init_dir_setting("scene_folder", DEFAULT_SCENE_DIR)
	_init_dir_setting("pixa_folder", DEFAULT_PIXA_DIR)
	_init_dir_setting("custom_folder", DEFAULT_CUSTOM_DIR)
	_init_dir_setting("mesh_folder", DEFAULT_MESH_DIR)

	if(OS.get_name() == "Windows"):
		#get_data_dir is %appdata% on windows
		#TODO: somehow get the ".." out of this, it looks weird in the settings
		_init_dir_setting("sokworlds_folder", OS.get_data_dir() + "\\..\\LocalLow\\sokpop\\sokworlds\\")
		#database_path = OS.get_data_dir() + "\\..\\LocalLow\\sokpop\\sokworlds\\local.sok"
	else:
		#just assuming proton on linux
		#TODO: try a few more options for wineprefix locations
		#get_data_dir is usually ~/.local/share 
		_init_dir_setting("sokworlds_folder", OS.get_data_dir() + "/Steam/steamapps/compatdata/1263820/pfx/drive_c/users/steamuser/AppData/LocalLow/sokpop/sokworlds/")
	
	if not (DirAccess.dir_exists_absolute(_get_dir_setting("sokworlds_folder"))):
		push_warning("sokworlds folder not found at the default path, can be set manually in Project Settings.")

	add_tool_menu_item("sokworlds database", database_window.open_database)
	add_tool_menu_item("import sworld", open_file_dialog.popup_centered)
	add_tool_menu_item("export sworld", save_file_dialog.popup_centered)
#	add_tool_menu_item("test", _test)

func _exit_tree():
	open_file_dialog.queue_free()
	save_file_dialog.queue_free()
	
	remove_inspector_plugin(inspector_plugin)
	
	remove_tool_menu_item("sokworlds database")
	remove_tool_menu_item("import sworld")
	remove_tool_menu_item("export sworld")
#	remove_tool_menu_item("test")
