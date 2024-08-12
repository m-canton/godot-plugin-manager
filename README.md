# Plugin Manager for Godot Projects

This is a Godot 4.3 project to create symbolic links from plugin projects to other projects. So you can edit your plugins from other projects.

Be careful when using symbolic links as it is easier to delete files. I recommend you start by reading about removing symbolic links if you are not familiar.

## Steps

1. You need to create `settings.ini` with category dirs (project dirs). Edit `settings.gd` with your name-path categories and runs `settings.tscn` scene to create the file. Make sure to create a category called `plugins` that will contain all your plugins.
2. Run the project and press Import Plugins button.
3. Now you can click on a project and select plugins to link. After press `Link Plugins` to create symbolic links in your projects.

## Remove symbolic links

You cannot remove symbolic links from this project. You must remove symbolic links according to your operating system. Never delete them from the Godot editor as it will delete the source folder as well.
