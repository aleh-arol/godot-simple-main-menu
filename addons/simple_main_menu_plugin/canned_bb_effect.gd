tool
extends Resource
class_name CannedRichTextEffect

export var effect_config: Dictionary setget configure_effect
export(RichTextEffect) var effect:RichTextEffect setget set_effect

func _init(effect:RichTextEffect = null, config:Dictionary = {}):
    effect = effect
    effect_config = config

func apply_effect(data:String) -> String:
    var effect_code = effect.bbcode if "bbcode" in effect else effect.get_class()
    assert(effect_code)

    var effect_config_data = ""
    for key in effect_config:
        effect_config_data += ("%s=%s " % [str(key), str(effect_config[key])])

    return "[%s %s]%s[/%s]" % [effect_code, effect_config_data,
                                data, effect_code]

func configure_effect(config:Dictionary):
    effect_config = config
    emit_changed()

func set_effect(new_effect:RichTextEffect):
    effect = new_effect
    emit_changed()
