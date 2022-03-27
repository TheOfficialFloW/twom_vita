uniform float4 ComboDesaturationAlphaTest;

uniform float4 GlobalFogColor;

uniform sampler2D Texture0;

float4 main(
    float4 Varying_Color : TEXCOORD8,
    float2 Varying_UV : TEXCOORD0,
    float2 Varying_Fog : TEXCOORD1
) {
#ifdef DIFFUSE_TEXTURE
    float4 albedo = float4(tex2D(Texture0, Varying_UV));

    #ifdef ALPHA_TEST
        if (albedo.w * ComboDesaturationAlphaTest.y + ComboDesaturationAlphaTest.z < 0.0f)
            discard;
    #endif

#else
    float4 albedo = float4(1.0f,1.0f,1.0f,1.0f);
#endif

    albedo *= Varying_Color;

#ifdef FOG
    float fogFactor = clamp(max(Varying_Fog.x, GlobalFogColor.w), 0.0f, 1.0f);
#ifdef BLEND_ALPHA
    albedo.xyz = lerp(GlobalFogColor.xyz, albedo.xyz, fogFactor);
#else
    albedo*=fogFactor;
#endif
#endif

    return albedo;
}
