extends Node
class_name BBCodeParser

const MACROS = {
    "{orange}" = "[b][color=a14000]",
    "{/orange}" = "[/color][/b]",

    "{orange_bg}" = "[b][bgcolor=753C00][color=FF8F00]",
    "{/orange_bg}" = "[/color][/bgcolor][/b]",

    "{angry}" = "{shake}{speed 4}{fade_off}[b][color=ba0700][shake rate=20.0 level=15 connected=1]",
    "{/angry}" = "[/shake][/color][/b]{fade_on}{speed 1}{pause .5}"
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