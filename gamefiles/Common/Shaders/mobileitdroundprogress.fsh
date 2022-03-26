uniform sampler2D Texture0;

#if defined(FINAL_TARGET_NO_SRGB)
	#define FINALIZE_SRGB gl_FragColor.xyz = sqrt(gl_FragColor.xyz);
#else
	#define FINALIZE_SRGB
#endif

uniform float4 GlobalFogColor;

float4 main(
    float2 uv0Varying : TEXCOORD0,
    float4 colorVarying : COLOR0,
    float2 uvCutoffAndFog : TEXCOORD1
) {
    float4 gl_FragColor = float4(0, 0, 0, 0);

	float4 color=colorVarying;

	if(uvCutoffAndFog.x<0.0)
		discard;

#ifdef FOG
    float fogFactor = clamp(max(uvCutoffAndFog.y, GlobalFogColor.w), 0., 1.);
    color.xyz = lerp(GlobalFogColor.xyz, color.xyz, uvCutoffAndFog.y);
#endif

#ifdef DIFFUSE_TEXTURE
    float4 txt = tex2D(Texture0, uv0Varying);
    color *= txt;
#endif
    
	gl_FragColor=color;

	FINALIZE_SRGB
    return gl_FragColor;
}
