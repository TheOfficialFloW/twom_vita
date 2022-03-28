uniform float4x4 ModelMatrix;
uniform float4x4 InvTModelMatrix;

uniform float4 MappingTransform;
uniform float4 DiffuseColor;

uniform float4x4 ViewProjMatrix;
uniform float4 GlobalFogParams;
uniform float4 VSHInvSunDiffuseDirection;
uniform float4 VSHSunFrontColor;

uniform float4 BoneMatrices[64 * 3];

void ComputeSkinningMatrix(float4 indices, float4 weights, out float4x4 M)
{
    int4 bix        = int4(indices)*3;
    M[0]=BoneMatrices[bix.x]*weights.x, M[1]=BoneMatrices[bix.x+1]*weights.x, M[2]=BoneMatrices[bix.x+2]*weights.x;
    M[0]+=BoneMatrices[bix.y]*weights.y, M[1]+=BoneMatrices[bix.y+1]*weights.y, M[2]+=BoneMatrices[bix.y+2]*weights.y;
    M[0]+=BoneMatrices[bix.z]*weights.z, M[1]+=BoneMatrices[bix.z+1]*weights.z, M[2]+=BoneMatrices[bix.z+2]*weights.z;
    M[0]+=BoneMatrices[bix.w]*weights.w, M[1]+=BoneMatrices[bix.w+1]*weights.w, M[2]+=BoneMatrices[bix.w+2]*weights.w;
    M[3]=float4(0.0f,0.0f,0.0f,1.0f);
}

void main(
    float3 Position,
    float3 Normal,
    float2 UV0,
#ifdef VERTEX_COLOR
    float4 Color,
#endif
#ifdef SKINNING
    float4 BlendWeight,
    float4 BlendIndices,
#endif

    // float4 out Varying_Normal : TEXCOORD0,
    float4 out Varying_Color : TEXCOORD8,
    float2 out Varying_UV : TEXCOORD0,
    float2 out Varying_Fog : TEXCOORD1,
    // float out Varying_ToneMap : TEXCOORD1,
    float4 out gl_Position : POSITION
) {
    // Varying_ToneMap = 1.0f;

    float4 pos = float4(Position, 1.0f);
    float4 nor = float4(Normal, 0.0f);

#ifdef SKINNING
    float4x4 SkinningMatrix;
    ComputeSkinningMatrix(BlendIndices, BlendWeight, SkinningMatrix);

    pos     = mul(SkinningMatrix, pos);
    nor     = mul(SkinningMatrix, nor);

    // Varying_ToneMap = 2.0f;
#endif

    nor.w = 1.0;

    float4 posWS4 = mul(pos, ModelMatrix);
    float3 posWS = posWS4.xyz;

    gl_Position = mul(posWS4, ViewProjMatrix);

    // Varying_Normal = mul(nor, InvTModelMatrix);

    Varying_UV = UV0 * MappingTransform.xy + MappingTransform.zw;

    Varying_Color = DiffuseColor;
#if defined(VERTEX_COLOR)
    Varying_Color *= Color;
#endif

#ifdef LIGHTING
    float4 worldSpaceNormal = mul(nor, InvTModelMatrix);
    float normalFactor = dot(normalize(worldSpaceNormal.xyz),VSHInvSunDiffuseDirection.xyz);
    float3 diff = (VSHSunFrontColor.xyz * normalFactor) * 2.0f;
    Varying_Color.xyz *= diff;
#endif

#ifdef FOG
    Varying_Fog.x = posWS.y * GlobalFogParams.x + GlobalFogParams.y;
#else
    Varying_Fog.x = 0.0f;
#endif
}
