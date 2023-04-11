# sworlds-plugin
Godot plugin to import and export Wacky Worlds

To use:
- Download either the release, or the entire repository as a zip
- Unzip the file and open project.godot with Godot 4.0.1 or above (or import the zip directly)
- Press Project > Tools > sworld database to access the database viewer
  - Press Open as Scene to open the selected world as a scene
  - Press Save Scene to save the currently open scene to the selected world
- To create your own placeable, add a "Placeable" node to the scene, add a PixaID and/or custom data, and press "Update Mesh" in the inspector
- To manually import a world, press Project > Tools > import sworld
- To manually export the currently opened scene to a world, press Project > Tools > export sworld
- To change default folders, go into Project > Project Settings..., turn Advanced Settings on in the General tab, and scroll down to the Sworlds category

Known issues:
 - Godot will allow you to unproportionally change scale, but only proportional scale is supported
