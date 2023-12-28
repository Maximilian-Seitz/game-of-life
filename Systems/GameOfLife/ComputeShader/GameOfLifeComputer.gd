class_name GameOfLifeComputer extends ComputeShader


var field_size: Vector2i

var texture: ImageTexture


func flip_cell(pos: Vector2i) -> void:
	if is_running:
		await finished
	
	mutex.lock()
	
	var img = texture.get_image()
	if pos.x >= 0 and pos.y >= 0 and pos.x < img.get_width() and pos.y < img.get_height():
		var color = img.get_pixel(pos.x, pos.y)
		var new_color = Color(1,1,1,1) if color.r == 0 else Color(0,0,0,1)
		img.set_pixelv(pos, new_color)

		texture.update(img)
	
	mutex.unlock()


var _textures: Array[RID]

var _source_texture: RID:
	get:
		return _textures[0]

var _target_texture: RID:
	get:
		return _textures[1]


func _generate_uniforms() -> Array[RDUniform]:
	var img := Image.create(
		field_size.x,
		field_size.y,
		false,
		Image.FORMAT_L8
	)
	
	texture = ImageTexture.create_from_image(img)


	var uniforms: Array[RDUniform] = []


	var img_bytes := img.get_data()

	var img_format := RDTextureFormat.new()
	img_format.width = img.get_width()
	img_format.height = img.get_height()
	img_format.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT | RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT
	img_format.format = RenderingDevice.DATA_FORMAT_R8_UINT
	
	for i in 2:
		_textures.append(renderer.texture_create(img_format, RDTextureView.new(), [img_bytes]))

		uniforms.append(RDUniform.new())
		uniforms[-1].uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
		uniforms[-1].binding = 1 + i
		uniforms[-1].add_id(_textures[-1])


	return uniforms


func _read_inputs() -> Vector3i:
	mutex.lock()

	renderer.texture_update(
		_source_texture,
		0,
		texture.get_image().get_data()
	)

	mutex.unlock()

	return Vector3i(
		ceil(float(texture.get_width())/8.0),
		ceil(float(texture.get_height())/8.0),
		1
	)


func _write_outputs():
	mutex.lock()

	texture.update.call_deferred(
		Image.create_from_data(
			texture.get_width(),
			texture.get_height(),
			false,
			texture.get_format(),
			renderer.texture_get_data(_target_texture, 0)
		)
	)

	mutex.unlock()

