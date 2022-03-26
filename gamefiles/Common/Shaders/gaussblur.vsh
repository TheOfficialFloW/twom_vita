uniform float4 PosToUV;
uniform float4 KernelSize;
uniform float4 BlurUVGenParams[2];

void main(
    float3 Position,
    float2 UV0,

    float4 out Varying_blurUV0 : TEXCOORD0,
    float4 out Varying_blurUV1 : TEXCOORD1,
    float4 out Varying_blurUV2 : TEXCOORD2,
    float4 out Varying_blurUV3 : TEXCOORD3,
    float4 out gl_Position : POSITION
) {
	float4 pos4 = float4(Position,1.0);

    gl_Position = pos4;

    float2 uv = pos4.xy * PosToUV.xy + PosToUV.zw;
    
    Varying_blurUV0.xy = uv + BlurUVGenParams[0].x * KernelSize.xy;
    Varying_blurUV0.zw = uv + BlurUVGenParams[0].y * KernelSize.xy;
    Varying_blurUV1.xy = uv + BlurUVGenParams[0].z * KernelSize.xy;
    Varying_blurUV1.zw = uv;
    Varying_blurUV2.xy = uv + BlurUVGenParams[1].x * KernelSize.xy;
    Varying_blurUV2.zw = uv + BlurUVGenParams[1].y * KernelSize.xy;
    Varying_blurUV3.xy = uv + BlurUVGenParams[1].z * KernelSize.xy;
}
