tool
extends EditorPlugin

func _enter_tree():
    add_custom_type("SimpleMainMenu", "Control", preload("simple_main_menu.gd"), preload("icon.png"))


func _exit_tree():
    remove_custom_type("SimpleMainMenu")
