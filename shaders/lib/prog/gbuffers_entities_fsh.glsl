/* DRAWBUFFERS:0 */

#include "/lib/m1_common.glsl"

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform vec4 entityColor; // Tinte de daño (parpadeo rojo) y efectos de entidad

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

    // Overlay de daño / golpe (parpadeo rojo de la entidad)
    albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);

    vec3 light = m1Lightmap(lightmap, lmcoord) * skyMul + celestialLight;

    if (handLight > 0.0) {
        vec3 L; float dist;
        float atten = torchAtten(viewPos, L, dist);
        float NdotL = clamp(dot(viewNormal, L) * 0.45 + 0.55, 0.0, 1.0);

        // Transición suave para el modelo del jugador en F5 / inventario
        float playerProximity = smoothstep(5.0, 1.0, dist);
        float baseIntensity = mix(atten, max(atten, 0.65), playerProximity);

        light += TORCH_COLOR * (baseIntensity * NdotL * handLight * 1.25);
    }

    gl_FragData[0] = vec4(albedo.rgb * light, albedo.a);
}
