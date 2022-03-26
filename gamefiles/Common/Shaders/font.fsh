uniform sampler2D Texture0;

#if defined(FINAL_TARGET_NO_SRGB)
	#define FINALIZE_SRGB gl_FragColor.xyz = sqrt(gl_FragColor.xyz);
#else
	#define FINALIZE_SRGB
#endif

uniform float4 OutlineColor;

float4 main(
    float4 colorVarying : COLOR0,
    float2 uv0Varying : TEXCOORD0
) {
    float4 gl_FragColor = float4(0, 0, 0, 0);

    float4 color=colorVarying;
    float4 txt=tex2D(Texture0,uv0Varying.xy);
    
#ifdef OUTLINES
    float4 outlineColor 	= OutlineColor;
    color 	= lerp( outlineColor, color, txt.x );
    color.w	*= txt.x + txt.g;
#else
    color.w *= txt.w;
#endif
    gl_FragColor=color;

	FINALIZE_SRGB
    return gl_FragColor;
}
