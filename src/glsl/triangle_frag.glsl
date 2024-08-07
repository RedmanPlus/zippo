#version 410 core

in vec3 v_Color;
in vec2 TexCoord;

out vec4 FragColor;

uniform sampler2D ourTexture;

void main() {
    FragColor = texture(ourTexture, TexCoord) * vec4(v_Color, 1.0);
}

