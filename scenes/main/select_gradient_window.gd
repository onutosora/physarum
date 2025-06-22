extends Window

@export var data_bridge: Node
@export var gradient_editor: GradientEditor
@export var gradients:Array[Gradient] = []
@onready var gradients_container = $MarginContainer/FlowContainer

func _ready() -> void:
	close_requested.connect(hide)
	for gradient in gradients:
		var gradient_rect = ColorRect.new()
		gradient_rect.custom_minimum_size = Vector2.ONE * 60.0
		gradients_container.add_child(gradient_rect)
		var gradient_material = ShaderMaterial.new()
		gradient_rect.material = gradient_material
		gradient_material.shader = preload("res://scenes/main/gradient_rect.gdshader")
		var gradient_texture = GradientTexture1D.new()
		gradient_texture.gradient = gradient
		gradient_material.set("shader_parameter/gradient_texture", gradient_texture)
		gradient_rect.gui_input.connect(gradient_rect_input_handle(gradient))

func gradient_rect_input_handle(gradient:Gradient) -> Callable:
	return func (event: InputEvent):
		if event is InputEventMouseButton:
			if event.button_index==1 and event.pressed:
				var new_gradient = gradient.duplicate()
				data_bridge.gradient_texture.gradient = new_gradient
				gradient_editor.gradient = new_gradient
