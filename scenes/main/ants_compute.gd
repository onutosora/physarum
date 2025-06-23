extends Node
class_name AntsComputeNode

const width := 700
const height := 700
const compute_groups := Vector3i(32,32,1)

@export var texture_rect: TextureRect
@export_category("Space properties")
@export var fade_scale: float = 100.0
@export var diffuse_scale: float = 1.0
@export_category("Agents")
@export var agents_number: int = 30000
@export var agent_pheromone: float = 10.0
@export var sensors_angle: float = deg_to_rad(10)
@export var random_angle: float = deg_to_rad(20)
@export var sensors_distance: float = 10.0
@export var madness_threshold: float = 99.0
@export var madness_duration: float = 0.1
@export var madness_chance: float = 0.5
@export_category("Tools")
@export var brush_radius: int = 3
@export var brush_power: int = 10
var agents: Array[Agent] = []

var diffuse_shader_file: RDShaderFile = load("res://compute_shaders/diffuse.glsl")
var fade_shader_file: RDShaderFile = load("res://compute_shaders/fade.glsl")
var agents_shader_file: RDShaderFile = load("res://compute_shaders/agents.glsl")
var render_shader_file: RDShaderFile = load("res://compute_shaders/render.glsl")
var paint_shader_file: RDShaderFile = load("res://compute_shaders/paint.glsl")

var diffuse_compute: ComputeShaderProxy
var fade_compute: ComputeShaderProxy
var agents_compute: ComputeShaderProxy
var render_compute: ComputeShaderProxy
var paint_compute: ComputeShaderProxy

var pheromone_image: Image
var render_image: Image
var agents_pos_dir_image: Image
var agents_props_image: Image

var render_texture: ImageTexture
var time:float = 0.0

var paint_position:Vector2i = Vector2i.ZERO
var paint_radius:int = 0
var paint_value:int = 0

func _ready() -> void:
	if not texture_rect:
		print("No texture rect. Exiting...")
		get_tree().quit()
	
	create_images()
	create_compute_shaders()
	init_agents()
	fill_pheromone_with_noise()
	
	render_texture = ImageTexture.create_from_image(render_image)
	texture_rect.texture = render_texture
	
	texture_rect.gui_input.connect(draw_pheromone_input)

func create_images() -> void:
	pheromone_image = Image.create(width, height, false, Image.FORMAT_RH)
	agents_pos_dir_image = Image.create(width, height, false, Image.FORMAT_RGBAF)
	agents_props_image = Image.create(width, height, false, Image.FORMAT_RGBAH)
	render_image = Image.create(width, height, false, Image.FORMAT_RGBA8)

func create_compute_shaders() -> void:
	create_diffuse_compute_shader()
	create_fade_compute_shader()
	create_agents_compute_shader()
	create_render_compute_shader()
	create_paint_compute_shader()

func create_diffuse_compute_shader() -> void:
	diffuse_compute = ComputeShaderProxy.new(diffuse_shader_file, compute_groups)
	diffuse_compute.bind_buffer_uniform(0, PackedFloat32Array([0.0, 0.0]).to_byte_array())
	diffuse_compute.bind_buffer_uniform(1, PackedFloat32Array([
		diffuse_scale,
		width,
		height
	]).to_byte_array())
	diffuse_compute.bind_texture_uniform(2, pheromone_image, RenderingDevice.DATA_FORMAT_R16_SFLOAT)
	diffuse_compute.bind_texture_uniform(3, pheromone_image, RenderingDevice.DATA_FORMAT_R16_SFLOAT)
	diffuse_compute.consolidate_uniforms()

func create_fade_compute_shader() -> void:
	fade_compute = ComputeShaderProxy.new(fade_shader_file, compute_groups)
	fade_compute.bind_buffer_uniform(0, PackedFloat32Array([0.0]).to_byte_array())
	fade_compute.bind_buffer_uniform(1, PackedFloat32Array([fade_scale]).to_byte_array())
	fade_compute.bind_texture_uniform(2, pheromone_image, RenderingDevice.DATA_FORMAT_R16_SFLOAT)
	fade_compute.consolidate_uniforms()

func create_agents_compute_shader() -> void:
	agents_compute = ComputeShaderProxy.new(agents_shader_file, compute_groups)
	agents_compute.bind_buffer_uniform(0, PackedFloat32Array([
		0.0,
		0.0
	]).to_byte_array())
	agents_compute.bind_buffer_uniform(1, PackedFloat32Array([
		width,
		height,
		agents_number,
		agent_pheromone,
		sensors_angle,
		random_angle,
		sensors_distance,
		madness_threshold,
		madness_duration,
		madness_chance
	]).to_byte_array())
	agents_compute.bind_texture_uniform(2, pheromone_image, RenderingDevice.DATA_FORMAT_R16_SFLOAT)
	agents_compute.bind_texture_uniform(3, agents_pos_dir_image, RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT)
	agents_compute.bind_texture_uniform(4, agents_props_image, RenderingDevice.DATA_FORMAT_R16G16B16A16_SFLOAT)
	agents_compute.consolidate_uniforms()

func create_render_compute_shader() -> void:
	render_compute = ComputeShaderProxy.new(render_shader_file, compute_groups)
	render_compute.bind_texture_uniform(0, pheromone_image, RenderingDevice.DATA_FORMAT_R16_SFLOAT)
	render_compute.bind_texture_uniform(1, render_image, RenderingDevice.DATA_FORMAT_R8G8B8A8_UNORM)
	render_compute.consolidate_uniforms()

