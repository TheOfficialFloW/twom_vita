uniform sampler2D Texture0;

float4 main(
    float4 uv0Varying : TEXCOORD0,
    float4 uv1Varying : TEXCOORD1
) {
    float4 gl_FragColor = float4(0, 0, 0, 0);
	
	float4 color=tex2D(Texture0,uv0Varying.xy);
	color+=tex2D(Texture0,uv0Varying.zw);
	color+=tex2D(Texture0,uv1Varying.xy);
	color+=tex2D(Texture0,uv1Varying.zw);
	
	color*=0.25;
    color.w = 0.0;
    
	gl_FragColor=color;
    return gl_FragColor;
}

