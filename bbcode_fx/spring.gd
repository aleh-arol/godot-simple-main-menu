tool
extends RichTextEffect
class_name SpringRichTextEffect

var bbcode = "spring"

func _init():
    randomize()

func _process_custom_fx(char_fx: CharFXTransform):
    #var speed = char_fx.env.get("speed", 5.0)
    #var amplitude = char_fx.env.get("a0", 20.0)
    #var duration = char_fx.env.get("duration", 3.0)
    var absolute_index = char_fx.absolute_index
    var idx_key = "start_amplitude_%d" % absolute_index

    var period = 8.0
    var idle_period = 5.0
    var start_amplitude = char_fx.env.get(idx_key, rand_range(0.0, 300.0))
    char_fx.env[idx_key] = start_amplitude

    var resistance = 2
    var freq = 10.0
    var char_phase_offset = PI/4

    var elapsed_time = char_fx.elapsed_time
    var fx_time = fmod(float(elapsed_time), (period + idle_period))
    var fx_work_time = clamp(fx_time, 0.0, period)

    var phase = absolute_index * char_phase_offset

    var amplitude = start_amplitude * exp(-fx_work_time * resistance)
    if (fx_work_time == period): amplitude = 0.0

    char_fx.offset = Vector2(amplitude * sin(freq * fx_work_time + phase), 0.0)

    return true
