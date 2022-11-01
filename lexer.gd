extends Node


class Token:
	var type : int
	var value
	var pos_start : Position
	var pos_end : Position
	
	
	func _init(type_ : int, value_, pos_start_ : Position, pos_end_ : Position) -> void:
		type = type_
		value = value_
		pos_start = pos_start_
		pos_end = pos_end_
	
	
	func _to_string() -> String:
		return "%s(%s)" % [["INT", "FLT", "STR", "IDN", "OPR", "BLN"][type], value]
	
	
	func is_literal() -> bool:
		return is_int() or is_float() or is_string() or is_boolean()
	
	
	func is_boolean() -> bool:
		return type == 5
	
	
	func is_int() -> bool:
		return type == 0
	
	
	func is_float() -> bool:
		return type == 1
	
	
	func is_string() -> bool:
		return type == 2
	
	
	func is_identifier() -> bool:
		return type == 3
	
	
	func is_op(op : String) -> bool:
		return type == 4 and value == op


class Position:
	var line := 0
	var column := 0
	var index := 0
	var source : String
	
	
	func copy() -> Position:
		var p = Position.new()
		p.line = line
		p.column = column
		p.index = index
		p.source = source
		return p
	
	
	func source_slice(until : Position) -> String:
		return source_segment(until)
		
		var start = index
		var length = until.index - index
		return source.right(start).left(length).strip_edges()
	
	
	func source_segment(until : Position) -> String:
		var start = line
		var end = until.line
		var res = ""
		
		var lines = source.split("\n")
		for line in range(start, max(end, 1)):
			res += "\n%s\t| %s" % [line + 1, lines[line]]
		
		return res
	
	
	func _to_string() -> String:
		return "Ln %s, Col %s" % [line, column]


class Iterator:
	var source : String
	var index := 0
	var pos := Position.new()
	
	
	func _init(source_ : String) -> void:
		source = source_
		pos.source = source_
	
	
	func curr() -> String:
		if index >= source.length():
			return ""
		return source[index]
	
	
	func next() -> void:
		if curr() == "\n":
			pos.line += 1
			pos.column = -1
		pos.column += 1
		pos.index += 1
		index += 1


enum TokenType {
	INTEGER,
	FLOAT,
	STRING,
	IDENTIFIER,
	OPERATOR,
	BOOLEAN
}


const NUMBERS = "1234567890."
const STRING_CAPS = "\"'"
const IDENTIFIERS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_"
const IDENTIFIERS_AND_DIGITS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"
const OPERATORS = "()[]{},:"
const COMMENT = "#"
const SIGN = "-"
const NUM_SEP = "_"


func make_tokens(source : String) -> Array:
	var tokens := []
	var iter = Iterator.new(source)
	var pos = Position.new()
	
	while iter.curr() != "":
		if iter.curr() in NUMBERS + SIGN:
			if not make_number(tokens, iter):
				return []
		elif iter.curr() in STRING_CAPS:
			if not make_string(tokens, iter):
				return []
		elif iter.curr() in IDENTIFIERS:
			if not make_identifier(tokens, iter):
				return []
		elif iter.curr() in OPERATORS:
			if not make_operator(tokens, iter):
				return []
		elif iter.curr() in " \n\t":
			iter.next()
		elif iter.curr() in COMMENT:
			comment(iter)
		else:
			printerr("Unsupported character '%s' (%s)" % [iter.curr(), iter.pos.copy()])
			return []
	
	tokens.append(Token.new(TokenType.OPERATOR, "EOF", iter.pos.copy(), iter.pos.copy()))
	
	return tokens


func make_number(tokens : Array, iter : Iterator) -> bool:
	var pstart = iter.pos.copy()
	var num = ""
	var dots = 0
	
	if iter.curr() == SIGN:
		num += SIGN
		iter.next()
	
	while iter.curr() in NUMBERS + NUM_SEP:
		if iter.curr() == ".":
			dots += 1
		elif iter.curr() == NUM_SEP:
			iter.next()
			continue
		
		num += iter.curr()
		iter.next()
	
	match dots:
		0: tokens.append(Token.new(TokenType.INTEGER, int(num), pstart, iter.pos.copy()))
		1: tokens.append(Token.new(TokenType.FLOAT, float(num), pstart, iter.pos.copy()))
		_:
			printerr("Invalid syntax, too many dots when forming number. %s: \"%s\"" % [pstart, pstart.slice(iter.pos.copy(), iter.source)])
			return false
	
	return true


func make_string(tokens : Array, iter : Iterator) -> bool:
	var pstart = iter.pos.copy()
	var string = ""
	var cap = iter.curr()
	
	iter.next()
	
	while iter.curr() != cap:
		if iter.curr() == "":
			printerr("String never terminated. %s" % pstart)
			return false
		
		string += iter.curr()
		iter.next()
	
	iter.next()
	
	tokens.append(Token.new(TokenType.STRING, string, pstart, iter.pos.copy()))
	return true


func make_identifier(tokens : Array, iter : Iterator) -> bool:
	var pstart = iter.pos.copy()
	var iname = ""
	
	while iter.curr() in IDENTIFIERS_AND_DIGITS:
		iname += iter.curr()
		iter.next()
	
	match iname:
		"true":
			tokens.append(Token.new(TokenType.BOOLEAN, true, pstart, iter.pos.copy()))
		"false":
			tokens.append(Token.new(TokenType.BOOLEAN, false, pstart, iter.pos.copy()))
		_:
			tokens.append(Token.new(TokenType.IDENTIFIER, iname, pstart, iter.pos.copy()))
	
	return true


func make_operator(tokens : Array, iter : Iterator) -> bool:
	var pstart = iter.pos.copy()
	var op = iter.curr()
	
	iter.next()
	
	tokens.append(Token.new(TokenType.OPERATOR, op, pstart, iter.pos.copy()))
	
	return true


func comment(iter : Iterator) -> void:
	while not iter.curr() in ["\n", ""]:
		iter.next()
