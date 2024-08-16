# Plugin Manager for Godot Projects

This is a Godot 4.3 project to create symbolic links from plugin projects to other projects. So you can edit your plugins from other projects. Projects don't need Godot 4.3 version.

⚠ Be careful when using symbolic links as it is easier to delete files. I recommend you start by reading about removing symbolic links if you don't know about.

I only have Windows to test but I use Godot methods to create symlinks. So it should be fine on macOS and Linux too.

## Organizing your projects

You must have all the plugin projects in a folder. The rest of the projects should be stored in a few different folders since the projects are not loaded recursively.

## Steps

1. Run the project and press `Settings` button.
2. Set the plugin dir in plugins row. You can add other rows with your different folders that contains projects. Press `Save` button to save the settings and tap outside the modal to close it.
3. Press `Import Plugins` button to import the plugins.
4. Now you can click on a project and select plugins to link. After press `Link Plugins` to create symbolic links in your projects.

You should add to `.gitignore` the symlinks to prevent paths from being displayed.

## Removing symbolic links

You cannot remove symbolic links from this project. You must remove symbolic links according to your operating system. Never delete them from the Godot editor as it will delete the source folder as well.
