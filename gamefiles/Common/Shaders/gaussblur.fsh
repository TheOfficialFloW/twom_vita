uniform float4 Weights;

uniform sampler2D Texture0;

float4 main(
    float4 Varying_blurUV0 : TEXCOORD0,
    float4 Varying_blurUV1 : TEXCOORD1,
    float4 Varying_blurUV2 : TEXCOORD2,
    float2 Varying_blurUV3 : TEXCOORD3
) {
    float4 color = float4(0.0f,0.0f,0.0f,0.0f);
    
    color += tex2D(Texture0,Varying_blurUV0.xy) * Weights.x;
    color += tex2D(Texture0,Varying_blurUV0.zw) * Weights.y;
    color += tex2D(Texture0,Varying_blurUV1.xy) * Weights.z;
    float4 mainSample = tex2D(Texture0,Varying_blurUV1.zw);
    color += mainSample * Weights.w;
    color += tex2D(Texture0,Varying_blurUV2.xy) * Weights.z;
    color += tex2D(Texture0,Varying_blurUV2.zw) * Weights.y;
    color += tex2D(Texture0,Varying_blurUV3.xy) * Weights.x;
    
#ifdef GLOW_BLUR_CLAMP
    color = clamp(color,0.0f,1.0f);
#endif
   
    return color;
}
