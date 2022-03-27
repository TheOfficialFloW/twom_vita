uniform float4x4 ModelViewProjMatrix;

void main(
    float3 Position,

    float2 out screenPosVarying : TEXCOORD0,
    float4 out gl_Position : POSITION
) {
    gl_Position = mul(float4(Position,1.0f), ModelViewProjMatrix);
    screenPosVarying = (gl_Position.xy / gl_Position.w) * 0.5f + 0.5f;
}
