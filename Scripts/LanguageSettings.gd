extends VBoxContainer

@export var language_option: OptionButton
@onready var language_option_button: OptionButton = $Control/Language

var languages := {
	"English": "en",
	"Indonesia": "id"
}

func _ready() -> void:
	for lang_name in languages.keys():
		language_option.add_item(lang_name)

	var current_locale := TranslationServer.get_locale()
	for i in range(language_option.item_count):
		var lang_name := language_option.get_item_text(i)
		if current_locale.begins_with(languages[lang_name]):
			language_option.select(i)
			break

	var popup = language_option_button.get_popup()
	var my_custom_font = language_option_button.get_theme_font("font")
	popup.add_theme_font_override("font", my_custom_font)
	popup.add_theme_font_size_override("font_size", 18)
	
	language_option.item_selected.connect(_on_language_selected)
	
func _on_language_selected(index: int):
	var lang_name := language_option.get_item_text(index)
	var locale = languages[lang_name]
	TranslationServer.set_locale(locale)
	get_tree().call_group("refresh_language", "refresh_language")
	print("Locale set to: ", locale)
