tool
extends EditorPlugin


const NOMLImportHandler := preload("res://addons/noml/noml_import_handler.gd")

var import_handler := NOMLImportHandler.new()


func _enter_tree() -> void:
	add_autoload_singleton("NOML", "res://addons/noml/noml.gd")
	add_import_plugin(import_handler)


func _exit_tree() -> void:
	remove_autoload_singleton("NOML")
	remove_import_plugin(import_handler)
