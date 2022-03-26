uniform float4 ComboDesaturationAlphaTest;

uniform float4 GlobalFogColor;

uniform sampler2D Texture0;

float4 main(
    float4 Varying_Color : COLOR0,
    float2 Varying_UV : TEXCOORD0,
    float Varying_Fog : TEXCOORD1
) {
    float4 gl_FragColor = float4(0, 0, 0, 0);

#ifdef DIFFUSE_TEXTURE
    float4 albedo = float4(tex2D(Texture0, Varying_UV));
    
    #ifdef ALPHA_TEST
        if (albedo.w * ComboDesaturationAlphaTest.y + ComboDesaturationAlphaTest.z < 0.0)
            discard;
    #endif
    
#else
    float4 albedo = float4(1.0,1.0,1.0,1.0);
#endif
    
    albedo *= Varying_Color;
    
#ifdef FOG
    float fogFactor = clamp(max(Varying_Fog, GlobalFogColor.w), 0.0, 1.0);
#ifdef BLEND_ALPHA
    albedo.xyz = lerp(GlobalFogColor.xyz, albedo.xyz, fogFactor);
#else
    albedo*=fogFactor;
#endif
#endif
    
    gl_FragColor = albedo;
    return gl_FragColor;
}
