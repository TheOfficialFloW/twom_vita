float4 main(
    float Varying_ToneMap : TEXCOORD0
) {
    float4 gl_FragColor = float4(0, 0, 0, 0);

    gl_FragColor = float4(Varying_ToneMap,Varying_ToneMap,1.0,1.0);
    return gl_FragColor;
}
