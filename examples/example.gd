extends Node


class DebugOutput:
	func _init(message : String) -> void:
		print(message)


enum Options {
	A, B, C
}


func _ready():
	#var file = File.new()
	#file.open("res://addons/noml/examples/example.noml", File.READ)
	
	var format = NOML.FieldType.Fields.new() \
		.req_entry("wooh", NOML.FieldType.NOMLArray.new(NOML.FieldType.Int.new())) \
		.req_entry("bruh", NOML.FieldType.NOMLArray.new(NOML.FieldType.Int.new())) \
		.opt_entry("zoop", NOML.FieldType.NOMLArray.new(NOML.FieldType.Int.new())) \
	
	var example = """
		{
			"wooh": [0, 0, 1],
			"bruh": [0, 1, 0],
			"zoop": [1, 0, 0],
		}
	"""
	
	
	var data = NOML.build(example) \
		.set_format(format) \
		.map_native("Node2D", Node2D) \
		.map("DebugOutput", DebugOutput) \
		.map_constant("Vector2.BLO", Vector2(0, 100)) \
		.map_enum("Options", Options) \
		.parse()
	
	print(data)

