uniform sampler2D Texture0; // Y
uniform sampler2D Texture1; // U
uniform sampler2D Texture2; // V

float4 main(
    float2 uv0Varying : TEXCOORD0
) {
    float4 gl_FragColor = float4(0, 0, 0, 0);

	float colorY = tex2D( Texture0, uv0Varying.xy ).x;
	float colorU = tex2D( Texture1, uv0Varying.xy ).x;
	float colorV = tex2D( Texture2, uv0Varying.xy ).x;

	colorY = 1.1643 * ( colorY - 0.0625 );
	colorU -= 0.5;
	colorV -= 0.5;

	// YUV to RGB color conversion
	float3 color;
	color.x = colorY + colorV * 1.5958;
	color.y = colorY - colorU * 0.39173 - colorV * 0.81290;
	color.z = colorY + colorU * 2.017;

	gl_FragColor = float4( clamp( color.xyz, 0., 1. ), 1. );
    return gl_FragColor;
}