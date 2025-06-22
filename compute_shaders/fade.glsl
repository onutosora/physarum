#[compute]
#version 450

layout (local_size_x = 32, local_size_y = 32, local_size_z = 1) in;

layout (set = 0, binding = 0, std430) buffer Timing {
	float delta;
} timing;
layout (set = 0, binding = 1, std430) buffer Params {
    float fading;
} params;
layout (set = 0, binding = 2, r16f) restrict uniform image2D pheromone_image;



void main() {
	ivec2 pos = ivec2(gl_GlobalInvocationID.xy);
	float pheromone = imageLoad(pheromone_image, pos).r;
	pheromone = max(0.0, pheromone - params.fading*timing.delta*pheromone/100.0);
	pheromone = clamp(pheromone, 0.0, 100.0);
	imageStore(pheromone_image, pos, vec4(pheromone,0.0,0.0,0.0));
}
