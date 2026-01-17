shader_type canvas_item;

uniform vec4 line_color : source_color = vec4(1.0);
uniform float line_thickness : hint_range(0.0, 10.0) = 0.0; // 0 é sem contorno
uniform float flash_modifier : hint_range(0.0, 1.0) = 0.0; // 1 é totalmente branco

void fragment() {
    vec2 size = TEXTURE_PIXEL_SIZE * line_thickness;
    float outline = 0.0;

    outline += texture(TEXTURE, UV + vec2(-size.x, 0.0)).a;
    outline += texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
    outline += texture(TEXTURE, UV + vec2(0.0, -size.y)).a;
    outline += texture(TEXTURE, UV + vec2(0.0, size.y)).a;
    outline = min(outline, 1.0);

    vec4 color = texture(TEXTURE, UV);
    // Aplica o contorno
    vec4 final_color = mix(color, line_color, outline - color.a);
    // Aplica o flash (piscar)
    final_color.rgb = mix(final_color.rgb, vec3(1,1,1), flash_modifier);

    COLOR = final_color;
}