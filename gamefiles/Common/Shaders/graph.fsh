uniform sampler2D   Texture0;

float4 main(
    float2 uvVarying : TEXCOORD0,
    float4 colorVarying : COLOR0
) {
    float4 gl_FragColor = float4(0, 0, 0, 0);

	float4 color = colorVarying;
	
#ifdef TEXTURE
	float4 txt = tex2D( Texture0, uvVarying );
	color *= txt;
#endif

    gl_FragColor = color;
    return gl_FragColor;
}

