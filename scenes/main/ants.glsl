#[compute]
#version 450

layout (local_size_x = 32, local_size_y = 32, local_size_z = 1) in;

layout (set = 0, binding = 0, std430) buffer Timing {
	float delta;
    float time;
} timing;
layout (set = 0, binding = 1, rgba32f) restrict uniform writeonly image2D render_image;
layout (set = 0, binding = 2, r8) restrict uniform readonly image2D pheromon_image_old;
layout (set = 0, binding = 3, r8) restrict uniform image2D pheromon_image_new;



void main() {
	ivec2 pos = ivec2(gl_GlobalInvocationID.xy);

	float old_pheromon = imageLoad(pheromon_image_old, pos).r;

	imageStore(pheromon_image_new, pos, vec4(old_pheromon));
	if (old_pheromon > 0.0) {
		imageStore(pheromon_image_new, pos+ivec2(0,1), vec4(1.0));
	}

	float pheromon = imageLoad(pheromon_image_new, pos).r;
	imageStore(render_image, pos, vec4(0.0, pheromon, 0.0, 1.0));
}
