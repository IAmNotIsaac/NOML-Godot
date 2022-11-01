extends Node


# ' = operator

# parse: value; 'EOF;
#
# value: | Int | Float | String
#        \ array
#
# array: | '[ value (', value)* ']
#        \ dictionary
#
# dictionary: | '{ value ': value (', value ': value)* '}
#             \ mapping
#
# mapping: | Identifier '( value (', value)* ')
#          | Builtin '( value (', value)* ')
#          \ error


class Iterator:
	var tokens : Array
	var index := 0
	
	
	func _init(tokens_ : Array) -> void:
		tokens = tokens_
	
	
	func curr(): # -> Token ## Token not in global scope, cant use type casting.
		if index >= tokens.size():
			return null
		return tokens[index]
	
	
	func curr_is_op(op : String) -> bool:
		var t = curr()
		if t == null: return false
		
		return t.is_op(op)
	
	
	func curr_is_literal() -> bool:
		var t = curr()
		if t == null: return false
		
		return t.is_literal()
	
	
	func curr_is_identifier() -> bool:
		var t = curr()
		if t == null: return false
		
		return t.is_literal()
	
	
	func curr_pos_start():
		var t = curr()
		if t == null: return null
		
		return t.pos_start
	
	
	func curr_pos_end():
		var t = curr()
		if t == null: return null
		
		return t.pos_end
	
	
	func next() -> void:
		index += 1

enum ArgTypes {
	INT, FLOAT, NUMBER,
	STRING,
	ARRAY,
	DICTIONARY,
}

const BUILTIN_MAPPINGS := {
	"Null": [],
	"Vector2": [ArgTypes.NUMBER, ArgTypes.NUMBER],
	"Vector3": [ArgTypes.NUMBER, ArgTypes.NUMBER, ArgTypes.NUMBER],
}


func parse(tokens : Array, mappings : Dictionary):
	var iter = Iterator.new(tokens)
	
	var value = value(iter, mappings)
	if value == null:
		return null
	
	if not iter.curr_is_op("EOF"):
		printerr("Expected end of file, got `%s`" % iter.curr())
		return null
	
	return value


func value(iter : Iterator, mappings : Dictionary):
	var token = iter.curr()
	if token == null:
		return null
	
	if token.is_literal():
		iter.next()
		return token.value
	
	return array(iter, mappings)


func array(iter : Iterator, mappings : Dictionary):
	var ps = iter.curr_pos_start()
	
	if iter.curr_is_op("["):
		var elements := []
		iter.next()
		
		if not iter.curr_is_op("]"):
			var v = value(iter, mappings)
			if v == null:
				return null
			elements.append(v)
		
		while iter.curr_is_op(","):
			iter.next()
			if iter.curr_is_op("]"):
				break
			var v = value(iter, mappings)
			if v == null:
				return null
			elements.append(v)
		
		if not iter.curr_is_op("]"):
			printerr("Expected , or ], got %s (%s): %s" % [iter.curr(), ps, ps.source_slice(iter.curr_pos_end())])
			return null
		
		iter.next()
		return elements
	
	return dictionary(iter, mappings)


func dictionary(iter : Iterator, mappings : Dictionary):
	var ps = iter.curr_pos_start()
	
	if iter.curr_is_op("{"):
		var elements := {}
		iter.next()
		
		if not iter.curr_is_op("}"):
			var k = value(iter, mappings)
			if k == null:
				return null
			
			if not iter.curr_is_op(":"):
				printerr("Expected :, got %s (%s): %s" % [iter.curr(), ps, ps.source_slice(iter.curr_pos_end())])
				return null
			
			iter.next()
			
			var v = value(iter, mappings)
			if v == null:
				return null
			
			elements[k] = v
		
		while iter.curr_is_op(","):
			iter.next()
			if iter.curr_is_op("}"):
				break
			
			var k = value(iter, mappings)
			if k == null:
				return null
			
			if not iter.curr_is_op(":"):
				printerr("Expected :, got %s (%s): %s" % [iter.curr(), ps, ps.source_slice(iter.curr_pos_end())])
				return null
			
			iter.next()
			
			var v = value(iter, mappings)
			if v == null:
				return null
			
			elements[k] = v
		
		if not iter.curr_is_op("}"):
			printerr("Expected , or }, got %s (%s): %s" % [iter.curr(), ps, ps.source_slice(iter.curr_pos_end())])
			return null
		
		iter.next()
		return elements
	
	return mapping(iter, mappings)


