tool
extends Control

# Godot Next Versions ToDo -----------------------------------------------------
# * When themes will support non int constants
#   * Hover SFX to a "theme" as a resouce path
#   * Idle VFX to a "theme"
# * Rich text label alignment properties
# * User signals removal
# * Tool Scripts reload and variable erasing (fixed in 4.0?)
# Godot Next Versions ToDo -----------------------------------------------------

# TODO: node warning to be a dict

# TODO: text shift?
# TODO: test with other effects
# TODO: params to resource
# TODO: unit tests

# Vars -------------------------------------------------------------------------

const _class_name = "SimpleMainMenu"
const _menu_proto_scene = preload("simple_main_menu_proto.tscn")

export var menu_items: Dictionary setget set_menu_items
var _menu_item_labels: Dictionary

export(AudioStream) var hover_sfx setget set_hover_sfx

export(int, 1, 3600) var idle_timeout: int = 30 setget set_idle_timeout
export(int) var idle_item_id: int = 0 setget set_idle_item
export(Resource) var idle_vfx setget set_idle_vfx

onready var idle_timer:Timer = $Root/IdleTimer;
onready var menu_items_container:VBoxContainer = $Root/VBoxContainer;
onready var audio_player:AudioStreamPlayer = $Root/AudioStreamPlayer;

var _last_warning := ""

# Vars -------------------------------------------------------------------------

# Signals ----------------------------------------------------------------------

signal menu_item_clicked(menu_item_id, button_id)

# Signals ----------------------------------------------------------------------

func _init():
    print("_init called for: %s" % self)
    if not is_connected("script_changed", self, "_on_script_changed"):
        self.connect("script_changed", self, "_on_script_changed")

    # we can't use onready in full due to onready will not be
    # repopulated/reinitialized on script updates (e.g. saves)
    # instead we have to rely on explicit node lookup (code repetition)
    # or as below watch for script reinits when scene was preserved
    # and manually "repopulate" node ref vars
    # see https://github.com/godotengine/godot/issues/16974 for details
    if is_inside_tree():
        idle_timer = $Root/IdleTimer;
        menu_items_container = $Root/VBoxContainer;
        audio_player = $Root/AudioStreamPlayer;

func _enter_tree():
    print("_enter_tree called")
    self.add_child(_menu_proto_scene.instance())

func _ready():
    print("_ready called")

    # deferred exported props application
    set_menu_items(menu_items)
    set_idle_timeout(idle_timeout)

    if hover_sfx:
        set_hover_sfx(hover_sfx)

    if idle_vfx:
        set_idle_vfx(idle_vfx)

    _post_init_proto_scene()
    show()

# Proto scene ------------------------------------------------------------------

func _post_init_proto_scene():
    assert(is_inside_tree())

    idle_timer.connect("timeout", self, "_on_idle_timeout")
    $Root.connect("gui_input", self, "_on_menu_control_input")
    mouse_filter = Control.MOUSE_FILTER_PASS

# Proto scene ------------------------------------------------------------------

# Error handling ---------------------------------------------------------------

func _get_configuration_warning() -> String:
    return _last_warning

func _reset_node_warning():
    _last_warning = ""

func _set_node_warning(msg):
    _last_warning = msg

func _notify_editor_error(error_msg):
    push_error(error_msg)
    _set_node_warning(error_msg)

# Error handling ---------------------------------------------------------------

# Menu items handling ----------------------------------------------------------

func _add_menu_item(item_id: int, item_text: String):
    var item_label: RichTextLabel = RichTextLabel.new()
    item_label.mouse_filter = Control.MOUSE_FILTER_STOP
    item_label.bbcode_enabled = true

    item_label.bbcode_text = "[center]%s[/center]" % item_text

    # TODO: property to be deprecated in the next versions
    # to be replaced with alignment properties
    item_label.fit_content_height = true
    item_label.scroll_active = false

    var user_signal_name := "%s_clicked" % item_text.to_lower().replace(" ", "_")
    if not has_user_signal(user_signal_name):
        add_user_signal(user_signal_name)

    item_label.connect("gui_input", self, "_on_menu_item_input", [item_id, user_signal_name])
    item_label.connect("mouse_entered", self, "_on_menu_item_mouse_entered", [item_id, item_label])
    item_label.connect("mouse_exited", self, "_on_menu_item_mouse_exited", [item_id, item_label])

    _menu_item_labels[item_id] = item_label
    menu_items_container.add_child(item_label)

func _remove_menu_item(item_id: int):
    assert(item_id in _menu_item_labels)

    var item_label = _menu_item_labels[item_id]
    # can't delete user signal in Godot current version
    menu_items_container.remove_child(item_label)
    item_label.queue_free()

    _menu_item_labels.erase(item_id)

func _menu_items_validate(menu_items_new: Dictionary) -> bool:
    _reset_node_warning()
    var valid := true

    for item_id in menu_items_new:
        var item_text = menu_items_new[item_id]

        if typeof(item_id) != TYPE_INT:
            _notify_editor_error("Menu item keys can only be ints")
            valid = false

        if typeof(item_text) != TYPE_STRING:
            _notify_editor_error("Menu item values can only be strings")
            valid = false

    return valid

