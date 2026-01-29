shader_type canvas_item;

// Textura de ruído gerada pela Godot
uniform sampler2D noise_img : repeat_enable;
// Velocidade do vento (X e Y)
uniform vec2 speed = vec2(0.03, 0.01);
// Escala das nuvens (quanto menor, maiores as nuvens)
uniform float density = 0.5;
// Força da sombra (0.0 a 1.0)
uniform float shadow_strength : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	// Faz o movimento baseado no tempo e na velocidade
	vec2 uv = UV * density + (TIME * speed);
	
	// Lê o valor do ruído (0.0 a 1.0)
	float noise_value = texture(noise_img, uv).r;
	
	// Cria um contraste para as nuvens ficarem com bordas mais definidas ou suaves
	// Ajuste o 0.4 e 0.6 para mudar a "grossura" das nuvens
	float mask = smoothstep(0.4, 0.6, noise_value);
	
	// Define a cor da sombra (preto com a intensidade escolhida)
	// Onde for 1.0 no mask, aplica a sombra
	vec4 shadow_color = vec4(0.0, 0.0, 0.0, mask * shadow_strength);
	
	COLOR = shadow_color;
}