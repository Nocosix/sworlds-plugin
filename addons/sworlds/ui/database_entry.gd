#Copyright (c) 2023 ewo gameing
#Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
@tool
extends Button

var label: RichTextLabel
var title: String = "DEFAULT NAME"
var last_modified: String = "01/01/1970"
var filename: String = ""

signal update(value: String)

func update_text():
	update.emit("Name: " + title + "\nLast Modified: " + last_modified)
	
func set_thumbnail(base64: String):
	if(base64 == ""):
		push_error("Empty thumbnail")
		return
	var byte_array: PackedByteArray = Marshalls.base64_to_raw(base64)
	var image: Image = Image.new()
	#apparently jpg is the norm here
	if (image.load_jpg_from_buffer(byte_array) != OK):
		if(image.load_png_from_buffer(byte_array) != OK):
			push_error("Unable to decode thumbnail")
			return
	var texture_rect := $HBoxContainer/TextureRect
	texture_rect.texture = ImageTexture.create_from_image(image)

func set_title(value: String):
	title = value
	update_text()
	
func set_modified(value: int):
	#for some reason using get_date_string_from_unix_time was hanging godot
	#hopefully that will get fixed? for now, unix timestamp
	last_modified = str(value)
	update_text()

func _ready():
	label = get_node("HBoxContainer/RichTextLabel")
