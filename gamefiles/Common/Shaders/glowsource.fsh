uniform sampler2D Texture0;

float4 main(
    float4 uv0Varying : TEXCOORD0,
    float4 uv1Varying : TEXCOORD1
) {
    float4 color=tex2D(Texture0,uv0Varying.xy);
    color+=tex2D(Texture0,uv0Varying.zw);
    color+=tex2D(Texture0,uv1Varying.xy);
    color+=tex2D(Texture0,uv1Varying.zw);
	
    color*=0.25f;
    color.w = 0.0f;

    return color;
}

