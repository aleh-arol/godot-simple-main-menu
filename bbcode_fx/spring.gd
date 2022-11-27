tool
extends RichTextEffect
class_name SpringRichTextEffect

var bbcode = "spring"

func _process_custom_fx(char_fx: CharFXTransform):
    var absolute_index = char_fx.absolute_index
    var elapsed_time = char_fx.elapsed_time
    var idx_key = "start_amplitude_%d" % absolute_index

    # spring effect duration
    var period = char_fx.env.get("t", 8.0)

    # idle period in between of the spring effects
    var idle_period = char_fx.env.get("idle_t", 0.0)

    # per char random start ampliture
    # once set reused afterwards (saving it back after init)
    var start_amplitude_min = char_fx.env.get("a0_min", 0.0)
    var start_amplitude_max = char_fx.env.get("a0_max", 300.0)

    var start_amplitude = char_fx.env.get(idx_key, rand_range(start_amplitude_min,
                                                                start_amplitude_max))
    char_fx.env[idx_key] = start_amplitude

    # spring vibration resistance
    var resistance = char_fx.env.get("resist", 2.0)

    # spring vibration freq
    var freq = char_fx.env.get("freq", 10.0)

    # spring vibration per char phase offset, PI / 4
    var char_phase_offset = char_fx.env.get("phase_off", 0.0)

    # time in effect space (recurring periods of period + idle_period)
    var fx_time = fmod(float(elapsed_time), (period + idle_period))
    var fx_work_time = clamp(fx_time, 0.0, period)

    # char phase0
    var phase = absolute_index * char_phase_offset

    var amplitude = start_amplitude * exp(-fx_work_time * resistance)

    # clamp amplitude when work time finished
    if (fx_work_time == period): amplitude = 0.0

    char_fx.offset = Vector2(amplitude * sin(freq * fx_work_time + phase), 0.0)

    return true
