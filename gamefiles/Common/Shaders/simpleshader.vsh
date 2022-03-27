uniform float4x4 ModelViewProjMatrix;
uniform float4 MappingTransform;
uniform float4 DiffuseColor;

void main(
    float3 Position,
#if defined(TEXTURE)
    float2 UV0,
#endif
    float4 Color,

    float4 out colorVarying : TEXCOORD8,
#if defined(TEXTURE)
    float2 out uv0Varying : TEXCOORD0,
#endif
    float4 out gl_Position : POSITION
) {
    gl_Position = mul(float4(Position,1.f), ModelViewProjMatrix);

    colorVarying=DiffuseColor;
#ifdef VERTEX_COLOR
    colorVarying*=Color;
#endif
#if defined(TEXTURE)
    uv0Varying=UV0*MappingTransform.xy+MappingTransform.zw;
#endif
}
