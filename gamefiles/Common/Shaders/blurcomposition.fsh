uniform sampler2D Texture0;

float4 main(
    float2 screenPosVarying : TEXCOORD0
) {
    float4 gl_FragColor = float4(0, 0, 0, 0);

    // czy wlasciwie potrzebne?
    float2 uv = screenPosVarying;
    
    // flip
    //uv.y = 1.0 - uv.y;
    
    // proper color
    float4 color = float4(tex2D(Texture0,uv).xyz,1.0);
    
    gl_FragColor = color;
    return gl_FragColor;
}
