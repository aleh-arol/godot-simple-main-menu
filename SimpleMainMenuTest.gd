tool
extends "res://addons/simple_main_menu_plugin/simple_main_menu.gd"

func _ready():
    connect("start_game_clicked", self, "on_start_game")
    connect("quit_game_clicked", self, "on_quit_game")

func on_start_game():
    print('ON START GAME')

func on_quit_game():
    print('ON QUIT GAME')


