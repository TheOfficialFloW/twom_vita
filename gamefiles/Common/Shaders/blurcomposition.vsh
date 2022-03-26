uniform float4x4 ModelViewProjMatrix;

void main(
    float3 Position,

    float2 out screenPosVarying : TEXCOORD0,
    float4 out gl_Position : POSITION
) {
    float4 pos4 = mul(float4(Position,1.0), ModelViewProjMatrix);
    
    screenPosVarying = (pos4.xy / pos4.w) * 0.5 + float2(0.5,0.5);
    
    gl_Position = pos4;
}
