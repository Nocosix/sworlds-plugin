# sworlds-plugin
Godot plugin to import and export Wacky Worlds

To use:
- Place addons folder into the root of a Godot 4 project
- In Project > Project Settings, click on the Plugins tab and check the Enable checkbox on the sworlds plugin
- Press Project > Tools > sworld database to access the database viewer
  - Press Open as Scene to open the selected world as a scene
  - Press Save Scene to save the currently open scene to the selected world
- To create your own placeable, add a "Placeable" node to the scene, add a PixaID and/or custom data, and press "Update Mesh" in the inspector
- To manually import a world, press Project > Tools > import sworld
- To manually export the currently opened scene to a world, press Project > Tools > export sworld
- To change default folders, go into Project > Project Settings..., turn Advanced Settings on in the General tab, and scroll down to the Sworlds category

Known issues:
 - Will not look recursively for nodes, Placeables must all be direct children of the SWorld
 - Godot will allow you to unproportionally change scale, but only proportional scale is supported
