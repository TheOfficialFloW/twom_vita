#if defined(TEXTURE)
uniform sampler2D Texture0;
#endif

float4 main(
#if defined(TEXTURE)
    float2 uv0Varying : TEXCOORD0,
#endif
    float4 colorVarying : TEXCOORD8
) {
    float4 color = colorVarying;

#ifdef TEXTURE
    float4 txt = tex2D(Texture0, uv0Varying);

#ifdef ALPHA_ONLY_TEXTURE
    color.w *= txt.w;
#elif defined(COLOR_ONLY_TEXTURE)
    color.xyz *= txt.xyz;
#else
    color *= txt;
#endif
#endif

    return color;
}
