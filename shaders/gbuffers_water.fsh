#version 150 compatibility

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform mat4 gbufferModelView;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
uniform float frameTimeCounter;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 viewPos;
in vec3 worldNormal;
in vec3 worldPos;
in float waterTop;

void main() {
    vec4 tex = texture2D(texture, texcoord);
    vec3 light = texture2D(lightmap, lmcoord).rgb;

    vec3 viewDir = normalize(-viewPos);
    vec3 normal = length(worldNormal) > 0.001 ? normalize(worldNormal) : vec3(0.0, 1.0, 0.0);

    // Micro-ondas analíticas (solo 3 cos, sin texturas extra ni passes: seguro para M1)
    // Perturban la normal para que los reflejos brillen como cristal en movimiento
    if (waterTop > 0.5) {
        vec2 p = worldPos.xz;
        float t = frameTimeCounter;
        float diag = cos((p.x + p.y) * 3.3 - t * 2.2) * 0.4;
        float dx = cos(p.x * 2.1 + t * 1.6) * 0.6 + diag;
        float dz = cos(p.y * 2.4 - t * 1.3) * 0.6 + diag;
        vec3 rippleWorld = normalize(vec3(-dx * 0.07, 1.0, -dz * 0.07));
        normal = normalize(mat3(gbufferModelView) * rippleWorld);
    }

    // Fresnel Schlick (agua F0 ≈ 0.02); pow(x,5) con multiplicaciones, más barato que pow()
    float cosTheta = max(dot(viewDir, normal), 0.0);
    float f = 1.0 - cosTheta;
    float f2 = f * f;
    float fresnel = 0.02 + 0.98 * (f2 * f2 * f);

    // Orientación celeste invariante a la rotación de cámara
    vec3 sunDir = normalize(sunPosition);
    vec3 upDir = length(upPosition) > 0.001 ? normalize(upPosition) : (length(gbufferModelView[1].xyz) > 0.001 ? normalize(gbufferModelView[1].xyz) : vec3(0.0, 1.0, 0.0));
    float SdotU = dot(sunDir, upDir);

    float dayFactor = clamp((SdotU + 0.05) / 0.15, 0.0, 1.0);

    // Reflejo especular del sol o luna: núcleo nítido + halo suave (aspecto cristalino)
    vec3 celestialDir = (SdotU >= 0.0) ? sunDir : -sunDir;
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
    float maxHandLight = max(float(heldBlockLightValue), float(heldBlockLightValue2));
    vec3 torchLight = vec3(0.0);
    
    if (maxHandLight > 0.0) {
        vec3 torchPos = vec3(heldBlockLightValue2 > heldBlockLightValue ? -0.35 : 0.35, -0.35, -0.2);
        vec3 toLight = torchPos - viewPos;
        float dist = length(toLight);
        
        float maxRadius = maxHandLight * 1.1;
        float normDist = clamp(dist / maxRadius, 0.0, 1.0);
        float edgeFade = 1.0 - smoothstep(0.35, 1.0, normDist);
        float atten = (1.0 / (1.0 + 0.35 * dist + 0.06 * dist * dist)) * edgeFade;
        
        torchLight = vec3(1.0, 0.70, 0.38) * atten * (maxHandLight / 15.0) * 1.25;
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