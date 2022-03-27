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

uniform float4x4 ModelViewProjMatrix;
uniform float4 VertexDenormalizationBox[2];

void main(
    float3 Position,
#ifdef SKINNING
    float4 BlendWeight,
    float4 BlendIndices,
#endif

    float2 out Varying_ToneMap : TEXCOORD0,
    float4 out gl_Position : POSITION
) {
	float4 pos = float4(VertexDenormalizationBox[0].xyz+Position.xyz*VertexDenormalizationBox[1].xyz,1.0);

	#ifdef SKINNING
		float4x4 SkinningMatrix;
		ComputeSkinningMatrix(BlendIndices, BlendWeight, SkinningMatrix);
		pos = mul(SkinningMatrix, pos);

		Varying_ToneMap.x = 1.0f;
	#else
		Varying_ToneMap.x = 0.0f;
	#endif

	gl_Position = mul(pos, ModelViewProjMatrix);
}
