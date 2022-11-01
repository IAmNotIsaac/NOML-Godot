extends Node


class DebugOutput:
	func _init(message : String) -> void:
		print(message)


func _ready():
	var file = File.new()
	file.open("res://addons/noml/examples/example.noml", File.READ)
	
	var data = NOML.parse(file.get_as_text()) \
		.map_native("Node2D", Node2D) \
		.map("DebugOutput", DebugOutput) \
		.build()
	
	print(data)

