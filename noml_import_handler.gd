tool
extends EditorImportPlugin


func get_importer_name() -> String:
	return "iamnotisaac.noml.importhandler"


func get_visible_name() -> String:
	return "NOML"


func get_recognized_extensions() -> Array:
	return ["noml"]


func get_save_extension() -> String:
	return "noml"


func get_resource_type():
	return "Mesh"

func get_preset_count():
	return 1

func get_preset_name(i):
	return "Default"

func get_import_options(i):
	return [{"name": "my_option", "default_value": false}]



func import(source_file, save_path, options, platform_variants, gen_files):
	pass
#	var file = File.new()
#	if file.open(source_file, File.READ) != OK:
#		return FAILED
