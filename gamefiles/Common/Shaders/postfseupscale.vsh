void main(
    float3 Position,
    float2 UV0,

    float2 out uv0Varying : TEXCOORD0,
    float4 out gl_Position : POSITION
) {
	float3 pos=Position;
	gl_Position=float4(pos,1);

	uv0Varying = UV0;
}
