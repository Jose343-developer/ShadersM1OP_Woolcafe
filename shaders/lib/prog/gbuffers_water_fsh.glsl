/* DRAWBUFFERS:0 */

#include "/lib/m1_common.glsl"

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform mat4 gbufferModelView;
uniform float frameTimeCounter;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 viewPos;
in vec3 viewNormal;
in vec3 worldPos;
in float waterTop;

void main() {
    vec4 tex = texture2D(texture, texcoord);
    vec3 light = m1Lightmap(lightmap, lmcoord);

    vec3 viewDir = -viewPos * inversesqrt(dot(viewPos, viewPos));
    vec3 normal = viewNormal;

    // Micro-ondas analíticas (solo 3 cos, sin texturas extra ni passes: seguro para M1)
    // Perturban la normal para que los reflejos brillen como cristal en movimiento
    if (waterTop > 0.5) {
        vec2 p = worldPos.xz;
        float t = frameTimeCounter;
        float diag = cos((p.x + p.y) * 3.3 - t * 2.2) * 0.4;
        float dx = cos(p.x * 2.1 + t * 1.6) * 0.6 + diag;
        float dz = cos(p.y * 2.4 - t * 1.3) * 0.6 + diag;
        vec3 rippleWorld = vec3(-dx * 0.07, 1.0, -dz * 0.07);
        rippleWorld *= inversesqrt(dot(rippleWorld, rippleWorld));
        normal = mat3(gbufferModelView) * rippleWorld;
    }

    // Fresnel Schlick (agua F0 ≈ 0.02); pow(x,5) con multiplicaciones, más barato que pow()
    float cosTheta = max(dot(viewDir, normal), 0.0);
    float f = 1.0 - cosTheta;
    float f2 = f * f;
    float fresnel = 0.02 + 0.98 * (f2 * f2 * f);

    // Reflejo especular del sol o luna: núcleo nítido + halo suave (aspecto cristalino)
    // dayFactor / celestialSign vienen precalculados de CPU
    vec3 celestialDir = sunPosition * (0.01 * celestialSign);
    vec3 reflectDir = reflect(-celestialDir, normal);
    float rDotV = max(dot(viewDir, reflectDir), 0.0);
    float soft = rDotV * rDotV;            // ^2
    soft *= soft; soft *= soft;            // ^8
    float sharpSpec = soft * soft;         // ^16
    sharpSpec *= sharpSpec;                // ^32
    sharpSpec *= sharpSpec;                // ^64 (destellos tipo cristal)
    float spec = (sharpSpec * 2.2 + soft * 0.18) * lmcoord.y;
    vec3 specColor = mix(vec3(0.65, 0.80, 1.0) * 0.45, vec3(1.0, 0.96, 0.85), dayFactor);

    // Luz de antorcha en mano o segunda mano reflejada suavemente en el agua
    vec3 torchLight = vec3(0.0);
    if (handLight > 0.0) {
        vec3 L; float dist;
        torchLight = TORCH_COLOR * (torchAtten(viewPos, L, dist) * handLight * 1.25);
    }

    // Color de agua cristalina: tono aguamarina limpio, la textura original solo aporta matiz del bioma
    vec3 waterBaseColor = mix(vec3(0.12, 0.58, 0.70), tex.rgb * glcolor.rgb, 0.22);
    vec3 skyReflectColor = mix(vec3(0.25, 0.38, 0.58), vec3(0.70, 0.86, 0.98), dayFactor) * lmcoord.y;

    vec3 finalWaterColor = mix(waterBaseColor, skyReflectColor, fresnel * 0.75) * (light + torchLight);
    finalWaterColor += specColor * spec;

    // Transparencia cristalina: muy clara al mirar hacia abajo, reflectante en ángulos rasantes;
    // los destellos suben la opacidad para que se vean nítidos
    float alpha = clamp(0.30 + fresnel * 0.60 + sharpSpec * 0.5, 0.28, 0.90);

    gl_FragData[0] = vec4(finalWaterColor, alpha);
}