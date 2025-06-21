extends Node
class_name PropsBinder

@export var source_node:Node
@export var source_property:StringName
@export var target_property:StringName = "value"
@export var target_change_signal:StringName = "value_changed"

func _ready() -> void:
	if not source_node.has_signal("property_changed"):
		print("Source is not valid")
		queue_free()
		return
	source_node.property_changed.connect(on_property_changed)
	get_parent().connect(target_change_signal, try_change_property)

func on_property_changed(property_name:StringName, new_value) -> void:
	if property_name == source_property:
		if get_parent().get(target_property) != new_value:
			get_parent().set(target_property, new_value)

func try_change_property(_new_value=null) -> void:
	if source_node.get(source_property) != get_parent().get(target_property):
		source_node.set(source_property, get_parent().get(target_property))
