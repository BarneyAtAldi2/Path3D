@tool
extends EditorPlugin

func _enter_tree():
	var script = ResourceLoader.load("res://addons/Trail3D/Trail3D.gd")
	var texture = ResourceLoader.load("res://addons/Trail3D/Icon.png")
	add_custom_type("Trail3D", "Node3D", script, texture)

func _exit_tree():
	remove_custom_type("Trail3D")
