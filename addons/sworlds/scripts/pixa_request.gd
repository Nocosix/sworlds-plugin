#Copyright (c) 2023 ewo gameing
#Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
@tool
class_name PixaRequest extends HTTPRequest

#thinking about renaming this class and making it handle the mesh table
#and all the custom images
#not sure how I want to handle this?
#i kind of want to have a signal that goes back to each of the placeables
#and then one back to the plugin when they're all done
#maybe have one instance of this, given out by the sworld
#var download_queue: Array = []
#var mesh_queue: Array = []

#want to rename this so it works for more api things

func download_pixa_id(pixa_id: String) -> Error:
	if(pixa_id == "0" or pixa_id == "-1"):
		push_warning("Trying to download invalid PixaID, this shouldn't happen.")
		return FAILED
	var response: Array
	var url: String
	var filename: String
	var pixa_dir: String = ProjectSettings.get_setting("sworlds/pixa_folder")
	print("Downloading Pixabay ID " + pixa_id + "...")
	request("https://sokpop.co/api/sokworlds/getImageUrl.php?pixabay_id=" + pixa_id)
	response = await request_completed
	url = JSON.parse_string(response[3].get_string_from_utf8())["image_url"]
	filename = pixa_dir + "/" + pixa_id + "." + url.get_extension()
	download_file = filename
	request(url)
	response = await request_completed
	download_file = ""
	if(response[0] == RESULT_SUCCESS):
		return OK
	else:
		return FAILED
