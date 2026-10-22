/* DRAWBUFFERS:0 */

// Sol y luna redondos 100% procedurales.
// Coste: solo afecta a los ~pocos cientos de píxeles del disco, 0 texturas extra.

uniform sampler2D texture;
uniform int renderStage;
uniform int moonPhase;        // 0 = llena ... 4 = nueva ... 7
uniform float sunsetFactor;   // custom uniform (shaders.properties)

in vec2 texcoord;
in vec4 glcolor;
in vec2 quadPos;

void main() {
    vec4 tex = texture2D(texture, texcoord);

    bool isSun = false;
    bool isMoon = false;
#if defined(MC_RENDER_STAGE_SUN) && defined(MC_RENDER_STAGE_MOON)
    isSun  = renderStage == MC_RENDER_STAGE_SUN;
    isMoon = renderStage == MC_RENDER_STAGE_MOON;
#endif

    float d = length(quadPos);
    float aa = fwidth(d) * 1.5;   // borde antialiased (sin MSAA)
    vec3 col;

    if (isSun) {
        // Disco con oscurecimiento de borde (limb darkening) + halo suave
        const float R = 0.42;
        float core = 1.0 - smoothstep(R - aa, R + aa, d);
        float limb = 0.80 + 0.20 * sqrt(max(1.0 - (d * d) / (R * R), 0.0));
        float g = max(1.0 - d, 0.0);
        float glow = g * g * g;

        vec3 sunCol = mix(vec3(1.0, 0.95, 0.85), vec3(1.0, 0.60, 0.28), sunsetFactor);
        col = sunCol * (core * limb * 1.6 + glow * 0.45);

    } else if (isMoon) {
        // Esfera iluminada según la fase lunar real del juego
        const float R = 0.50;
        vec2 q = quadPos / R;
        float r2 = dot(q, q);
        float disk = 1.0 - smoothstep(1.0 - aa / R, 1.0 + aa / R, sqrt(r2));

        vec3 n = vec3(q, sqrt(max(1.0 - r2, 0.0)));
        float ph = float(moonPhase) * 0.7853982;          // 2π / 8
        vec3 sunL = vec3(sin(ph), 0.0, cos(ph));
        float lit = smoothstep(-0.06, 0.12, dot(n, sunL));

        // "Mares" lunares baratos (2 senos) para que no sea un disco plano
        float maria = 0.86 + 0.14 * sin(q.x * 6.5 + 1.3) * sin(q.y * 5.5 - 0.7);

        float phaseBright = 0.5 + 0.5 * cos(ph);          // halo más fuerte en luna llena
        float g = max(1.0 - d, 0.0);

        col = vec3(0.86, 0.90, 1.0) * (disk * lit * maria)
            + vec3(0.35, 0.45, 0.70) * (g * g * g * 0.25 * phaseBright);

    } else {
#ifdef M1_END
        // End minimalista: lavanda oscuro y tenue, sin textura ni detalles.
        const vec3 END_SKY = vec3(0.085, 0.078, 0.112);
        vec4 c = tex * glcolor;
        bool isEndSky = true;
    #ifdef MC_RENDER_STAGE_CUSTOM_SKY
        isEndSky = renderStage == MC_RENDER_STAGE_CUSTOM_SKY;
    #endif
        if (isEndSky) {
            gl_FragData[0] = vec4(END_SKY, c.a);
        } else {
            // Otros elementos del cielo (End flashes): desaturados y suaves
            float y = dot(c.rgb, vec3(0.299, 0.587, 0.114));
            gl_FragData[0] = vec4(y * vec3(0.55, 0.52, 0.65), c.a);
        }
#else
        // Skies personalizados: sin cambios
        gl_FragData[0] = tex * glcolor;
#endif
        return;
    }

    // Mezcla aditiva de vanilla (SRC_ALPHA, ONE): negro = transparente.
    // glcolor.a atenúa sol/luna con la lluvia.
    gl_FragData[0] = vec4(col * glcolor.rgb, glcolor.a);
}
