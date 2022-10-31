extends Node


class NOMLBuilder:
	const _LEXER := preload("res://addons/noml/lexer.gd")
	const _PARSER := preload("res://addons/noml/parser.gd")
	
	var _source : String
	var _mappings := {}
	
	
	func _init(source) -> void:
		_source = source
	
	
	func map(noml_name : String, type : GDScript) -> NOMLBuilder:
		if noml_name in _PARSER.BUILTIN_MAPPINGS:
			printerr("Cannot override built-in %s mapping." % noml_name)
			return self
		_mappings[noml_name] = type
		return self
	
	
	func map_native(noml_name : String, type : GDScriptNativeClass) -> NOMLBuilder:
		if noml_name in _PARSER.BUILTIN_MAPPINGS:
			printerr("Cannot override built-in %s mapping." % noml_name)
			return self
		_mappings[noml_name] = type
		return self
	
	
	func build():
		var lexer = _LEXER.new()
		var parser = _PARSER.new()
		
		var tokens = lexer.make_tokens(_source)
		var data = parser.parse(tokens, _mappings)
		
		return data


func parse(source : String) -> NOMLBuilder:
	return NOMLBuilder.new(source)
