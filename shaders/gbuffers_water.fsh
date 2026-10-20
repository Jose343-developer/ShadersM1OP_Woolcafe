#version 150 compatibility

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform vec3 sunPosition;
uniform vec3 upPosition;
uniform mat4 gbufferModelView;
uniform int heldBlockLightValue;
uniform int heldBlockLightValue2;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 viewPos;
in vec3 worldNormal;

void main() {
    vec4 tex = texture2D(texture, texcoord);
    vec3 light = texture2D(lightmap, lmcoord).rgb;

    vec3 viewDir = normalize(-viewPos);
    vec3 normal = length(worldNormal) > 0.001 ? normalize(worldNormal) : vec3(0.0, 1.0, 0.0);

    // Efecto Fresnel: más transparente al mirar hacia abajo, más reflectante a lo lejos
    float fresnel = pow(1.0 - max(dot(viewDir, normal), 0.0), 3.0);

    // Orientación celeste invariante a la rotación de cámara
    vec3 sunDir = normalize(sunPosition);
    vec3 upDir = length(upPosition) > 0.001 ? normalize(upPosition) : (length(gbufferModelView[1].xyz) > 0.001 ? normalize(gbufferModelView[1].xyz) : vec3(0.0, 1.0, 0.0));
    float SdotU = dot(sunDir, upDir);

    float dayFactor = clamp((SdotU + 0.05) / 0.15, 0.0, 1.0);
    float nightFactor = 1.0 - dayFactor;

    // Reflejo especular del sol o luna sobre el agua
    vec3 celestialDir = (SdotU >= 0.0) ? sunDir : -sunDir;
    vec3 reflectDir = reflect(-celestialDir, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 24.0) * lmcoord.y;
    vec3 specColor = mix(vec3(0.65, 0.80, 1.0) * 0.45, vec3(1.0, 0.95, 0.8) * 0.75, dayFactor);

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

    // Color de agua cristalina estética (mezcla la textura original sutilmente con azul turquesa)
    vec3 waterBaseColor = mix(vec3(0.08, 0.48, 0.62), tex.rgb * glcolor.rgb, 0.35);
    vec3 skyReflectColor = mix(vec3(0.25, 0.38, 0.58), vec3(0.65, 0.82, 0.95), dayFactor) * lmcoord.y;

    vec3 finalWaterColor = mix(waterBaseColor, skyReflectColor, fresnel * 0.55) * (light + torchLight);
    finalWaterColor += specColor * spec;

    // Transparencia cristalina equilibrada (0.52 base, sube con el ángulo de visión)
    float alpha = clamp(0.52 + fresnel * 0.35, 0.45, 0.88);

    gl_FragData[0] = vec4(finalWaterColor, alpha);
}