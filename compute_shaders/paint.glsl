#[compute]
#version 450

layout (local_size_x = 32, local_size_y = 32, local_size_z = 1) in;

layout (set = 0, binding = 0, std430) buffer Params {
    int width;
    int height;
    int posx;
    int posy;
    int radius;
    int value;
} params;
layout (set = 0, binding = 1, r32f) restrict uniform image2D pheromone_image;

ivec2 close_position(ivec2 position) {
    position.x = int(mod(position.x, params.width));
    position.y = int(mod(position.y, params.height));
    return position;
}

void main() {
    if (params.radius == 0) return;
    ivec2 position = ivec2(gl_GlobalInvocationID.xy);
    ivec2 origin = ivec2(params.posx, params.posy);
    float dist = distance(position,origin);
    if (dist <= params.radius) {
        float old_value = imageLoad(pheromone_image, position).r;
        float faded_value = (1.2 - dist / params.radius) * params.value;
        faded_value = clamp(old_value+faded_value, 0.0, 100.0);
        imageStore(pheromone_image, position, vec4(faded_value));
    }
}
