uniform float4 UserVSHParams[ 2 ];

void main(
    float3 Position,
    float2 UV0,

    float2 out uv0Varying : TEXCOORD0,
    float4 out gl_Position : POSITION
) {
    float4 uvOffsets  = UserVSHParams[ 0 ];
    float4 posScale   = UserVSHParams[ 1 ];
    gl_Position		= float4( Position, 1.f );
    gl_Position.xy *= posScale.xy;
    uv0Varying.xy	= UV0 * uvOffsets.xy + uvOffsets.zw;
}
