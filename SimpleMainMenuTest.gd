tool
extends "res://addons/simple_main_menu_plugin/simple_main_menu.gd"

func _ready():
    var r1 = connect("start_game_clicked", self, "on_start_game")
    var r2 = connect("quit_game_clicked", self, "on_quit_game")

    assert(r1 == OK)
    assert(r2 == OK)

func on_start_game():
    print('ON START GAME')

func on_quit_game():
    print('ON QUIT GAME')


