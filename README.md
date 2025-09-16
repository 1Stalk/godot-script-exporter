# Godot Script Exporter Plugin
This repository contains the source code for the "Script Exporter" plugin for the Godot Engine.

This tool allows you to select multiple GDScript files from your project and export their contents into a single text file or copy them directly to your clipboard. It's very useful for sharing code or preparing it for AI assistants.

## Screenshots

**Main Window:** Select scripts, choose options, and export.
![Script Exporter Window](visuals/1.png)

**Example Output:** The exported text is cleanly formatted with headers for each script.
![Example of exported text file](visuals/2.png)

**How to Access:** The plugin is easily accessible from the `Tools` menu.
![Accessing the plugin via the Tools menu](visuals/3.png)


## Installation

1.  **(Recommended)** Find and install "Script Exporter" in the Godot Engine's Asset Library tab.
2.  **(Manual)** Download this repository, and copy the `addons/ScriptExporter` folder into the `addons` folder of your Godot project.

Then, enable the plugin in `Project -> Project Settings -> Plugins`.

## About this Repository

The actual plugin code is located in the `addons/ScriptExporter` directory. This structure is required for the Godot Asset Library. The `README.md` file in that directory contains the user-facing documentation displayed in the Asset Library.

## Acknowledgements

This plugin was inspired by the idea and great UI of the [Scene Tree as Text](https://github.com/CyrylSz/scene-tree-as-text) plugin by Cyryl Szczakowski.

In fact, both plugins complement each other perfectly. While **Scene Tree as Text** exports the *structure* of your scenes, **Script Exporter** provides the *code* that brings those scenes to life. Using them together is a great way to get a complete snapshot of your project for sharing or analysis.

## License
This project is licensed under the MIT License.