#version 150 compatibility

/* DRAWBUFFERS:0 */

#include "/lib/m1_common.glsl"

uniform sampler2D texture;
uniform sampler2D lightmap;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 viewPos;
in vec3 viewNormal;
in vec3 skyMul;
in float celestialLight;

void main() {
    vec4 albedo = texture2D(texture, texcoord) * glcolor;

    // SIN 'discard' a propósito: Iris aplica el alpha test solo a la geometría
    // cutout (hojas, pasto). Así el terreno sólido conserva el Hidden Surface
    // Removal del GPU M1 y no se sombrean píxeles ocultos.

    // Luz base * tinte de cielo (por vértice) + difusa sol/luna (por vértice)
    vec3 light = texture2D(lightmap, lmcoord).rgb * skyMul + celestialLight;

    // Antorcha en mano (rama uniforme: coherente en toda la GPU, sin divergencia)
    if (handLight > 0.0) {
        vec3 L; float dist;
        float atten = torchAtten(viewPos, L, dist);
        // Orientación de la cara rompe el círculo plano de luz
        float NdotL = clamp(dot(viewNormal, L) * 0.45 + 0.55, 0.0, 1.0);
        light += TORCH_COLOR * (atten * NdotL * handLight * 1.25);
    }

    gl_FragData[0] = vec4(albedo.rgb * light, albedo.a);
}