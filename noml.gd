extends Node


class NOMLBuilder:
	const _LEXER := preload("res://addons/noml/lexer.gd")
	const _PARSER := preload("res://addons/noml/parser.gd")
	
	var _format : FieldType = FieldType.Any.new()
	var _source : String
	var _mappings := {}
	var _constants := {}
	
	
	func _init(source) -> void:
		_source = source
	
	
	func set_format(format : FieldType) -> NOMLBuilder:
		_format = format
		return self
	
	
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
	
	
	func parse(verify := true):
		var lexer = _LEXER.new()
		var parser = _PARSER.new()
		
		var tokens = lexer.make_tokens(_source)
		var data = parser.parse(tokens, _mappings, _constants)
		
		if verify:
			if not _format.matches_type(data):
				printerr("Parsed data does not accurately follow format!")
				return null
		
		return data


class FieldType:
	enum Discriminator {
		INT, FLOAT, BOOL, NOML_STRING, NOML_ARRAY, NOML_DICTIONARY, FIELDS, TYPE, NATIVE_TYPE, ANY
	}
	
	
	func get_discriminator() -> int:
		return -1
	
	
	func matches_type(value) -> bool:
		return false
	
	
	class Int extends FieldType:
		func get_discriminator() -> int:
			return Discriminator.INT
		
		func matches_type(value) -> bool:
			if value is int:
				return true
			
			printerr("Expected type int.")
			return false
	
	
	class Float extends FieldType:
		func get_discriminator() -> int:
			return Discriminator.Float
		
		func matches_type(value) -> bool:
			if value is Float:
				return true
			
			printerr("Expected type float.")
			return false
	
	
	class Bool extends FieldType:
		func get_discriminator() -> int:
			return Discriminator.BOOL
		
		func matches_type(value) -> bool:
			if value is bool:
				return true
			
			printerr("Expected type bool.")
			return false
	
	
	class NOMLString extends FieldType:
		func get_discriminator() -> int:
			return Discriminator.NOML_STRING
		
		func matches_type(value) -> bool:
			if value is String:
				return true
			
			printerr("Expected type String.")
			return false
	
	
	class NOMLArray extends FieldType:
		var _type : FieldType
		
		func _init(type : FieldType) -> void:
			_type = type
		
		func matches_type(value) -> bool:
			if not value is Array:
				printerr("Expected type Array.")
				return false
			
			if _type is FieldType.Any:
				return true
			
			for element in value:
				if not _type.matches_type(element):
					printerr("Array element type error.")
					return false
			
			return true
		
		func get_discriminator() -> int:
			return Discriminator.NOML_ARRAY
	
	
	class NOMLDictionary extends FieldType:
		var _key_type : FieldType
		var _val_type : FieldType
		
		func _init(key_type : FieldType, val_type : FieldType) -> void:
			_key_type = key_type
			_val_type = val_type
		
		func matches_type(value) -> bool:
			if not value is Dictionary:
				printerr("Expected type Dictionary.")
				return false
			
			var key_matches := _key_type is FieldType.ANY
			if not key_matches:
				for element in value.keys():
					if not _key_type.matches_type(element):
						printerr("Dictionary key type error.")
						return false
			
			var val_matches := _val_type is FieldType.ANY
			if not val_matches:
				for element in value.values():
					if not _val_type.matches_type(element):
						printerr("Dictionary value type error.")
						return false
			
			return key_matches and val_matches
		
		func get_discriminator() -> int:
			return Discriminator.NOML_DICTIONARY
	
	
	class Fields extends FieldType:
		var _req_entries := {}
		var _opt_entries := {}
		
		func req_entry(entry_name : String, entry_type : FieldType) -> Fields:
			_req_entries[entry_name] = entry_type
			return self
		
		func opt_entry(entry_name : String, entry_type : FieldType) -> Fields:
			_opt_entries[entry_name] = entry_type
			return self
		
		func matches_type(value) -> bool:
			if not value is Dictionary:
				printerr("Expected dictionary with fields format.")
				return false
			
			# VVVVV 0) ensure all user entries are strings
			# VVVVV 1) ensure all required fields are met
			# VVVVV 2) ensure no extraneous fields
			# 3) ensure all required fields' types match
			# 4) ensure all optional fields' types match
			
			var required := _req_entries.keys().duplicate()
			var user_entries : Array = value.keys().duplicate()
			
			# all user entries must be strings
			for entry in user_entries:
				if not entry is String:
					printerr("All field entry keys expected to be of type String.")
					return false
			
			# all required entries must be met
			for entry in value.keys():
				user_entries.erase(entry)
				required.erase(entry)
			
			if required.size() != 0:
				var reqstr := str(required)
				reqstr = reqstr.substr(1, reqstr.length() - 2)
				printerr("Following fields are required: %s." % reqstr)
				return false
			
			# no extraneous entries should be found
			for entry in _opt_entries.keys():
				user_entries.erase(entry)
			
			if user_entries.size() != 0:
				var extstr := str(required)
				extstr = extstr.substr(1, extstr.length() - 2)
				printerr("Extraneous entries found: %s." % extstr)
				return false
			
			# ensure all required entry type matches
			for entry in _req_entries.keys():
				if not _req_entries[entry].matches_type(value[entry]):
					return false
			
			for entry in _opt_entries.keys():
				if value.has(entry) and not _opt_entries[entry].matches_type(value[entry]):
					return false
			
			return true
		
		func get_discriminator() -> int:
			return Discriminator.FIELDS
	
	
	class Type extends FieldType:
		var _type : GDScript
		
		func _init(type : GDScript) -> void:
			_type = type
		
		func matches_type(value) -> bool:
			if value is _type:
				return true
			
			printerr("Expected type %s" % _type)
			return false
		
		func get_discriminator() -> int:
			return Discriminator.TYPE
	
	
	class NativeType extends FieldType:
		var _type
		
		func _init(type : GDScriptNativeClass):
			_type = type
		
		func matches_type(value) -> bool:
			if value is _type:
				return true
			
			printerr("Expected type %s" % _type)
			return false
		
		func get_discriminator() -> int:
			return Discriminator.NATIVE_TYPE
	
	
	class Any extends FieldType:
		func get_discriminator() -> int:
			return Discriminator.ANY
		
		func matches_type(value) -> bool:
			return true


func build(source : String) -> NOMLBuilder:
	return NOMLBuilder.new(source)
