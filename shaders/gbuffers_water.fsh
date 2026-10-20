#version 150 compatibility

uniform sampler2D texture;
uniform sampler2D lightmap;
uniform vec3 sunPosition;
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

    // Detectar si el bloque en esta capa es agua (basado en el canal alfa y tinte de bioma)
    vec3 viewDir = normalize(-viewPos);
    vec3 normal = normalize(worldNormal);

    // Efecto Fresnel: más transparente al mirar hacia abajo, más reflectante a lo lejos
    float fresnel = pow(1.0 - max(dot(viewDir, normal), 0.0), 3.0);

    // Reflejo especular rápido del sol/luna sobre el agua
    vec3 sunDir = normalize(sunPosition);
    vec3 reflectDir = reflect(-sunDir, normal);
    float spec = pow(max(dot(viewDir, reflectDir), 0.0), 24.0) * lmcoord.y;

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
    vec3 skyReflectColor = vec3(0.65, 0.82, 0.95) * lmcoord.y;

    vec3 finalWaterColor = mix(waterBaseColor, skyReflectColor, fresnel * 0.55) * (light + torchLight);
    finalWaterColor += vec3(1.0, 0.95, 0.8) * spec * 0.7; // Brillo solar

    // Transparencia cristalina equilibrada (0.52 base, sube con el ángulo de visión)
    float alpha = clamp(0.52 + fresnel * 0.35, 0.45, 0.88);

    gl_FragData[0] = vec4(finalWaterColor, alpha);
}