func mapping(iter : Iterator, mappings : Dictionary):
	var ps = iter.curr_pos_start()
	
	if iter.curr_is_identifier():
		var type = iter.curr()
		var args := []
		var property_override := {}
		
		iter.next()
		
		if not iter.curr_is_op("("):
			printerr("Expected ( and arguments for type initializing. (%s): %s" % [ps, ps.source_slice(iter.curr_pos_end())])
			return null
		
		iter.next()
		
		if not iter.curr_is_op(")"):
			var v = value(iter, mappings)
			if v == null:
				return null
			args.append(v)
		
		while iter.curr_is_op(","):
			iter.next()
			if iter.curr_is_op(")"):
				break
			var v = value(iter, mappings)
			if v == null:
				return null
			args.append(v)
		
		if not iter.curr_is_op(")"):
			printerr("Expected , or ), got %s (%s): %s" % [iter.curr(), ps, ps.source_slice(iter.curr_pos_end())])
			return null
		
		iter.next()
		
		if iter.curr_is_op("{"):
			iter.next()
			
			if not iter.curr_is_op("}"):
				if not iter.curr_is_identifier():
					printerr("Expected identifier for property override, got %s. (%s): %s" % [iter.curr(), ps, ps.source_slice(iter.curr_pos_end())])
					return
				var k = iter.curr().value
				iter.next()
				
				if not iter.curr_is_op(":"):
					printerr("Expected :, got %s (%s): %s" % [iter.curr(), ps, ps.source_slice(iter.curr_pos_end())])
					return null
				
				iter.next()
				
				var v = value(iter, mappings)
				if v == null:
					return null
				
				property_override[k] = v
			
			while iter.curr_is_op(","):
				iter.next()
				if iter.curr_is_op("}"):
					break
				
				if not iter.curr_is_identifier():
					printerr("Expected identifier for property override, got %s. (%s): %s" % [iter.curr(), ps, ps.source_slice(iter.curr_pos_end())])
					return
				var k = iter.curr().value
				iter.next()
				
				if not iter.curr_is_op(":"):
					printerr("Expected :, got %s (%s): %s" % [iter.curr(), ps, ps.source_slice(iter.curr_pos_end())])
					return null
				
				iter.next()
				
				var v = value(iter, mappings)
				if v == null:
					return null
				
				property_override[k] = v
			
			if not iter.curr_is_op("}"):
				printerr("Expected , or }, got %s (%s): %s" % [iter.curr(), ps, ps.source_slice(iter.curr_pos_end())])
				return null
			
			iter.next()
		
		if type.value in BUILTIN_MAPPINGS:
			if BUILTIN_MAPPINGS[type.value].size() != args.size():
				printerr("Expected %s args for type %s. (%s): %s" % [BUILTIN_MAPPINGS[type.value].size(), type.value, ps, ps.source_slice(iter.curr_pos_end())])
				return null
			
			var i := 0
			for t in BUILTIN_MAPPINGS[type.value]:
				var expectation := ""
				var v = args[i]
				i += 1
				
				match t:
					ArgTypes.INT:
						if not v is int:
							expectation = "int"
					
					ArgTypes.FLOAT:
						if v is float:
							expectation = "float"
					
					ArgTypes.NUMBER:
						if not (v is int or v is float):
							expectation = "int or float"
					
					ArgTypes.STRING:
						if not v is String:
							expectation = "String"
					
					ArgTypes.ARRAY:
						if not v is Array:
							expectation = "Array"
					
					ArgTypes.DICTIONARY:
						if not v is Dictionary:
							expectation = "Dictionary"
				
				if expectation:
					printerr("Types on constructor and initialization do not match. Expected %s, got %s" % [expectation, v])
					return
		
		match type.value:
			"Null": return null
			"Vector2": return Vector2(args[0], args[1])
			"Vector3": return Vector3(args[0], args[1], args[2])
			_:
				if not type.value in mappings:
					printerr("Type %s not defined. Consider implementing a custom mapping. (%s): %s" % [type.value, ps, ps.source_slice(iter.curr_pos_end())])
					return
				
				var obj = mappings[type.value].callv("new", args)
				
				for p in property_override:
					obj.set(p, property_override[p])
				
				return obj
	
	printerr("Expected boolean, integer, float, string, array, dictionary, or mapping, got %s (%s): %s" % [iter.curr(), ps, ps.source_slice(iter.curr_pos_end())])
	return null
