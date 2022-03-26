uniform float4x4 ModelViewProjMatrix;

void main(
    float3 Position,
    float2 UV0,
    float4 Color,

    float2 out uv0Varying : TEXCOORD0,
    float4 out colorVarying : COLOR0,
    float4 out gl_Position : POSITION
) {
    gl_Position = mul(float4(Position,1.f), ModelViewProjMatrix);
    
    uv0Varying = UV0;
    colorVarying = Color;
}
