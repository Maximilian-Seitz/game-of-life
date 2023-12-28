#[compute]
#version 450

// Invocations in the (x, y, z) dimension
layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;


// Uniforms
layout(set = 0, binding = 1, r8ui) restrict readonly uniform uimage2D input_img;
layout(set = 0, binding = 2, r8ui) restrict writeonly uniform uimage2D output_img;



ivec2 normalizePos(ivec2 pos) {
	ivec2 img_size = imageSize(input_img);
	int x = pos.x;
	int y = pos.y;

	if (x >= img_size.x) {
		x -= img_size.x;
	} else if (x < 0) {
		x += img_size.x;
	}

	if (y >= img_size.y) {
		y -= img_size.y;
	} else if (y < 0) {
		y += img_size.y;
	}

	return ivec2(x, y);
}

uvec4 readPixel(ivec2 pos) {
	return imageLoad(input_img, pos);
}

void writePixel(ivec2 pos, uvec4 color) {
	imageStore(output_img, pos, color);
}


bool is_cell_live(ivec2 pos) {
	return readPixel(normalizePos(pos)).r > 0;
}

int cell_life(ivec2 pos) {
	if (is_cell_live(pos)) {
		return 1;
	} else {
		return 0;
	}
}

int get_neightbour_count(ivec2 pos) {
	return cell_life(pos + ivec2(-1, -1)) + cell_life(pos + ivec2(-1, 0)) + cell_life(pos + ivec2(-1, 1)) +
		   cell_life(pos + ivec2( 0, -1))                                 + cell_life(pos + ivec2( 0, 1)) +
		   cell_life(pos + ivec2( 1, -1)) + cell_life(pos + ivec2( 1, 0)) + cell_life(pos + ivec2( 1, 1));
}

/*
 * 1. Any live cell with fewer than two live neighbours dies, as if caused by underpopulation.
 * 2. Any live cell with two or three live neighbours lives on to the next generation.
 * 3. Any live cell with more than three live neighbours dies, as if by overpopulation.
 * 4. Any dead cell with exactly three live neighbours becomes a live cell, as if by reproduction.
 */
bool should_cell_be_live(ivec2 pos) {
	int neighbour_count = get_neightbour_count(pos);
	if (is_cell_live(pos)) {
		return neighbour_count == 2 || neighbour_count == 3;
	} else {
		return neighbour_count == 3;
	}
}

void main() {
	ivec2 pos = ivec2(gl_GlobalInvocationID.xy);

	ivec2 size = imageSize(input_img);

	if (pos.x < size.x && pos.y < size.y) {
		if (should_cell_be_live(pos)) {
			writePixel(pos, uvec4(-1, 0, 0, -1));
		} else {
			writePixel(pos, uvec4(0, 0, 0, -1));
		}
	}
}
