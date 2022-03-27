uniform float4x4 ViewProjMatrix;
uniform float4 GlobalFogParams;

uniform float4x4 ModelMatrix;

uniform float4 MappingTransform;
uniform float4 DiffuseColor;

void main(
    float3 Position,
    float2 UV0,

    float2 out uv0Varying : TEXCOORD0,
    float4 out colorVarying : TEXCOORD8,
    float2 out uvCutoffAndFog : TEXCOORD1,
    float4 out gl_Position : POSITION
) {
    float3 posWS = mul(Position, float3x3(ModelMatrix));

    gl_Position=mul(float4(posWS,1.0f), ViewProjMatrix);
    uv0Varying = UV0 * MappingTransform.xy + MappingTransform.zw;

    float4 color = DiffuseColor;

#ifdef FOG
    float fog = posWS.y * GlobalFogParams.x + GlobalFogParams.y;
#else
    float fog = 0.0f;
#endif

    uvCutoffAndFog = float2(color.w - uv0Varying.y, fog);
    colorVarying = float4(color.xyz,1.0f);
}
