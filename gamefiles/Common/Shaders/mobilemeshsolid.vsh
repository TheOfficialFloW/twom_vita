uniform float4x4 ModelMatrix;
uniform float4x4 InvTModelMatrix;

uniform float4 LightmapUVMulAdd;
uniform float4 LightProbe[6];
uniform float4 LightProbeGradient[4];

uniform float4 MappingTransform;
uniform float4 DiffuseColor;

uniform float4x4 ViewProjMatrix;
uniform float4 WorldSpaceEyePosition;
uniform float4 GlobalFogParams;
uniform float4 VSHInvSunDiffuseDirection;
uniform float4 VSHSunFrontColor;

uniform float4 BoneMatrices[64 * 3];

float EncodeKosovoFakeDepth(float worldSpaceY)
{
    return (clamp(worldSpaceY, -4.0f, 4.0f) + 4.0f) / 8.0f;
}

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
//#ifdef LIGHTMAP
    float2 UV2,
//#endif
#ifdef SKINNING
    float4 BlendWeight,
    float4 BlendIndices,
#endif

    // float4 out Varying_Normal : TEXCOORD0,
    float3 out Varying_Color : TEXCOORD8,
    float2 out Varying_UV : TEXCOORD0,
    float2 out Varying_Fog : TEXCOORD1,
    // float out Varying_ToneMap : TEXCOORD1,
    float3 out Varying_Diffuse : TEXCOORD9,

#ifdef KOSOVO_SOFTNESS_DEPTH_IN_ALPHA
    float2 out Varying_SoftnessDepth : TEXCOORD2,
#endif

#ifdef ENV_MAP
    float4 out Varying_EnvMapVector : TEXCOORD3,
#endif

//#ifdef LIGHTMAP
    float2 out Varying_LightmapUV : TEXCOORD4,
//#endif

    float4 out gl_Position : POSITION
) {
    // Varying_ToneMap = 1.0f;

    //----------------------------------------------

    float4 pos = float4(Position, 1.0f);
    float4 nor = float4(Normal, 0.0f);

#ifdef SKINNING
    float4x4 SkinningMatrix;
    ComputeSkinningMatrix(BlendIndices, BlendWeight, SkinningMatrix);

    pos     = mul(SkinningMatrix, pos);
    nor     = mul(SkinningMatrix, nor);
#endif

    nor.w=1.0;

    gl_Position = mul(mul(pos, ModelMatrix), ViewProjMatrix);

    // Varying_Normal = mul(nor, InvTModelMatrix);

    Varying_UV = UV0 * MappingTransform.xy + MappingTransform.zw;
    //Varying_Color = Color.xyz*DiffuseColor.xyz;

    Varying_Color = DiffuseColor.xyz;
#if defined(VERTEX_COLOR)
    Varying_Color *= Color.xyz;
#endif

    // fog

    float4 posWS4 = mul(pos, ModelMatrix);
    float3 posWS = posWS4.xyz;

    Varying_Fog.x = posWS.y * GlobalFogParams.x + GlobalFogParams.y;

    // sun

    float4 worldSpaceNormal = mul(nor, InvTModelMatrix);


#if defined(LIGHTMAP)
    Varying_LightmapUV = UV2 * LightmapUVMulAdd.xy + LightmapUVMulAdd.zw;
#elif defined(TERRAIN_LIGHTMAP)
    Varying_LightmapUV = LightmapUVMulAdd.xy + LightmapUVMulAdd.zw;
#elif defined(LIGHT_PROBES)
    float3 probeX = (worldSpaceNormal.x >= 0.0f) ? LightProbe[1].xyz : LightProbe[0].xyz ;
    float3 probeY = (worldSpaceNormal.y >= 0.0f) ? LightProbe[3].xyz : LightProbe[2].xyz ;
    float3 probeZ = (worldSpaceNormal.z >= 0.0f) ? LightProbe[5].xyz : LightProbe[4].xyz ;

    float3 probeCenterWS = LightProbeGradient[0].xyz;
    float3 gradX = LightProbeGradient[1].xyz;
    float3 gradY = LightProbeGradient[2].xyz;
    float3 gradZ = LightProbeGradient[3].xyz;
    float3 probeOffsetWS = posWS - probeCenterWS;

    probeX += probeOffsetWS.xxx * gradX;
    probeY += probeOffsetWS.yyy * gradY;
    probeZ += probeOffsetWS.zzz * gradZ;

    float3 sqNrmWS = worldSpaceNormal.xyz * worldSpaceNormal.xyz;
    Varying_Diffuse = sqNrmWS.x * probeX + sqNrmWS.y * probeY + sqNrmWS.z * probeZ;
#else
    float normalFactor = dot(normalize(worldSpaceNormal.xyz),VSHInvSunDiffuseDirection.xyz);
    float3 diff = (VSHSunFrontColor.xyz * normalFactor) * 2.0f;
    Varying_Color.xyz *= diff;
#endif

    float3 worldSpaceView = posWS - WorldSpaceEyePosition.xyz;

#if defined(ENV_MAP)
    Varying_EnvMapVector.xyz = reflect(worldSpaceView.xyz,worldSpaceNormal.xyz);
#endif

    //todo: global depth buffer generation

    //todo: specular

#ifdef KOSOVO_SOFTNESS_DEPTH_IN_ALPHA
    Varying_SoftnessDepth.x = EncodeKosovoFakeDepth(posWS.y);
#endif
}
