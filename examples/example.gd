extends Node


class DebugOutput:
	func _init(message : String) -> void:
		print(message)


func _ready():
	var file = File.new()
	#file.open("res://addons/noml/examples/example.noml", File.READ)
	
	var example = """
	
	"""
	
	var data = NOML.build(example) \
		.map_native("Node2D", Node2D) \
		.map("DebugOutput", DebugOutput) \
		.map_constant("Vector2.BLO", Vector2(0, 100)) \
		.parse()
	
	print(data)

