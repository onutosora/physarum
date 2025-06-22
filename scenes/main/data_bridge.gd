extends Node

signal property_changed(name:StringName, new_value)

@export var compute_node:AntsComputeNode

var fade_scale: float:
	set(val):
		compute_node.fade_scale = val
		property_changed.emit('fade_scale', val)
	get:
		return compute_node.fade_scale

var diffuse_scale: float:
	set(val):
		compute_node.diffuse_scale = val
		property_changed.emit('diffuse_scale', val)
	get:
		return compute_node.diffuse_scale

var agent_pheromone: float:
	set(val):
		compute_node.agent_pheromone = val
		property_changed.emit('agent_pheromone', val)
	get:
		return compute_node.agent_pheromone

var sensors_angle: float:
	set(val):
		compute_node.sensors_angle = deg_to_rad(val)
		property_changed.emit('sensors_angle', val)
	get:
		return rad_to_deg(compute_node.sensors_angle)

var random_angle: float:
	set(val):
		compute_node.random_angle = deg_to_rad(val)
		property_changed.emit('random_angle', val)
	get:
		return rad_to_deg(compute_node.random_angle)

var sensors_distance: float:
	set(val):
		compute_node.sensors_distance = val
		property_changed.emit('sensors_distance', val)
	get:
		return compute_node.sensors_distance

var agents_number: int:
	set(val):
		compute_node.agents_number = int(val)
		property_changed.emit('agents_number', val)
	get:
		return compute_node.agents_number

var brush_radius: int:
	set(val):
		compute_node.brush_radius = int(val)
		property_changed.emit('brush_radius', val)
	get:
		return compute_node.brush_radius

var brush_power: int:
	set(val):
		compute_node.brush_power = int(val)
		property_changed.emit("brush_power", val)
	get:
		return compute_node.brush_power

func _ready() -> void:
	property_changed.emit('fade_scale', fade_scale)
	property_changed.emit('diffuse_scale', diffuse_scale)
	property_changed.emit('agent_pheromone', agent_pheromone)
	property_changed.emit('sensors_distance', sensors_distance)
	property_changed.emit('sensors_angle', sensors_angle)
	property_changed.emit('random_angle', random_angle)
	property_changed.emit('agents_number', agents_number)
	property_changed.emit('brush_radius', brush_radius)
	property_changed.emit("brush_power", brush_power)

func fill_field()->void:
	compute_node.fill_field(100.0)

func fill_field_with_noise()->void:
	compute_node.fill_pheromone_with_noise()

func clear_field()->void:
	compute_node.fill_field(0.0)

func randomize_settings()->void:
	#fade_scale       = randf_range(0,100)
	#diffuse_scale    = randf_range(0,1.0)
	agent_pheromone  = randf_range(0,100)
	sensors_distance = randf_range(0,50)
	sensors_angle    = randf_range(0,90)
	random_angle     = randf_range(0,90)
