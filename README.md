# NOML-Godot
Godot implementation for Named Object Markup Language (NOML).

## Introduction
### What's NOML?
Not much.
It's a markup language I've made just because JSON is nice and easy, but there's one or two things which I don't particularly like about it. One of these, of course, being the way objects are handled, so I create a somewhat friendlier way of handling it.
NOML itself is just a standard of sorts. Any NOML implementation should include the following:
- Boolean
- Integers
- Floats
- Strings
- Arrays (lists)
- Dictionaries
- Mappings

The NOML standard is designed to be used with any, or at least, most programming languages.

As of now, NOML is only able to be interpreted, not created dynamically. I'll get there, don't worry!

### So... What's a mapping?
In NOML, a mapping is a custom type, that refers to a type in a programming language. It's an object defined in NOML that directly translates to a user defined type in something like Python, C++, Rust, or in this particular case, GDScript.

### Great. How do I use it?
###### Install
As it's currently only available as a Godot add-on, well, you'll only be able to use it in Godot. If you are using Godot, you're in luck. Simply place the root directory in the addons folder. It should look like the following:
```
My Godot Project/
 | addons/noml/
 |  | plugin.cfg
 |  | plugin.gd
 |  | noml.gd
 |  | [...]
 |
 | project.godot
 | [...]
```
You may need to restart the editor before usage.

###### Usage
Start by getting your file contents.
```GDScript
# main.gd
func read_noml():
	var file = File.new()
	file.open("res://mydata.noml", File.READ)	# make sure you've created a NOML file!

	var noml_builder = NOML.parse(file.get_as_text())		# Returns a NOMLBuilder, allowing us to create mappings
	noml_builder \
		# First we define what we want to call our type in the NOML file, then we pass in our type.
		.map_native("Node2D", Node2D) \
		# Although the name and type name don't have to match, it's usually recommended they do.
		.map_native("Body", KinematicBody2D) \	
		.build()				# When we're ready, we want to build our data.
```
Great, we've got our code. But what does our NOML file look like?
In this example, this is our NOML.
```GDScript
# mydata.noml
[
	Node2D(),
	Body() {
		name: "Player",
		position: Vector2(64, 5)	# Godot's implementation has built-in types!
	},
]
```
You can even use your own custom user-defined classes, however, you need to use the `map` method on NOML, as opposed to `map_native`. ("native" refers to godot's GDScriptNativeClass. Basically, any class that's built in to the engine, usually nodes. Anything you have to call `new` on to instantiate.)

