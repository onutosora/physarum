#[compute]
#version 450

layout (local_size_x = 32, local_size_y = 32, local_size_z = 1) in;
layout (set = 0, binding = 0, r16f) restrict uniform readonly image2D pheromone_image;
layout (set = 0, binding = 1, rgba32f) restrict uniform writeonly image2D render_image;

void main() {
    ivec2 pos = ivec2(gl_GlobalInvocationID.xy);
    float pheromone = imageLoad(pheromone_image, pos).r / 100.0;
    imageStore(render_image, pos, vec4(vec3(pheromone),1.0));
}
