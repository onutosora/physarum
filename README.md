# Physarum algorithm
Physarum algorithm implemented in godot via compute shaders.

## How it works
The main logic is made via compute shaders and written in glsl.
There are four compute shader modules:
- Pheromone fading
- Pheromone diffusion
- Agents behavior
- Render

## Details
- Amount of agents is [0, 360000].
- High performance at any number of agents.
- Customizable parameters of pheromone field and agents.

## TODO
- [ ] Customizable color gradient.
- [ ] More agents behavior parameters.
