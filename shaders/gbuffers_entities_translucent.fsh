#version 150 compatibility

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform vec4 entityColor;

uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;
uniform int worldTime;
uniform vec3 sunPosition;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 viewPos;
in vec3 worldNormal;

void main() {
    vec4 albedo = texture2D(texture, texcoord) * glcolor;

    // Overlay de daño / golpe
    albedo.rgb = mix(albedo.rgb, entityColor.rgb, entityColor.a);

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
        
        vec3 lightDir = normalize(toLight);
        float NdotL = clamp(dot(worldNormal, lightDir) * 0.45 + 0.55, 0.0, 1.0);
        
        float playerProximity = smoothstep(5.0, 1.0, dist);
        float baseIntensity = mix(atten, max(atten, 0.65), playerProximity);
        
        float dynamicTorch = baseIntensity * NdotL * (maxHandLight / 15.0);
        torchColor = vec3(1.0, 0.70, 0.38) * dynamicTorch * 1.25;
    }

    // 3. Sol y Noche atmosféricos
    vec3 sunDir = normalize(sunPosition);
    float dayFactor = clamp(sunDir.y * 2.0, 0.0, 1.0);
    float nightFactor = clamp(-sunDir.y * 2.0, 0.0, 1.0);
    float sunsetFactor = clamp(1.0 - abs(sunDir.y * 3.0), 0.0, 1.0);

    vec3 sunTint = vec3(1.05, 0.98, 0.88) * dayFactor;
    vec3 sunsetTint = vec3(1.15, 0.72, 0.45) * sunsetFactor;
    vec3 nightTint = vec3(0.42, 0.52, 0.78) * nightFactor;

    vec3 skyColorEnhancement = mix(vec3(1.0), sunTint + sunsetTint + nightTint, lmcoord.y * 0.45);
    
    float sunNdotL = max(dot(worldNormal, sunDir), 0.0) * lmcoord.y * dayFactor * 0.2;

    vec3 finalLight = (baseLight * skyColorEnhancement) + torchColor + sunNdotL;

    gl_FragData[0] = vec4(albedo.rgb * finalLight, albedo.a);
}
