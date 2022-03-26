uniform sampler2D Texture0;

uniform float4 AnimationFrameFactor;
uniform float4 AlphaTest;

uniform float4 GlobalGBufferScale;
uniform float4 GlobalGBufferOffset;

float4 main(
    float4 uv0Varying : TEXCOORD0,
    float4 colorVarying : COLOR0,
    float4 gl_FragCoord : WPOS
) {
    float4 gl_FragColor = float4(0, 0, 0, 0);

	float4 color=colorVarying;
    float4 txt=tex2D(Texture0,uv0Varying.xy);

#ifdef TEXTURE_ANIMATION
    float4 txt2=tex2D(Texture0,uv0Varying.zw);
    txt=lerp(txt,txt2,AnimationFrameFactor.x);
#endif
    
#ifdef ALPHA_TEST
    if(txt.w*AlphaTest.x+AlphaTest.y<0.0)
        discard;
#endif

    color *= txt;
    
    float2 bufferUV = gl_FragCoord.xy*GlobalGBufferScale.xy+GlobalGBufferOffset.xy;

	gl_FragColor=color;
    return gl_FragColor;
}
