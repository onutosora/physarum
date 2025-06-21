#[compute]
#version 450

layout (local_size_x = 32, local_size_y = 32, local_size_z = 1) in;

layout (set = 0, binding = 0, std430) buffer Timing {
    float time;
	float delta;
} timing;
layout (set = 0, binding = 1, std430) buffer Params {
    float diffusion;
    float width;
    float height;
} params;
layout (set = 0, binding = 2, r32f) restrict uniform readonly image2D pheromone_image_old;
layout (set = 0, binding = 3, r32f) restrict uniform writeonly image2D pheromone_image_new;

float rand(vec3 co){
    return fract(sin(dot(co, vec3(12.9898, 78.233, -393.54))) * 43758.5453);
}

ivec2 close_position(ivec2 position) {
    int iwidth  = int(params.width);
    int iheight = int(params.height);
    if      (position.x < 0       ) position.x = iwidth-1;
    else if (position.x >= iwidth ) position.x = 0;
    if      (position.y < 0       ) position.y = iheight-1;
    else if (position.y >= iheight) position.y = 0;
    return position;
}

void main() {
    ivec2 pos = ivec2(gl_GlobalInvocationID.xy);
    
    float total_pheromone = 0.0;
    for (int x=-1;x<2;x++) for (int y=-1;y<2;y++) {
        ivec2 new_pos = close_position(pos + ivec2(x,y));
        total_pheromone += imageLoad(pheromone_image_old, new_pos).r;
    }
    total_pheromone /= 9.0;
    float start_pheromone = imageLoad(pheromone_image_old, pos).r;
    imageStore(pheromone_image_new, pos, vec4(
        mix(start_pheromone, total_pheromone, params.diffusion*timing.delta*60.0*start_pheromone/100.0)
    ));
}
