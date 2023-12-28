class_name GameOfLife extends Node2D


@export var field_size: Vector2i = Vector2i(2000, 2000)

@export_group("Zoom")
@export var min_zoom: float = 0.5
@export var max_zoom: float = 40.0
@export var zoom_step: float = 0.1

@export_group("Computation")
@export var computer: GameOfLifeComputer

@export_group("Visuals")
@export var field_material: Material


var sprite: Sprite2D
var camera: Camera2D

var is_busy: bool = false


func _ready():
	computer.field_size = field_size
	computer.finished.connect(_computer_finished)
	computer.start()

	camera = Camera2D.new()
	camera.zoom = 20 * Vector2.ONE
	camera.position = field_size / 2
	add_child(camera)

	sprite = Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.centered = false
	sprite.texture = computer.texture
	sprite.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	sprite.region_enabled = true
	sprite.region_rect = Rect2(
		-4*field_size,
		9*field_size
	)
	sprite.position = -4*field_size
	sprite.material = field_material
	add_child(sprite)


func _exit_tree():
	computer.finished.disconnect(_computer_finished)
	computer.stop()


func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			camera.position -= event.relative / camera.zoom
			_center_camera()
	elif event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom_in(get_local_mouse_position())
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom_out(get_local_mouse_position())
			elif event.button_index == MOUSE_BUTTON_LEFT:
				toggle_current_cell()

func zoom_in(pos: Vector2):
	var zoom_factor = camera.zoom.x * (1.0 + zoom_step)

	if zoom_factor < max_zoom:
		camera.position += (pos - camera.position) * zoom_step
		camera.zoom = zoom_factor * Vector2.ONE
	else:
		camera.zoom = max_zoom * Vector2.ONE
	
	_center_camera()

func zoom_out(pos: Vector2):
	var zoom_factor = camera.zoom.x * (1.0 - zoom_step)

	if zoom_factor > min_zoom:
		camera.position -= (pos - camera.position) * zoom_step
		camera.zoom = zoom_factor * Vector2.ONE
	else:
		camera.zoom = min_zoom * Vector2.ONE
	
	_center_camera()

func get_hovered_cell() -> Vector2i:
	var mouse_pos = sprite.get_local_mouse_position()
	return Vector2i(
		int(mouse_pos.x) % sprite.texture.get_width(),
		int(mouse_pos.y) % sprite.texture.get_width()
	)

func toggle_current_cell() -> void:
	toggle_cell(get_hovered_cell())

func toggle_cell(pos: Vector2i) -> void:
	computer.flip_cell(pos)

func run_computer():
	if not is_busy:
		is_busy = true
		computer.run()

func _computer_finished():
	is_busy = false

func _center_camera():
	while camera.position.x < -0.5*field_size.x:
		camera.position.x += field_size.x

	while camera.position.y < -0.5*field_size.y:
		camera.position.y += field_size.y

	while camera.position.x > 1.5*field_size.x:
		camera.position.x -= field_size.x

	while camera.position.y > 1.5*field_size.y:
		camera.position.y -= field_size.y
