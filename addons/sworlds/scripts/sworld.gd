#Copyright (c) 2023 ewo gameing
#Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the “Software”), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
#The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
@tool
class_name SWorld extends WorldEnvironment

var procedural_sky : ProceduralSkyMaterial

var _sky_color: Color
@export var sky_color: Color = Color(0.97, 0.94, 0.89):
	get:
		return _sky_color
	set(value):
		_sky_color = value
		procedural_sky.sky_top_color = value
		#slightly darker at the horizon
		procedural_sky.sky_horizon_color = value * Color(0.9, 0.9, 0.9)

var _floor_color: Color
@export var floor_color: Color = Color(0.91, 0.85, 0.76) :
	get:
		return _floor_color
	set(value):
		_floor_color = value
		procedural_sky.ground_bottom_color = value
		#slightly darker at the horizon
		procedural_sky.ground_horizon_color = value * Color(0.9, 0.9, 0.9)
		
@export_range(0, 8) var soundtrack_index: int = 0

func _init():
	#for whatever reason, having the default value at 0 isn't enough
	soundtrack_index = 0
	environment = preload("res://addons/sworlds/resources/default_environment.tres").duplicate(true)
	procedural_sky = environment.sky.sky_material as ProceduralSkyMaterial
