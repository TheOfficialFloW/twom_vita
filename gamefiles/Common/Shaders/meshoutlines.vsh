uniform float4 BoneMatrices[64 * 3];

void ComputeSkinningMatrix(float4 indices, float4 weights, out float4 va, out float4 vb, out float4 vc)
{
    int4 bix        = int4(indices)*3;
    va=BoneMatrices[bix.x]*weights.x, vb=BoneMatrices[bix.x+1]*weights.x, vc=BoneMatrices[bix.x+2]*weights.x;
    va+=BoneMatrices[bix.y]*weights.y, vb+=BoneMatrices[bix.y+1]*weights.y, vc+=BoneMatrices[bix.y+2]*weights.y;
    va+=BoneMatrices[bix.z]*weights.z, vb+=BoneMatrices[bix.z+1]*weights.z, vc+=BoneMatrices[bix.z+2]*weights.z;
    va+=BoneMatrices[bix.w]*weights.w, vb+=BoneMatrices[bix.w+1]*weights.w, vc+=BoneMatrices[bix.w+2]*weights.w;
}

uniform float4x4 ModelViewProjMatrix;
uniform float4 VertexDenormalizationBox[2];

void main(
    float3 Position,
#ifdef SKINNING
    float4 BlendWeight,
    float4 BlendIndices,
#endif

    float out Varying_ToneMap : TEXCOORD0,
    float4 out gl_Position : POSITION
) {
	float4 pos = float4(VertexDenormalizationBox[0].xyz+Position.xyz*VertexDenormalizationBox[1].xyz,1.0);

	Varying_ToneMap = 0.0;
	
	#ifdef SKINNING
		float4 va, vb, vc;
		ComputeSkinningMatrix(BlendIndices, BlendWeight, va, vb, vc);
		pos = float4(dot(pos, va), dot(pos, vb), dot(pos, vc), 1.0);
		
		Varying_ToneMap = 1.0;
	#endif

	gl_Position = mul(pos, ModelViewProjMatrix);    
}
