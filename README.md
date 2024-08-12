# Plugin Manager for Godot Projects

This is a Godot 4.3 project to create symbolic links from plugin projects to other projects. So you can edit your plugins from other projects. Projects don't need Godot 4.3 version.

⚠ Be careful when using symbolic links as it is easier to delete files. I recommend you start by reading about removing symbolic links if you are not familiar.

## Organizing your projects

You must have all the plugin projects in a folder. The rest of the projects should be stored in a few different folders since the projects are not loaded recursively.

## Steps

An interface to edit categories is pending, but I don't have time to do it right now. So I've made an alternative way using a gdscript.

1. You need to create `settings.ini` with category dirs (project dirs). Edit `settings.gd` with your name-path categories and runs `settings.tscn` scene to create the file. Make sure to create a category called `plugins` that will contain all your plugins.
2. Run the project and press Import Plugins button.
3. Now you can click on a project and select plugins to link. After press `Link Plugins` to create symbolic links in your projects.

## Removing symbolic links

You cannot remove symbolic links from this project. You must remove symbolic links according to your operating system. Never delete them from the Godot editor as it will delete the source folder as well.
