void main(
    float3 Position,
    float2 UV0,

    float2 out uv0Varying : TEXCOORD0,
    float4 out gl_Position : POSITION
) {
    gl_Position=float4(Position,1.0f);
    uv0Varying = UV0;
}
