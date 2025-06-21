extends Node
class_name ButtonBinder

@export var target:Node
@export var target_function:StringName

func _ready() -> void:
	var parent = get_parent()
	if parent is Button:
		parent.pressed.connect(_on_pressed)

func _on_pressed() -> void:
	target.call_deferred(target_function)
