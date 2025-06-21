shader_type canvas_item;

uniform sampler2D gradient_texture;

void fragment() {
	COLOR.rgb = texture(gradient_texture, vec2(1.0-UV.y,0.0)).rgb;
}
