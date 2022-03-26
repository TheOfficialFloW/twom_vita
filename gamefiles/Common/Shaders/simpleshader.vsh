uniform float4x4 ModelViewProjMatrix;
uniform float4 MappingTransform;
uniform float4 DiffuseColor;

void main(
    float3 Position,
#if defined(TEXTURE)
    float2 UV0,
#endif
    float4 Color,

    float4 out colorVarying : COLOR0,
#if defined(TEXTURE)
    float2 out uv0Varying : TEXCOORD0,
#endif
    float4 out gl_Position : POSITION
) {
	float3 pos=Position;
    gl_Position = mul(float4(pos,1), ModelViewProjMatrix);

    colorVarying=DiffuseColor;
#ifdef VERTEX_COLOR
	colorVarying*=Color;
#endif
#if defined(TEXTURE)
    uv0Varying=UV0*MappingTransform.xy+MappingTransform.zw;
#endif
}
