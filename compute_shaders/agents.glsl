#[compute]
#version 450

layout (local_size_x = 32, local_size_y = 32, local_size_z = 1) in;

layout (set = 0, binding = 0, std430) buffer Timing {
    float time;
	float delta;
} timing;
layout (set = 0, binding = 1, std430) buffer Params {
    float width;
    float height;
    float agents_number;
    float agent_pheromone;
    float sensors_angle;
    float random_sensors_angle;
    float sensors_distance;
    float madness_threshold;
    float madness_duration;
    float madness_chance;
} params;
layout (set = 0, binding = 2, r16f) restrict uniform image2D pheromone_image;
layout (set = 0, binding = 3, rgba32f) restrict uniform image2D agents_pos_dir;
layout (set = 0, binding = 4, rgba16f) restrict uniform image2D agents_props;


vec2 rotate(vec2 v, float a) {
	float s = sin(a);
	float c = cos(a);
	mat2 m = mat2(c, s, -s, c);
	return m * v;
}

vec2 close_position(vec2 position) {
    position.x = mod(position.x, params.width);
    position.y = mod(position.y, params.height);
    return position;
}

float rand(vec2 co){
    return fract(sin(dot(vec3(co, timing.time), vec3(12.9898, 78.233, -2915.471))) * 43758.5453);
}

void main() {
    ivec2 invoc_vec = ivec2(gl_GlobalInvocationID.xy);
    int agent_id = invoc_vec.x + invoc_vec.y*int(params.width);
    if (agent_id >= params.agents_number) return;


    // Get agent data
    vec4 pos_dir = imageLoad(agents_pos_dir, invoc_vec);
    vec2 agent_position = pos_dir.rg;
    vec2 agent_direction = pos_dir.ba;
    vec4 props = imageLoad(agents_props, invoc_vec);
    float madness = props.r;
    float agent_random = rand(agent_position+agent_direction);


    // Spill pheromone
    float current_pheromone = imageLoad(pheromone_image, ivec2(agent_position)).r;
    imageStore(pheromone_image, ivec2(agent_position), vec4(current_pheromone+params.agent_pheromone));


    // Calculate new agent position
    vec2 new_agent_position = agent_position+agent_direction*timing.delta*60.0;
    new_agent_position = close_position(new_agent_position);
    

    // Calculate new agent agent direction
    vec2 left_direction  = rotate(agent_direction,  params.sensors_angle);
    vec2 right_direction = rotate(agent_direction, -params.sensors_angle);

    vec2 sensor_forward = close_position( agent_position + agent_direction * params.sensors_distance );
    vec2 sensor_left    = close_position( agent_position + left_direction  * params.sensors_distance );
    vec2 sensor_right   = close_position( agent_position + right_direction * params.sensors_distance );

    float pheromone_forward = imageLoad(pheromone_image, ivec2(sensor_forward)).r;
    float pheromone_left    = imageLoad(pheromone_image, ivec2(sensor_left   )).r;
    float pheromone_right   = imageLoad(pheromone_image, ivec2(sensor_right  )).r;

    float detected_pheromone = 0.0;
    if (madness > 0.0) {
        detected_pheromone = min(pheromone_forward, min(pheromone_left, pheromone_right));
    } else {
        detected_pheromone = max(pheromone_forward, max(pheromone_left, pheromone_right));
    }
    // float madness_trigger = max(sign(detected_pheromone - params.madness_threshold), 0.0);
    // madness = (1.0 - madness_trigger) * max(0.0, madness-timing.delta) + madness_trigger * params.madness_duration;
    if (detected_pheromone > params.madness_threshold && agent_random < params.madness_chance * timing.delta * 60.0) {
        madness = params.madness_duration;
    } else {
        madness = max(0.0, madness-timing.delta);
    }
    
    vec2 new_agent_direction = agent_direction;
    if      (detected_pheromone == pheromone_left ) new_agent_direction = left_direction;
    else if (detected_pheromone == pheromone_right) new_agent_direction = right_direction;
    
    float rand_fac = agent_random*2.0 - 1.0;
    new_agent_direction = rotate(new_agent_direction, rand_fac * params.random_sensors_angle);

    imageStore(agents_pos_dir, invoc_vec, vec4(
        new_agent_position.x,
        new_agent_position.y,
        new_agent_direction.x,
        new_agent_direction.y
    ));
    imageStore(agents_props, invoc_vec, vec4(
        madness,
        props.g,
        props.b,
        props.a
    ));
}
