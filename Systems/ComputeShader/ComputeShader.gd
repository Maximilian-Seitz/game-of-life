class_name ComputeShader extends Resource


@export var shader_file: RDShaderFile


signal finished()


var is_running: bool = false


var mutex: Mutex
var _semaphore: Semaphore
var _thread: Thread

var renderer: RenderingDevice

var _shader: RID
var _pipeline: RID

var _uniform_set: RID


var _should_stop: bool = false


func start():
	mutex = Mutex.new()
	_semaphore = Semaphore.new()
	_thread = Thread.new()
	_thread.start(_thread_compute)

	renderer = RenderingServer.create_local_rendering_device()

	var shader_spirv := shader_file.get_spirv()
	_shader = renderer.shader_create_from_spirv(shader_spirv)
	_pipeline = renderer.compute_pipeline_create(_shader)

	_uniform_set = renderer.uniform_set_create(
		_generate_uniforms(),
		_shader,
		0 #needs to match the "set" in our shader file
	)


func stop():
	mutex.lock()
	_should_stop = true
	mutex.unlock()

	_semaphore.post()
	_thread.wait_to_finish()


func run():
	await RenderingServer.frame_post_draw
	_semaphore.post()


func _thread_compute():
	while true:
		_semaphore.wait()

		mutex.lock()
		var should_stop := _should_stop
		mutex.unlock()

		if should_stop:
			break
		
		is_running = true
		
		
		var size = _read_inputs()


		var compute_list := renderer.compute_list_begin()
		renderer.compute_list_bind_compute_pipeline(compute_list, _pipeline)
		renderer.compute_list_bind_uniform_set(compute_list, _uniform_set, 0)
		renderer.compute_list_dispatch(compute_list, size.x, size.y, size.z)
		renderer.compute_list_end()


		renderer.submit()
		renderer.sync()
		
		_write_outputs()

		_emit_finished.call_deferred()

		is_running = false


func _emit_finished():
	finished.emit()



func _read_inputs():
	pass

func _write_outputs():
	pass


func _generate_uniforms():
	return []