func set_menu_items(menu_items_new: Dictionary):
    if _menu_items_validate(menu_items_new):
        menu_items = menu_items_new

        # defer until ready called
        if not is_inside_tree(): yield(self, 'ready')

        for item_id in _menu_item_labels:
            if not item_id in menu_items_new:
                _remove_menu_item(item_id)

        for item_id in menu_items_new:
            if not item_id in _menu_item_labels:
                _add_menu_item(item_id, menu_items_new[item_id])

        if menu_items:
            set_idle_item(menu_items_new.keys()[0])

# Menu items handling ----------------------------------------------------------

# Idle effect ------------------------------------------------------------------

func set_idle_timeout(new_idle_timeout: int):
    idle_timeout = new_idle_timeout

    # defer until ready called
    if not is_inside_tree(): yield(self, 'ready')
    idle_timer.wait_time = idle_timeout

func set_idle_item(idle_item_id_new: int):
    _reset_node_warning()
    if idle_item_id_new in menu_items:
        # defer until ready called
        if not is_inside_tree(): yield(self, 'ready')

        reset_idle_vfx()
        if idle_item_id != idle_item_id_new:
            _reinstall_idle_vfx(idle_item_id_new, idle_item_id)

        idle_item_id = idle_item_id_new

    else:
        _notify_editor_error("Idle menu item id provided not in menu item keys")

func set_idle_vfx(vfx: CannedRichTextEffect):
    if idle_vfx and idle_vfx.is_connected("changed", self, "reset_idle_vfx"):
        idle_vfx.disconnect("changed", self, "reset_idle_vfx")

    idle_vfx = vfx
    if idle_vfx and not idle_vfx.is_connected("changed", self, "reset_idle_vfx"):
        idle_vfx.connect("changed", self, "reset_idle_vfx")

    # defer until ready called
    if not is_inside_tree(): yield(self, 'ready')

    reset_idle_vfx()
    _reinstall_idle_vfx(idle_item_id, idle_item_id)

func _reinstall_idle_vfx(new_item_id: int, old_item_id: int):
    assert(old_item_id in menu_items)
    assert(new_item_id in menu_items)

    var old_idle_item_control = _menu_item_labels[old_item_id]
    var new_idle_item_control = _menu_item_labels[new_item_id]

    old_idle_item_control.custom_effects.clear()
    new_idle_item_control.install_effect((idle_vfx as CannedRichTextEffect).effect)

func reset_idle_vfx(stop: bool = false):
    # stop idle effect
    var idle_item_control := (_menu_item_labels[idle_item_id] as RichTextLabel)
    var idle_item_text := String(menu_items[idle_item_id])
    idle_item_control.bbcode_text = ("[center]%s[/center]" % idle_item_text)

    if not stop:
        idle_timer.start()

func start_idle_vfx():
    var idle_item_control := (_menu_item_labels[idle_item_id] as RichTextLabel)
    var idle_item_bb_text := idle_item_control.bbcode_text

    idle_item_control.bbcode_text = idle_vfx.apply_effect(idle_item_bb_text)

func _on_idle_timeout():
    if idle_vfx:
        start_idle_vfx()

# Idle effect ------------------------------------------------------------------

func hide():
    menu_items_container.hide()
    reset_idle_vfx(true)

func show():
    menu_items_container.show()
    idle_timer.start()

func set_hover_sfx(sfx: AudioStream):
    hover_sfx = sfx

    # defer until ready called
    if not is_inside_tree(): yield(self, 'ready')
    audio_player.stream = hover_sfx

func _on_menu_item_input(event: InputEvent, item_id: int, user_signal_name: String):
    if event is InputEventMouseButton and event.pressed:
        emit_signal(user_signal_name)
        emit_signal("menu_item_clicked", item_id, event.button_index)

    if event is InputEventMouse:
        reset_idle_vfx()

func _on_menu_control_input(event: InputEvent):
    if event is InputEvent:
        reset_idle_vfx()

func _on_menu_item_mouse_entered(item_id: int, item_label: Control):
    var hover_color = get_color("font_color_hover", _class_name)
    var hover_shadow_color = get_color("font_color_shadow_hover", _class_name)
    var hover_shadow_offset_x = get_constant("shadow_offset_x_hover", _class_name)
    var hover_shadow_offset_y = get_constant("shadow_offset_y_hover", _class_name)

    item_label.add_color_override("default_color", hover_color)
    item_label.add_color_override("font_color_shadow", hover_shadow_color)
    item_label.add_constant_override("shadow_offset_x", hover_shadow_offset_x)
    item_label.add_constant_override("shadow_offset_y", hover_shadow_offset_y)

    if audio_player.stream:
        audio_player.play()

func _on_menu_item_mouse_exited(item_id: int, item_label: Control):
    item_label.remove_color_override("default_color")
    item_label.remove_color_override("font_color_shadow")
    item_label.remove_constant_override("shadow_offset_x")
    item_label.remove_constant_override("shadow_offset_y")

func _on_script_changed():
    # cleanup dynamically created labels as
    # on script reloading we lost the tracks
    # due to menu_item_labels var cleared
    # see the whole story here: https://github.com/godotengine/godot/issues/16974
    if is_inside_tree():
        if menu_items_container:
            for child in menu_items_container.get_children():
                menu_items_container.remove_child(child)
                child.queue_free()

