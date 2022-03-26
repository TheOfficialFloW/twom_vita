float4 main(
    float2 Varying_ToneMap : TEXCOORD0
) {
    return float4(Varying_ToneMap.x,Varying_ToneMap.x,1.0f,1.0f);
}
