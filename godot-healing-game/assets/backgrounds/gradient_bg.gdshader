shader_type canvas_item;

uniform vec4 top_color : source_color = vec4(0.91, 0.784, 0.627, 1.0);
uniform vec4 bottom_color : source_color = vec4(0.42, 0.357, 0.31, 1.0);

void fragment() {
	float t = UV.y;
	COLOR = mix(bottom_color, top_color, t);
}
