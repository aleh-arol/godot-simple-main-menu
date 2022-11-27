tool
extends Resource
class_name CannedRichTextEffect

export var effect_config: Dictionary setget configure_effect
export(RichTextEffect) var custom_effect:RichTextEffect setget set_custom_effect
export(String) var effect:String setget set_effect, get_effect

var _effect_code:String = ""

func _init(custom_effect:RichTextEffect = null, config:Dictionary = {}):
    set_custom_effect(custom_effect)
    effect_config = config

func apply_effect(data:String) -> String:
    var result = data
    if _effect_code:
        var effect_config_data = ""
        for key in effect_config:
            effect_config_data += ("%s=%s " % [str(key), str(effect_config[key])])

        result = "[%s %s]%s[/%s]" % [_effect_code, effect_config_data,
                                    data, _effect_code]

    return result

func configure_effect(config:Dictionary):
    effect_config = config
    emit_changed()

func set_effect(new_effect:String):
    if new_effect != _effect_code:
        _effect_code = new_effect
        custom_effect = null

        emit_changed()

func get_effect() -> String:
    return _effect_code

func set_custom_effect(new_effect:RichTextEffect):
    custom_effect = new_effect
    _effect_code = ""
    if custom_effect:
        _effect_code = custom_effect.bbcode \
                        if "bbcode" in custom_effect \
                            else custom_effect.get_class()

    emit_changed()
