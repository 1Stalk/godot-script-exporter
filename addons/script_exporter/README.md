# Script Exporter

A simple Godot editor plugin that allows you to select multiple GDScript files and export their contents into a single text file or copy them directly to your clipboard.

This is very useful for:
- Sharing multiple scripts with others easily.
- Preparing code snippets for tutorials or articles.
- Feeding a collection of scripts to an AI assistant.

## Features
-   **Grouped View:** View scripts grouped by their folders.
-   **Flat View:** View all project scripts in a single list.
-   **Select All:** Quickly select or deselect all scripts.
-   **Export to File:** Concatenates all selected scripts into a single `output_scripts.txt` file in your project root (`res://`).
-   **Copy to Clipboard:** Copies the content of all selected scripts to the clipboard.
-   **Markdown Formatting:** Optionally wrap the code for each script in a `gdscript` markdown block.

## How to Use
1.  Install plugin from Godot Asset Library or by copying `addons/ScriptExporter` folder into your project.
2.  Enable plugin in `Project -> Project Settings -> Plugins`.
3.  A new menu item "Export Scripts..." will appear under "Tools" menu in the top editor bar.
4.  Click on it to open the Script Exporter window.
5.  Select cripts you want to export.
6.  Choose your desired options (like "Wrap in Markdown").
7.  Click "Save to File" or "Copy to Clipboard".

## Acknowledgements

This plugin was inspired by the idea and great UI of the [Scene Tree as Text](https://godotengine.org/asset-library/asset/3975) plugin by Cyryl Szczakowski.

Both plugins complement each other perfectly. While **Scene Tree as Text** exports the *structure* of your scenes, **Script Exporter** provides the *code* that brings those scenes to life. Using them together is a great way to get a complete snapshot of your project for sharing or analysis.

## License
This plugin is available under the MIT license. See the `LICENSE` file for more details.