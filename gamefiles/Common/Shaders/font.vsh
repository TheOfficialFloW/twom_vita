uniform float4x4 ModelViewProjMatrix;
uniform float4 MappingTransform;
uniform float4 FontColor;

void main(
    float3 Position,
    float2 UV0,

    float4 out colorVarying : COLOR0,
    float2 out uv0Varying : TEXCOORD0,
    float4 out gl_Position : POSITION
) {
    float3 pos=Position;
    gl_Position = mul(float4(pos,1), ModelViewProjMatrix);
    uv0Varying = UV0*MappingTransform.xy+MappingTransform.zw;
    colorVarying = FontColor;
}
