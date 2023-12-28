extends Node


@export var game: GameOfLife
@export var grid_material: ShaderMaterial


func _process(_delta):
	grid_material.set_shader_parameter("highlight_pos", game.get_hovered_cell())

