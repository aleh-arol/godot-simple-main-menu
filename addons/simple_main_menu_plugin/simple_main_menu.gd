tool
extends Control

# Vars -------------------------------------------------------------------------

const _menu_proto_scene = preload("simple_main_menu_proto.tscn")

export var menu_items: Dictionary setget set_menu_items
var _menu_item_labels: Dictionary

export(int, 1, 3600) var idle_timeout: int = 30 setget set_idle_timeout

var _last_warning := ""

# Vars -------------------------------------------------------------------------

# Signals ----------------------------------------------------------------------

signal menu_item_clicked(menu_item_id)

# Signals ----------------------------------------------------------------------

#TODO: timer effect (restart time on activity, stop effect on activity)

#TODO: timer ()
#TODO: theme/theme changed

func _init():
    print("_init called for: %s" % self)
    if not is_connected("script_changed", self, "_on_script_changed"):
        self.connect("script_changed", self, "_on_script_changed")

func _enter_tree():
    print("_enter_tree called")
    self.add_child(_menu_proto_scene.instance())

func _ready():
    print("_ready called")

    # deferred exported props application
    set_menu_items(menu_items)
    set_idle_timeout(idle_timeout)

    _post_init_proto_scene()
    show()

# Proto scene ------------------------------------------------------------------

func _proto_scene_constructed() -> bool:
    return get_child_count() != 0

func _post_init_proto_scene():
    assert(_proto_scene_constructed())

    $Root/IdleTimer.connect("timeout", self, "_on_idle_timeout")
    mouse_filter = Control.MOUSE_FILTER_PASS

# Proto scene ------------------------------------------------------------------

# Error handling ---------------------------------------------------------------

func _get_configuration_warning():
    return _last_warning

func _reset_node_warning():
    _last_warning = ""

func _set_node_warning(msg):
    _last_warning = msg

# Error handling ---------------------------------------------------------------

# Menu items handling ----------------------------------------------------------

func _add_menu_item(item_id: int, item_text: String):
    var item_label: Label = Label.new()
    item_label.text = item_text
    item_label.mouse_filter = Control.MOUSE_FILTER_STOP
    item_label.align = Label.ALIGN_CENTER
    item_label.valign = Label.VALIGN_CENTER

    var user_signal_name := "%s_clicked" % item_text.to_lower().replace(" ", "_")
    if not has_user_signal(user_signal_name):
        add_user_signal(user_signal_name)

    item_label.connect("gui_input", self, "_on_menu_item_input", [item_id, user_signal_name])

    _menu_item_labels[item_id] = item_label
    $Root/VBoxContainer.add_child(item_label)

func _remove_menu_item(item_id):
    assert(item_id in _menu_item_labels)

    var item_label = _menu_item_labels[item_id]
    #delete user signal?
    $Root/VBoxContainer.remove_child(item_label)
    item_label.queue_free()

    _menu_item_labels.erase(item_id)

func _menu_items_validate(menu_items_new) -> bool:
    _reset_node_warning()
    var valid := true

    for item_id in menu_items_new:
        var item_text = menu_items_new[item_id]

        if typeof(item_id) != TYPE_INT:
            var error_msg := "Menu item keys can only be ints"
            push_error(error_msg)
            _set_node_warning(error_msg)
            valid = false

        if typeof(item_text) != TYPE_STRING:
            var error_msg := "Menu item values can only be strings"
            push_error(error_msg)
            _set_node_warning(error_msg)
            valid = false

    return valid

func set_menu_items(menu_items_new):
    if _menu_items_validate(menu_items_new):
        menu_items = menu_items_new

        if _proto_scene_constructed():

            for item_id in _menu_item_labels:
                if not item_id in menu_items_new:
                    _remove_menu_item(item_id)

            for item_id in menu_items_new:
                if not item_id in _menu_item_labels:
                    _add_menu_item(item_id, menu_items_new[item_id])

# Menu items handling ----------------------------------------------------------

# Idle effect ------------------------------------------------------------------

func set_idle_timeout(idle_timeout):
    idle_timeout = idle_timeout
    if _proto_scene_constructed():
        ($Root/IdleTimer as Timer).wait_time = idle_timeout

func restart_idle_timer():
    ($Root/IdleTimer as Timer).start()

func _on_idle_timeout():
    pass

# Idle effect ------------------------------------------------------------------

func hide():
    $Root/VBoxContainer.hide()
    $Root/IdleTimer.stop()

func show():
    $Root/VBoxContainer.show()
    $Root/IdleTimer.start()

func _on_menu_item_input(event, item_id, user_signal_name):
    if event is InputEventMouseButton and event.button_index == BUTTON_LEFT and event.pressed:
        emit_signal(user_signal_name)
        emit_signal("menu_item_clicked", item_id)

    elif event is InputEventMouse:
        restart_idle_timer()

func _on_script_changed():
    # cleanup dynamically created labels as
    # on script reloading we lost the tracks
    # due to menu_item_labels var cleared
    if _proto_scene_constructed():
        var label_conainer := $Root/VBoxContainer

        if label_conainer:
            for child in label_conainer.get_children():
                label_conainer.remove_child(child)
                child.queue_free()

