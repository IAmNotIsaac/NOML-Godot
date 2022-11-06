extends Node


class NOMLBuilder:
	const _LEXER := preload("res://addons/noml/lexer.gd")
	const _PARSER := preload("res://addons/noml/parser.gd")
	
	var _source : String
	var _mappings := {}
	var _constants := {}
	
	
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
	
	
	func map_constant(noml_name : String, value) -> NOMLBuilder:
		if noml_name in _PARSER.BUILTIN_CONSTANTS:
			printerr("Cannot override built-in %s constant" % noml_name)
		_constants[noml_name] = value
		return self
	
	
	func map_enum(noml_name : String, enum_ : Dictionary) -> NOMLBuilder:
		for k in enum_.keys():
			var const_name := "%s.%s" % [noml_name, k]
			
			if _constants.has(const_name) or _PARSER.BUILTIN_CONSTANTS.has(const_name):
				printerr("Enums are supported through constants, but constant %s already exists. Enum %s not mapped." % [const_name, noml_name])
				return self
		
		for k in enum_.keys():
			var const_name := "%s.%s" % [noml_name, k]
			
			_constants[const_name] = enum_[k]
		
		return self
	
	
	func parse():
		var lexer = _LEXER.new()
		var parser = _PARSER.new()
		
		var tokens = lexer.make_tokens(_source)
		var data = parser.parse(tokens, _mappings, _constants)
		
		return data


func build(source : String) -> NOMLBuilder:
	return NOMLBuilder.new(source)
