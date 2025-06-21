extends Object
class_name ComputeShaderProxy

var _rd: RenderingDevice
var _shader: RID
var _pipeline: RID
var _uniform_rids: Array[RID]
var _uniforms: Array[RDUniform]
var _uniform_set: RID
var _groups:Vector3i
var _textures_sizes:Dictionary[int,Vector2i]
var binds_rids: Dictionary[int, RID]

func _init(shader_file:RDShaderFile, groups:Vector3i) -> void:
	_groups = groups
	create_rendering_device()
	create_shader(shader_file)
	create_pipeline()

func create_rendering_device() -> void:
	_rd = RenderingServer.create_local_rendering_device()

func create_shader(shader_file:RDShaderFile) -> void:
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv()
	_shader = _rd.shader_create_from_spirv(shader_spirv)

func create_pipeline() -> void:
	_pipeline = _rd.compute_pipeline_create(_shader)

func create_texture_format(width:int, height:int, img_format)->RDTextureFormat:
	var format := RDTextureFormat.new()
	format.width = width
	format.height = height
	format.format = img_format
	format.usage_bits = \
		RenderingDevice.TEXTURE_USAGE_STORAGE_BIT|\
		RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT|\
		RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT
	return format

func bind_buffer_uniform(binding:int, byte_array:PackedByteArray) -> void:
	var buffer_rid = _rd.storage_buffer_create(byte_array.size(), byte_array)
	var uniform = RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	uniform.binding = binding
	uniform.add_id(buffer_rid)
	
	_uniforms.append(uniform)
	_uniform_rids.append(buffer_rid)
	binds_rids[binding] = buffer_rid

func bind_texture_uniform(binding:int, image:Image, rd_format:RenderingDevice.DataFormat=RenderingDevice.DATA_FORMAT_R8_UNORM):
	var format:RDTextureFormat = create_texture_format(
		image.get_width(), 
		image.get_height(),
		 rd_format
	)
	var view := RDTextureView.new()
	var data:Array[PackedByteArray] = [PackedByteArray(image.get_data())]
	var texture_rid = _rd.texture_create(format, view, data)
	var uniform := RDUniform.new()
	uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	uniform.binding = binding
	uniform.add_id(texture_rid)
	
	_uniforms.append(uniform)
	_uniform_rids.append(texture_rid)
	binds_rids[binding] = texture_rid
	_textures_sizes[binding] = Vector2i(image.get_width(), image.get_height())

func consolidate_uniforms() -> void:
	_uniform_set = _rd.uniform_set_create(_uniforms, _shader, 0)

func update_buffer_uniform(binding:int, byte_array:PackedByteArray) -> void:
	var buffer_rid = binds_rids[binding]
	_rd.buffer_update(buffer_rid, 0, byte_array.size(), byte_array)

func update_texture_uniform(binding:int, image:Image) -> void:
	var texture_rid = binds_rids[binding]
	var data:PackedByteArray = PackedByteArray(image.get_data())
	_rd.texture_update(texture_rid, 0, data)

func execute() -> void:
	var compute_list = _rd.compute_list_begin()
	_rd.compute_list_bind_compute_pipeline(compute_list, _pipeline)
	_rd.compute_list_bind_uniform_set(compute_list, _uniform_set, 0)
	_rd.compute_list_dispatch(compute_list, _groups.x, _groups.y, _groups.z)
	_rd.compute_list_end()
	
	_rd.submit()
	_rd.sync()

func get_buffer_uniform_data(binding:int) -> PackedByteArray:
	var buffer_rid = binds_rids[binding]
	var data = _rd.buffer_get_data(buffer_rid)
	return data

func get_texture_uniform_data(binding:int, to_image:Image):
	var texture_rid = binds_rids[binding]
	var texture_size = _textures_sizes[binding]
	var data = _rd.texture_get_data(texture_rid, 0)
	to_image.set_data(texture_size.x, texture_size.y, false, to_image.get_format(), data)

func clear():
	if _rd != null:
		for uniform_rid in _uniform_rids:
			_rd.free_rid(uniform_rid)
		_rd.free_rid(_uniform_set)
		_rd.free_rid(_pipeline)
		_rd.free_rid(_shader)
		_rd.free()
