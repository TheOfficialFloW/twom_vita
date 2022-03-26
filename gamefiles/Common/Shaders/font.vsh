uniform float4x4 ModelViewProjMatrix;
uniform float4 MappingTransform;
uniform float4 FontColor;

void main(
    float3 Position,
    float2 UV0,

    float4 out colorVarying : TEXCOORD8,
    float2 out uv0Varying : TEXCOORD0,
    float4 out gl_Position : POSITION
) {
    gl_Position = mul(float4(Position,1.f), ModelViewProjMatrix);
    uv0Varying = UV0*MappingTransform.xy+MappingTransform.zw;
    colorVarying = FontColor;
}
