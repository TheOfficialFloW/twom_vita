uniform sampler2D Texture0;

float4 main(
    float2 uv0Varying : TEXCOORD0,
    float4 colorVarying : COLOR0
) {
    float4 color=colorVarying;
    
#ifndef NO_TEXTURE
    float4 txt=tex2D(Texture0,uv0Varying.xy);
#ifdef ALPHA_ONLY_TEXTURE
    color.w*=txt.w;
#elif defined(COLOR_ONLY_TEXTURE)
    color.xyz*=txt.xyz;
#else
    color*=txt;
#endif
#endif

#if defined(FINAL_TARGET_NO_SRGB)
	color.xyz = sqrt(color.xyz);
#endif
    return color;
}
