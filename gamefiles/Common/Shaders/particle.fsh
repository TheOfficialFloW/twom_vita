uniform sampler2D Texture0;
uniform sampler2D Texture10;

#define BW float3(0.2126, 0.7152, 0.0722)

uniform float4 GlobalFogColor;

uniform float4 ComboDesaturationAlphaTest;

float4 main(
    float4 colorVarying : COLOR0,
    float4 uv0Varying : TEXCOORD0,
    float2 frameFactorFog : TEXCOORD1
) {
    float4 gl_FragColor = float4(0, 0, 0, 0);
    
    float4 color = colorVarying;
    float4 txt=tex2D(Texture0,uv0Varying.xy);
    
#ifdef ALPHA_TEST
    if((txt.w*color.w*ComboDesaturationAlphaTest.y+ComboDesaturationAlphaTest.z) < 0.0)
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
    float fogFactor = clamp( max( frameFactorFog.y, GlobalFogColor.w ), 0.0, 1.0 );
#ifdef BLEND_ALPHA
    color.xyz = lerp( GlobalFogColor.xyz, color.xyz, fogFactor );
#else
    color.xyzw *= fogFactor;
#endif
#endif
    
    gl_FragColor=color;
    return gl_FragColor;
}
