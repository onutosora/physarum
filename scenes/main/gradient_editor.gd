extends Panel
class_name GradientEditor

@export var gradient: Gradient:
	set(val):
		gradient = val
		if gradient_texture:
			gradient_texture.gradient = gradient
			recreate_buttons()

var gradient_texture: GradientTexture1D
var buttons:Dictionary[int, Button] = {}

func _ready() -> void:
	gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	material.set("shader_parameter/gradient_texture", gradient_texture)
	recreate_buttons()
	resized.connect(on_resized)

func recreate_buttons() -> void:
	if not gradient: return
	
	for point in buttons:
		var button = buttons[point]
		button.queue_free()
	buttons.clear()
	
	for point in range(gradient.get_point_count()):
		var button = Button.new()
		button.custom_minimum_size=Vector2.ONE * size.x
		button.theme = preload("res://scenes/main/gradient_editor.tres")
		button.focus_mode = Control.FOCUS_NONE
		add_child(button)
		button.set("point", point)
		button.position.y = (1.0 - gradient.get_offset(point)) * size.y
		buttons[point] = button
		button.gui_input.connect(create_button_gui_input_handler(button, point))

func on_resized() -> void:
	for point in buttons:
		var button = buttons[point]
		button.position.y = (1.0 - gradient.get_offset(point)) * size.y

var moving_point:int = -1
var click_offset:Vector2 = Vector2.ZERO
func create_button_gui_input_handler(button:Button, point:int) -> Callable:
	return func(event: InputEvent) -> void:
		if event is InputEventMouseButton:
			if event.button_index == 1:
				if event.pressed:
					moving_point = point
					click_offset = get_local_mouse_position() - button.position
				else:
					moving_point = -1
		elif event is InputEventMouseMotion and moving_point == point:
			var click_pos = clamp(get_local_mouse_position().y, 0.0, size.y)
			var offset = click_pos / size.y
			
			if 0.98-offset < gradient.get_offset(point - 1):
				return
			if 1.02-offset > gradient.get_offset(point + 1):
				return
			
			button.position.y = click_pos - click_offset.y
			gradient.set_offset(point, 1.0-offset)
