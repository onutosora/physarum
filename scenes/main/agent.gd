extends Object
class_name Agent

var position:Vector2
var direction:Vector2

func _init(pos:Vector2) -> void:
	position = pos
	direction = Vector2(
		randfn(-1,1),
		randfn(-1,1)
	).normalized()
