uniform float4 UserVSHParams[3];
uniform float4 UVOffset;
uniform float4 GlowUVOffset;
uniform float4 VignetteUVOffset;
uniform float4 CustomVSHParams[4];

void main(
    float3 Position,
    float2 UV0,

    float2 out Varying_MainUV : TEXCOORD0,
    float2 out Varying_GlowUV : TEXCOORD1,
    float2 out Varying_MaskUV0 : TEXCOORD2,
    float2 out Varying_MaskUV1 : TEXCOORD3,
    float2 out Varying_VignetteUV : TEXCOORD4,
    float3 out Varying_ScreenColor : COLOR0,
    float4 out gl_Position : POSITION
) {
    float4 pos4 = float4(Position, 1.0);
    float2 uv = UV0 * float2(1, -1) + float2(0, 1);
    
    Varying_MainUV = uv * UVOffset.xy + UVOffset.zw;
	Varying_GlowUV = uv * GlowUVOffset.xy + GlowUVOffset.zw;
    Varying_MaskUV0 = float2(dot(pos4,CustomVSHParams[2]),dot(pos4,CustomVSHParams[3]));
    Varying_MaskUV1 = float2(dot(pos4,CustomVSHParams[0]),dot(pos4,CustomVSHParams[1]));
    Varying_VignetteUV = uv * VignetteUVOffset.xy + VignetteUVOffset.zw;

	float4 sc = lerp(UserVSHParams[0], UserVSHParams[1], 1.0 - Varying_MainUV.y);
	Varying_ScreenColor = lerp(float3(1.0), sc.xyz, sc.w);

    gl_Position = pos4;
}