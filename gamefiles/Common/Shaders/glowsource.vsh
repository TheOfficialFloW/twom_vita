uniform float4 UVOffsets;
uniform float4 SampleOffsets;

void main(
    float3 Position,
    float2 UV0,

    float4 out uv0Varying : TEXCOORD0,
    float4 out uv1Varying : TEXCOORD1,
    float4 out gl_Position : POSITION
) {
	float3 pos=Position;

    gl_Position = float4(pos,1);

    float2 uv = float2(UV0.x, 1.0f - UV0.y);
    uv = uv * UVOffsets.xy + UVOffsets.zw;
    
	uv0Varying.xy = uv + SampleOffsets.xy;
	uv0Varying.zw = uv - SampleOffsets.xy;
	
	uv1Varying.xy = uv + SampleOffsets.zw;
	uv1Varying.zw = uv - SampleOffsets.zw;
}
