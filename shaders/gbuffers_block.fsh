#version 150 compatibility

uniform sampler2D texture;
uniform sampler2D lightmap;

uniform int heldBlockLightValue;
uniform int heldBlockLightValue2; // Segunda mano (Off-hand)
uniform int worldTime;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform mat4 gbufferModelView;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 viewPos;
in vec3 worldNormal;

void main() {
    vec4 albedo = texture2D(texture, texcoord) * glcolor;
    if (albedo.a < 0.1) discard;

    vec3 normal = length(worldNormal) > 0.001 ? normalize(worldNormal) : vec3(0.0, 1.0, 0.0);

    // 1. Luz base del juego
    vec3 baseLight = texture2D(lightmap, lmcoord).rgb;

    // 2. Luz de antorcha en mano principal y segunda mano (Off-hand)
    float maxHandLight = max(float(heldBlockLightValue), float(heldBlockLightValue2));
    vec3 torchColor = vec3(0.0);
    
    if (maxHandLight > 0.0) {
        vec3 torchPos = vec3(heldBlockLightValue2 > heldBlockLightValue ? -0.35 : 0.35, -0.35, -0.2);
        vec3 toLight = torchPos - viewPos;
        float dist = length(toLight);
        
        float maxRadius = maxHandLight * 1.1;
        float normDist = clamp(dist / maxRadius, 0.0, 1.0);
        float edgeFade = 1.0 - smoothstep(0.35, 1.0, normDist);
        float atten = (1.0 / (1.0 + 0.35 * dist + 0.06 * dist * dist)) * edgeFade;
        
        vec3 torchDir = normalize(toLight);
        float NdotL = clamp(dot(normal, torchDir) * 0.45 + 0.55, 0.0, 1.0);
        
        float dynamicTorch = atten * NdotL * (maxHandLight / 15.0);
        torchColor = vec3(1.0, 0.70, 0.38) * dynamicTorch * 1.25;
    }

    // 3. Orientación celeste invariante a la rotación de cámara
    vec3 sunDir = normalize(sunPosition);
    vec3 upDir = length(upPosition) > 0.001 ? normalize(upPosition) : (length(gbufferModelView[1].xyz) > 0.001 ? normalize(gbufferModelView[1].xyz) : vec3(0.0, 1.0, 0.0));
    
    // SdotU: producto punto entre sol y cenit en espacio de vista (100% independiente de dónde mire el jugador)
    float SdotU = dot(sunDir, upDir);

    // Factores astronómicos suaves y continuos
    float dayFactor = clamp((SdotU + 0.05) / 0.15, 0.0, 1.0);
    float nightFactor = 1.0 - dayFactor;
    float sunsetFactor = clamp(1.0 - abs(SdotU) * 6.5, 0.0, 1.0);

    // Tintes atmosféricos según la hora y la exposición al cielo (lmcoord.y)
    vec3 dayTint = vec3(1.05, 0.98, 0.88);
    vec3 sunsetTint = vec3(1.18, 0.74, 0.46);
    vec3 nightTint = vec3(0.60, 0.72, 1.05);

    vec3 skyTint = mix(nightTint, dayTint, dayFactor);
    skyTint = mix(skyTint, sunsetTint, sunsetFactor);

    vec3 skyColorEnhancement = mix(vec3(1.0), skyTint, lmcoord.y * 0.45);
    
    // Iluminación direccional de sol / luna según orientación de caras
    vec3 celestialDir = (SdotU >= 0.0) ? sunDir : -sunDir;
    float celestialNdotL = max(dot(normal, celestialDir), 0.0);
    float celestialLight = celestialNdotL * lmcoord.y * (dayFactor * 0.20 + nightFactor * 0.04);

    // Combinación final de luces
    vec3 finalLight = (baseLight * skyColorEnhancement) + torchColor + celestialLight;

    gl_FragData[0] = vec4(albedo.rgb * finalLight, albedo.a);
}
