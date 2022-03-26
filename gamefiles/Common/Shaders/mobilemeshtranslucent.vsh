uniform float4x4 ModelMatrix;
uniform float4x4 InvTModelMatrix;

uniform float4 MappingTransform;
uniform float4 DiffuseColor;

uniform float4x4 ViewProjMatrix;
uniform float4 GlobalFogParams;
uniform float4 VSHInvSunDiffuseDirection;
uniform float4 VSHSunFrontColor;

uniform float4 BoneMatrices[64 * 3];

void ComputeSkinningMatrix(float4 indices, float4 weights, out float4 va, out float4 vb, out float4 vc)
{
    int4 bix        = int4(indices)*3;
    va=BoneMatrices[bix.x]*weights.x, vb=BoneMatrices[bix.x+1]*weights.x, vc=BoneMatrices[bix.x+2]*weights.x;
    va+=BoneMatrices[bix.y]*weights.y, vb+=BoneMatrices[bix.y+1]*weights.y, vc+=BoneMatrices[bix.y+2]*weights.y;
    va+=BoneMatrices[bix.z]*weights.z, vb+=BoneMatrices[bix.z+1]*weights.z, vc+=BoneMatrices[bix.z+2]*weights.z;
    va+=BoneMatrices[bix.w]*weights.w, vb+=BoneMatrices[bix.w+1]*weights.w, vc+=BoneMatrices[bix.w+2]*weights.w;
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
    float4 out Varying_Color : COLOR0,
    float2 out Varying_UV : TEXCOORD0,
    float out Varying_Fog : TEXCOORD1,
    // float out Varying_ToneMap : TEXCOORD1,
    float4 out gl_Position : POSITION
) {
    // Varying_ToneMap = 1.0;
    
    float4 pos = float4(Position, 1.0);
    float4 nor = float4(Normal, 0.0);
    
#ifdef SKINNING
    float4 va, vb, vc;
    ComputeSkinningMatrix(BlendIndices, BlendWeight, va, vb, vc);
    
    pos     = float4(dot(pos, va), dot(pos, vb), dot(pos, vc), 1.0);
    nor     = float4(dot(nor, va), dot(nor, vb), dot(nor, vc), 1.0);
    
    // Varying_ToneMap = 2.0;
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
    float3 diff = (VSHSunFrontColor.xyz * normalFactor) * 2.0;
    Varying_Color.xyz *= diff;
#endif
    
#ifdef FOG
    Varying_Fog = posWS.y * GlobalFogParams.x + GlobalFogParams.y;
#else
    Varying_Fog = 0.0;
#endif
}
