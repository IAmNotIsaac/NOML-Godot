tool
extends EditorPlugin


func _enter_tree() -> void:
	add_autoload_singleton("NOML", "res://addons/noml/noml.gd")


func _exit_tree() -> void:
	remove_autoload_singleton("NOML")
