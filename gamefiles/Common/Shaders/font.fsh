uniform sampler2D Texture0;
uniform float4 OutlineColor;

float4 main(
    float4 colorVarying : TEXCOORD8,
    float2 uv0Varying : TEXCOORD0
) {
    float4 color=colorVarying;
    float4 txt=tex2D(Texture0,uv0Varying.xy);
    
#ifdef OUTLINES
    float4 outlineColor 	= OutlineColor;
    color 	= lerp( outlineColor, color, txt.x );
    color.w	*= txt.x + txt.g;
#else
    color.w *= txt.w;
#endif

#ifdef FINAL_TARGET_NO_SRGB
	color.xyz = sqrt(color.xyz);
#endif
    return color;
}
