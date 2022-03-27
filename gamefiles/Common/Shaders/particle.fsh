uniform sampler2D Texture0;

#define BW float3(0.2126f, 0.7152f, 0.0722f)

uniform float4 GlobalFogColor;

uniform float4 ComboDesaturationAlphaTest;

float4 main(
    float4 colorVarying : TEXCOORD8,
    float4 uv0Varying : TEXCOORD0,
    float2 frameFactorFog : TEXCOORD1
) {
    float4 color = colorVarying;
    float4 txt=tex2D(Texture0,uv0Varying.xy);

#ifdef ALPHA_TEST
    if((txt.w*color.w*ComboDesaturationAlphaTest.y+ComboDesaturationAlphaTest.z) < 0.0f)
        discard;
#endif

#ifdef TEXTURE_FRAME_INTERPOLATION
    float4 txt2 = tex2D(Texture0,uv0Varying.zw);
    txt = lerp(txt,txt2,frameFactorFog.x);
#endif

#ifdef TEXTURE_DESATURATION
    float intensity = dot(txt.xyz,BW);
    float desaturationPower = ComboDesaturationAlphaTest.x;
    txt.xyz = lerp(txt.xyz,float3(intensity,intensity,intensity),desaturationPower);
#endif

    color *= txt;

#ifdef FOG
    float fogFactor = clamp( max( frameFactorFog.y, GlobalFogColor.w ), 0.0f, 1.0f );
#ifdef BLEND_ALPHA
    color.xyz = lerp( GlobalFogColor.xyz, color.xyz, fogFactor );
#else
    color.xyzw *= fogFactor;
#endif
#endif

    return color;
}
