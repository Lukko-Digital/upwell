extends Node
class_name BBCodeParser

const MACROS = {
    "{orange}" = "[b][color=a14000]",
    "{/orange}" = "[/color][/b]",

    "{orange_bg}" = "[b][bgcolor=753C00][color=FF8F00]",
    "{/orange_bg}" = "[/color][/bgcolor][/b]"
}

# Searches through [text] and replaces all instances of [MACROS]
static func parse(text: String) -> String:
    for key in MACROS:
        text = text.replace(key, MACROS[key])
    return text

static func strip_bbcode(string: String) -> String:
    var regex = RegEx.new()
    regex.compile("\\[.+?\\]")
    return regex.sub(string, "", true)