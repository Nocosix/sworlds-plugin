#Copyright (c) 2023 ewo gameing
#Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
@tool
class_name Placeable extends MeshInstance3D

const DEFAULT_MESH = preload("res://addons/sworlds/resources/default_mesh.tres")

@export var pixa_id: String = "0"
@export_file var custom_data: String = ""

#this function will get the pixa texture, if it has been downloaded and imported
func get_pixa_texture() -> Texture2D:
	var pixa_dir: String = ProjectSettings.get_setting("sworlds/pixa_folder")
	if(pixa_id == "0" or pixa_id == "-1"):
		push_warning("Invalid placeable with Pixa ID " + pixa_id + " and no custom data.")
		return preload("res://addons/sworlds/resources/default_texture.png")
	if(FileAccess.file_exists(pixa_dir + "/" + pixa_id + ".png")):
		return load(pixa_dir + "/" + pixa_id + ".png")
	if(FileAccess.file_exists(pixa_dir + "/" + pixa_id + ".jpg")):
		return load(pixa_dir + "/" + pixa_id + ".jpg")
	push_warning("No texture found for Pixa ID " + pixa_id + ".")
	return preload("res://addons/sworlds/resources/default_texture.png")

func update_mesh():
	var pixa_dir: String = ProjectSettings.get_setting("sworlds/pixa_folder")
	var mesh_dir: String = ProjectSettings.get_setting("sworlds/mesh_folder")
	var mesh_path: String
	if(custom_data == ""):
		mesh_path = mesh_dir + "/" + pixa_id + ".res"
	else:
		mesh_path = mesh_dir + "/" + custom_data.get_file().get_basename() + ".res"
		
	if(FileAccess.file_exists(mesh_path)):
		#not using .duplicate() because they should all be the same anyway?
		#might want to turn it on if you are messing with the prefab
		#otherwise it may use a cached copy
		mesh = load(mesh_path)
		#mesh = load(mesh_path).duplicate()
		return
	#now to actually create the mesh if needed
	var texture: Texture2D
	if(custom_data == ""):
		texture = get_pixa_texture()
	else:
		texture = load(custom_data)
	mesh = DEFAULT_MESH.duplicate(true)
	#squishing it down to the image's correct aspect ratio
	#assumes DEFAULT_MESH is BoxMesh
	mesh.size.z *= float(texture.get_height()) / texture.get_width()
	mesh.surface_get_material(0).set_shader_parameter("tex", texture)
	ResourceSaver.save(mesh, mesh_path)