func create_paint_compute_shader() -> void:
	paint_compute = ComputeShaderProxy.new(paint_shader_file, compute_groups)
	paint_compute.bind_buffer_uniform(0, PackedInt32Array([
		width,
		height,
		0,
		0,
		0,
		0
	]).to_byte_array())
	paint_compute.bind_texture_uniform(1, pheromone_image, RenderingDevice.DATA_FORMAT_R16_SFLOAT)
	paint_compute.consolidate_uniforms()

func init_agents() -> void:
	for x in range(width):
		for y in range(height):
			var position = Vector2(randf_range(0,width),randf_range(0,height))
			var direction = Vector2(randf_range(-1,1),randf_range(-1,1)).normalized()
			agents_pos_dir_image.set_pixel (x,y,Color(position.x,position.y,direction.x,direction.y))

func fill_pheromone_with_noise() -> void:
	var shift_power = 100.0
	var shift = Vector3(
		randf_range(-shift_power,shift_power),
		randf_range(-shift_power,shift_power),
		randf_range(-shift_power,shift_power)
	)
	for x in range(width):
		for y in range(height):
			var pheromone = max(
				FastNoiseLite.new().get_noise_3d(
					x + shift.x,
					y + shift.y,
					shift.z
				) + 0.5
			,0.0)*100.0
			pheromone_image.set_pixel(x,y,Color(pheromone,0,0))

func _process(delta: float) -> void:
	
	execute_diffuse(delta)
	execute_fade(delta)
	execute_agents(delta)
	execute_render()
	execute_paint()
	render_texture.update(render_image)
	
	time += delta

func coords_torus(coords: Vector2) -> Vector2:
	if coords.x < 0:
		coords.x = width-1
	elif coords.x >= width:
		coords.x = 0
	if coords.y < 0:
		coords.y = height-1
	elif coords.y >= height:
		coords.y = 0
	return coords

func execute_diffuse(delta:float) -> void:
	diffuse_compute.update_buffer_uniform(0, PackedFloat32Array([time, delta]).to_byte_array())
	diffuse_compute.update_buffer_uniform(1, PackedFloat32Array([
		diffuse_scale,
		width,
		height
	]).to_byte_array())
	diffuse_compute.update_texture_uniform(2, pheromone_image)
	diffuse_compute.update_texture_uniform(3, pheromone_image)
	diffuse_compute.execute()
	diffuse_compute.get_texture_uniform_data(3, pheromone_image)

func execute_fade(delta: float) -> void:
	fade_compute.update_buffer_uniform(0, PackedFloat32Array([delta]).to_byte_array())
	fade_compute.update_buffer_uniform(1, PackedFloat32Array([fade_scale]).to_byte_array())
	fade_compute.update_texture_uniform(2, pheromone_image)
	fade_compute.execute()
	fade_compute.get_texture_uniform_data(2, pheromone_image)

func execute_agents(delta: float) -> void:
	agents_compute.update_buffer_uniform(0, PackedFloat32Array([
		time,
		delta
	]).to_byte_array())
	agents_compute.update_buffer_uniform(1, PackedFloat32Array([
		width,
		height,
		agents_number,
		agent_pheromone,
		sensors_angle,
		random_angle,
		sensors_distance,
		madness_threshold,
		madness_duration,
		madness_chance
	]).to_byte_array())
	agents_compute.update_texture_uniform(2, pheromone_image)
	agents_compute.update_texture_uniform(3, agents_pos_dir_image)
	agents_compute.update_texture_uniform(4, agents_props_image)
	agents_compute.execute()
	agents_compute.get_texture_uniform_data(2, pheromone_image)
	agents_compute.get_texture_uniform_data(3, agents_pos_dir_image)
	agents_compute.get_texture_uniform_data(4, agents_props_image)

func execute_render() -> void:
	render_compute.update_texture_uniform(0, pheromone_image)
	render_compute.update_texture_uniform(1, render_image)
	render_compute.execute()
	render_compute.get_texture_uniform_data(1, render_image)

func execute_paint() -> void:
	paint_compute.update_buffer_uniform(0, PackedInt32Array([
		width,
		height,
		paint_position.x,
		paint_position.y,
		paint_radius,
		paint_value
	]).to_byte_array())
	paint_compute.update_texture_uniform(1, pheromone_image)
	paint_compute.execute()
	paint_compute.get_texture_uniform_data(1, pheromone_image)

func draw_pheromone_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var click_pos = get_click_texture_position()
		paint_position = click_pos
	
	if event is InputEventMouseButton:
		if event.button_mask & 3 != 0:
			var value = brush_power if event.button_mask & 1 != 0 else -100
			var click_pos = get_click_texture_position()
			if Rect2(0,0,width-1,height-1).has_point(click_pos):
				paint_radius = brush_radius
				paint_value = value
		else:
			paint_radius = 0
		

func get_click_texture_position() -> Vector2:
	var local_mouse = texture_rect.get_local_mouse_position()
	if texture_rect.size.x > texture_rect.size.y:
		var aspect := float(height)/texture_rect.size.y
		var texture_size_x = float(width)/aspect
		var margin_x = (texture_rect.size.x-texture_size_x)/2.0
		local_mouse.x -= margin_x
		local_mouse *= aspect
	else:
		var aspect := float(width)/texture_rect.size.x
		var texture_size_y = float(height)/aspect
		var margin_y = (texture_rect.size.y-texture_size_y)/2.0
		local_mouse.y -= margin_y
		local_mouse *= aspect
	return local_mouse

func close_position(position:Vector2) -> Vector2:
	if position.x < 0:
		position.x = width+position.x
	elif position.x >= width:
		position.x = position.x-width
	if position.y < 0:
		position.y = height+position.y
	elif position.y >= height:
		position.y = position.y-height
	return position

func fill_field(value:float) -> void:
	pheromone_image.fill(Color(value,0,0,0))
