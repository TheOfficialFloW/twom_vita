uniform sampler2D Texture0;

float4 main(
    float2 screenPosVarying : TEXCOORD0
) {
    // czy wlasciwie potrzebne?
    float2 uv = screenPosVarying;

    // flip
    //uv.y = 1.0f - uv.y;

    // proper color
    return float4(tex2D(Texture0,uv).xyz,1.0f);
}
