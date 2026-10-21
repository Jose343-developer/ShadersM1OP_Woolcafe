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
    if (albedo.a < 0.1) discard;

    // En primera persona la mano porta directamente la fuente de luz (sin atenuación)
    vec3 light = texture2D(lightmap, lmcoord).rgb * skyMul + celestialLight
               + TORCH_COLOR * (handLight * 1.25);

    // Si el jugador sostiene una antorcha, la mano y el objeto nunca quedan en negro
    light = max(light, vec3(0.95, 0.70, 0.38) * handLight);

    gl_FragData[0] = vec4(albedo.rgb * light, albedo.a);
}
