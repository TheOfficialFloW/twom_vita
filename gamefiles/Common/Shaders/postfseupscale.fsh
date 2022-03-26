uniform sampler2D Texture0;

float4 main(
    float2 uv0Varying : TEXCOORD0
) {
    float4 gl_FragColor = float4(0, 0, 0, 0);

	float4 txt=tex2D(Texture0,uv0Varying);
	gl_FragColor=txt;
    return gl_FragColor;
}
