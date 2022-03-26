uniform sampler2D Texture0;

uniform float4 GlobalFogColor;

float4 main(
    float2 uv0Varying : TEXCOORD0,
    float4 colorVarying : COLOR0,
    float2 uvCutoffAndFog : TEXCOORD1
) {
	float4 color=colorVarying;

	if(uvCutoffAndFog.x<0.0f)
		discard;

#ifdef FOG
    float fogFactor = clamp(max(uvCutoffAndFog.y, GlobalFogColor.w), 0.f, 1.f);
    color.xyz = lerp(GlobalFogColor.xyz, color.xyz, uvCutoffAndFog.y);
#endif

#ifdef DIFFUSE_TEXTURE
    float4 txt = tex2D(Texture0, uv0Varying);
    color *= txt;
#endif

#ifdef FINAL_TARGET_NO_SRGB
	color.xyz = sqrt(color.xyz);
#endif

    return color;
}
