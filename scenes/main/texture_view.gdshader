shader_type canvas_item;

uniform sampler2D gradient;

void fragment() {
	COLOR = texture(gradient, vec2(COLOR.r,0.0));
}