###### Syntax
The following is the syntax of NOML under the [EBNF](https://en.wikipedia.org/wiki/Extended_Backus%E2%80%93Naur_form) standard.
```EBNF
eof = ? end of file ?
newline = ? newline character ?
char = ? all characters supported in a string ?
digit	= "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" ;
letter 	= "A" | "B" | "C" | "D" | "E" | "F" | "G"
       	| "H" | "I" | "J" | "K" | "L" | "M" | "N"
       	| "O" | "P" | "Q" | "R" | "S" | "T" | "U"
       	| "V" | "W" | "X" | "Y" | "Z" | "a" | "b"
       	| "c" | "d" | "e" | "f" | "g" | "h" | "i"
       	| "j" | "k" | "l" | "m" | "n" | "o" | "p"
       	| "q" | "r" | "s" | "t" | "u" | "v" | "w"
       	| "x" | "y" | "z" | "_" ;

comment	= "#", { char }, newline ;

int	= digit, { digit } ;
float 	= { digit }, ".", { digit } ;
ident	= letter, { letter | digit } ;
string	= '"', { char }, '"'
	| "'", { char }, "'" ;

dict	= "{", value, ":", value, { ",", value, ":", value }, [","], "}" ;
	| "{", "}" ;

array	= "[", value, { ",", value }, [","], "]"
	| "[", "]" ;

args	= ("(", value, { ",", value }, [","] ")")
	| "(", ")"

property_override
	= "{", ident, ":", value, { ",", ident, ":", value }, [","], "}" ;
	| "{", "}" ;

mapping	= ident, args, [ property override ]
	| "Vector2", "(", int | float, ",", int | float ")"
	| "Vector3", "(", int | float, ",", int | float, ",", int | float ")"

value	= int | float | string | array | dict | mapping ;
parse	= value, eof ;
```
###### English, please.
Unless you're for some reason really fluent with EBNF, you're probably gonna want an introduction. Depending on whether or not you have prior experience with stuff like JSON, you may want [a quick over-view](#a-quick-guide), or alternatively, [a real good understanding of NOML](#an-in-depth-guide).

## A guide to NOML
##### A quick guide
Okay so maybe you know a little JSON, or even a lot. To be fair, there isn't really that much to know anyways. NOML has all the types JSON has, with an additional type called a mapping. This means that you can interpret all JSON with NOML, however you may not be able to interpret all NOML as JSON.

NOML shares the same or similar formatting for all types. If you come from JSON, really all you need to get up to speed on for NOML is just mappings. Once you understand that, you're good right away! The basic gist of it is that instead of having to interpret your own objects, you can just map it. All the work is done for you, no need to write a complicated interpreter. It's just an easier way of doing things.

Additionally, it should be mentioned that NOML also has support for comments. They're pretty simple: after a #, all characters will be ignored up until a newline.

##### An in-depth guide
NOML is a language with only types. The types, as previously stated, are:
- Boolean
- Integers
- Floats
- Strings
- Arrays (lists)
- Dictionaries
- Mappings

I go over them in summary and detail [here](#types).

It's important to understand that in NOML, you're only actually allowed just one value. That's right, your entire NOML file can hold only one singular value in it. However, some of these values can hold more values, those being Arrays, Dictionaries, Mappings, and Strings if you're creative enough. This is all to say, that you could very well have a NOML file that looks just like this:
```
1
```
And you wouldn't be allowed anything more. Using the aforementioned types to allow us to hold more values, sometimes called containers, allows us to hold more information in our file, but fundamentally, we're only allowed one value at the top of our file.

Okay, now you probably don't want to just store a 1 or something like that in a file, resources are better wasted elsewhere, so often you'll be using arrays or dictionaries or something as a root value. Honestly, you could get by just fine with that, and if that's your intention, my suggestion is to just stick with JSON as there's much better support for that right now.

One bothersome thing about JSON is that due to the lack of mappings, you actually have to interpret your own objects. Of course, not impossible, or very hard even, but certainly a time waster. The purpose of NOML is namely just to make that one thing easier, so you'll find that in all other aspects, NOML is pretty much JSON. This is because JSON isn't really that bad, just a couple short-comings.

### Types
###### Boolean
A simple true or false! It can only contain be in two possible states. A true or false. A 1 or a 0.
```
# Example.noml
[
	true,
	false
]
```

###### Integers
Integers in NOML are just regular ol' whole numbers. Stuff like 1. And 2. 3, 4, 5, 6, 100, 200, 6'000'000, you get the gist. They're pretty fundamental, not much to it. They get converted into Godot integers on parse.
```
# Example.noml
[
	1, 2, 3, 4, 5, 6,
	100, 200,
	6000000
]
```
###### Floats
Ah, floats. Lovely stuff, lots of detail. Any number with a period is a float. 5.5, 24.3, 6.9, etc. Even some real crazy stuff can be considered a float, like 1., .1, or even ..
```
# Example.noml
[
	5.5, 24.3, 6.9,
	1.,			# Equals 1.0
	.1,			# Equals 0.1
	.			# Equals 0.0
]
```
###### Strings
A string is just a sequence of characters. Chances are if you're looking at obscure JSON alternatives, you probably already know what a string is.
Strings can be initialised with either " or ', and then terminated with the same character chosen to initialise it. For example,
```
# Example.noml
[
	"My string!",
	"Another string of mine!",
	"The following is a string, not a float:",
	"123.4"
]
```
###### Arrays
Although called an array, they act more like lists or tuples, as any element can be of any type. Initialised with [ and terminated with ], an array holds a collection of items that are associated with each other in some manner.
Examples include:
```
# Example.noml
[
	[123, 456, "789"],	# Although "789" is a string and not an integer, it can still be in the same array as an integer.
	[62.490, ., "wooh!", "numbers", "rule!"]
]
```
All elements of a dictionary are separated by a comma.
###### Dictionaries
Dictionaries, a very useful data type. It can be thought of as a series of keys, and each key points to a specific value, but those keys and values are stored in the same place. Each key is unique, whereas each value is variable. That means that each key will point to a value, but each value may point to many unique keys.
Each key and value is referred to as an entry, or sometimes a key-value pair.
Dictionary keys and values can be of any type and mixed-together. Dictionaries are formed pretty easily, using a standard key-value pair syntax.
```
# Example.noml
{
	"my key": 123,
	
	["Strange", "key"]: "stranger value",

	"nested_dictionary": {
		"wow": "that",
		"sure": "is",
		"nifty": "!"
	}
}
```
All entries are separated by a comma, just like an array.
###### Mappings
Finally, mappings! NOML just wouldn't be NOML without mappings. It'd be a slightly strange JSON.
Mappings must be defined outside of NOML, through the interpreter. In Godot-NOML, that's done using `NOMLBuilder.map()` and `NOMLBuilder.map_native()`. Once you have a type mapped, you can refer to it in NOML. For example, let's say you map "Node2D" to Godot's Node2D. In NOML, to create a Node2D, you would instatiate it like so:
```
# ExampleNode.noml
Node2D()
```
The round brackets are absolutely necessary. It tells us that we're instantiating, and provides us a space to pass in constructor arguments. All types supported with mapping in Godot don't have constructor arguments, however, you can map your own custom types to NOML, and use constructor arguments on them. For example:
```GDScript
# Example.gd
class Person:
	var name
	var age

	func _init(p_name, p_age):
		name = p_name
		age = p_age


func _ready():
	var file = File.new()
	file.open("res://Example.noml", File.READ)

	NOML.parse(file.get_as_text()) \
		.map("Person", Person) \
		.build()
```
```
# ExampleCustom.noml
[
	Person("Steve", 36),
	Person("Harley", 24),
]
```
Is completely valid!

Okay, but what about Godot's nodes? Sure, you can map them and all that, but aren't they kinda useless if you're stuck using the constructor, and can't set the values in NOML? Great question, and yes! You're absolutely right!
<br><br><br><br><br><br><br><br><br>
But actually, NOML has a nifty little feature called "property overriding". Formatted similarly to dictionaries with the exception that all keys are identifiers, placing one directly after your type will set the corresponding properties on initialisation! Let me give you a little example:
```
# ExampleNode.noml
Node2D() { name: "Steve", position: Vector2(0, 0) }
```
It even works with your own custom types:
```
# ExampleCustom.noml
[
	Person("Steve", 36) { name: "Steven", 47 },
	Person("Harley", 24) { name: "Harleyyyyyyyre[ye", 100000000 }
]
```

Now finally, you must be wondering... What's up with that Vector2? We never mapped a Vector2. And you're right, we never did map a Vector2, because we can't map a Vector2. Due to certain limitations with Godot, you can't map certain types, such as int, String, PoolByteArray, Vector2, and so on. Luckily, Godot-NOML has got you covered with built-in implementations, so don't sweat it.

######  Comments
Technically not a type, but should be mentioned. Any time you use #, all characters following it will be ignored up until a newline. Most JSON implementations don't support comments, but they can be really useful, so I say include them.
Example:
```
# Example.noml
# ^^^ this is a comment, you've seen them!
# I love comments!
# Multi-line comments are not supported, you simply must use this format for comments.
{
	0: "data0",
	# Comments can go anywhere!
	1: "data1",	# Event at the end of a line, which is very useful!
}
```

## So what's next for NOML?
I've got a few ideas in mind. I recognise that this is a slightly useful tool, mostly just for the convenience. It could be considered a core design philosophy that its main purpose is to be convenient. However, there's so much room for experimentation! I'm considering the idea of something I might call a "standard", or maybe a "format". It basically forces a dictionary to assume a particular format. That is to say that it must have all field as required by the standard/format, failure to do so will result in a failed build of the NOML. I'd say the best way to think about it syntactically would be Rust's structs, just without methods for obvious reasons. I like this idea because it takes even less load off the user, as they don't have to check that a property exists on something like a dictionary before using it. You could achieve something like this with mapping, but it's just not the same. Maybe some of the properties on the format could have default values, too, so you don't have to set all the properties.

I also have considered the idea of inheritence, but I'm not exactly sold on it as I don't see the real benefit right now.

Another idea I've considerd is some sort of multi-file format, the same way in which modules work in something like Python, but I fear this idea is just too complex and not really in the nature of NOML. Maybe that's just my excuse so I don't have to rewrite the interpreter to suppor that.

What I definitely do want to do is refine the standard at some point and move it into other languages for sure. This is not just a useful thing for Godot, so many languages could benefit from this.
