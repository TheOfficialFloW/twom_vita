uniform sampler2D Texture0; // Y
uniform sampler2D Texture1; // U
uniform sampler2D Texture2; // V

float4 main(
    float2 uv0Varying : TEXCOORD0
) {
	float colorY = tex2D( Texture0, uv0Varying.xy ).x;
	float colorU = tex2D( Texture1, uv0Varying.xy ).x;
	float colorV = tex2D( Texture2, uv0Varying.xy ).x;

	colorY = 1.1643f * ( colorY - 0.0625f );
	colorU -= 0.5f;
	colorV -= 0.5f;

	// YUV to RGB color conversion
	float3 color;
	color.x = colorY + colorV * 1.5958f;
	color.y = colorY - colorU * 0.39173f - colorV * 0.81290f;
	color.z = colorY + colorU * 2.017f;

    return float4( clamp( color.xyz, 0.f, 1.f ), 1.f );
}