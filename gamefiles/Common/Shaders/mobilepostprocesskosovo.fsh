uniform sampler2D Texture0; // input (main)

#ifdef ENABLED
    uniform sampler2D Texture1; // glow
#endif

uniform sampler2D Texture5; // clouds (pencil)

#define BW float3(0.2126f, 0.7152f, 0.0722f)

uniform float4 UserPSHParams[5];
uniform float4 VignetteAndNoiseParams;
uniform float4 CustomPSHParams[4];
uniform float4 ThresholdX_ExpositionY;

float4 main(
    float2 Varying_MainUV : TEXCOORD0,
    float2 Varying_GlowUV : TEXCOORD1,
    float2 Varying_MaskUV0 : TEXCOORD2,
    float2 Varying_MaskUV1 : TEXCOORD3,
    float2 Varying_VignetteUV : TEXCOORD4,

    float3 Varying_ScreenColor : TEXCOORD8
) {
    float4 color = tex2D(Texture0, Varying_MainUV);

    //tonemap

#if !defined(FINAL_TARGET_NO_SRGB)
    color.xyz *= 2.0f;
#endif
    color.xyz *= UserPSHParams[0].xyz;
    
#ifdef ENABLED
    float4 glow  = tex2D(Texture1, Varying_GlowUV);
    
    // calculate glow intensity (from GlowSource shader)
    float4 threshold = ThresholdX_ExpositionY;
    float glowIntensity = clamp(dot(glow.xyz-threshold.xyz,BW),0.0f,1.0f);
    
    //tonemap
#if defined(FINAL_TARGET_NO_SRGB)
    glow.xyz *= 0.5f;
#endif
	
    color.xyz += UserPSHParams[1].xyz * glowIntensity;
    color.xyz = lerp(glow.xyz, color.xyz, glow.w);
#endif
    
    color.xyz = clamp(color.xyz, 0.0f, 1.0f);
    
    //saturation
    float saturation = UserPSHParams[2].x;
    float colorIntensity = dot(color.xyz,BW);
    color.xyz = lerp(float3(colorIntensity),color.xyz,saturation);
    
    //constrast
    color.xyz = lerp(color.xyz,color.xyz*color.xyz,UserPSHParams[3].xyz);
    
    // pencil effect
    float intensity = dot(color.xyz,BW);
    float cutoff = clamp((CustomPSHParams[0].x - intensity)*CustomPSHParams[0].z,0.0f,1.0f);

    float4 pencilTxt  = tex2D(Texture5, Varying_MaskUV0);
    float4 pencilTxt2 = tex2D(Texture5, Varying_MaskUV1);
    pencilTxt = lerp(pencilTxt2,pencilTxt,CustomPSHParams[2].x);
    
    float pencilEffect = lerp(pencilTxt.x,pencilTxt.w,cutoff);
    float3 pencilEffectVec = float3(pencilEffect,pencilEffect,pencilEffect);
    
    float downFactor = clamp((intensity-CustomPSHParams[1].x)*CustomPSHParams[1].y,0.0f,1.0f);
    float upFactor = clamp((CustomPSHParams[1].z-intensity)*CustomPSHParams[1].w,0.0f,1.0f);
    float totalFactor = downFactor * upFactor;
    
    color.xyz = lerp(color.xyz,pencilEffectVec,clamp(totalFactor*CustomPSHParams[0].y,0.0f,1.0f));
    
    // screen color
    color.xyz *= Varying_ScreenColor;

    // vignette
    float dist =  dot(Varying_VignetteUV,Varying_VignetteUV);
    dist = clamp(dist * VignetteAndNoiseParams.x + VignetteAndNoiseParams.y,0.0f,1.0f);
    color.xyz *= dist * dist;
   
    
	// Apply low spec devices color multiplicator
	#ifndef GLOW_BLUR_CLAMP
		color.xyz *= UserPSHParams[4].a;
    #else
		color.xyz *= 2.0f;
	#endif
	
	float4 gl_FragColor = float4(color.xyz,1.0f);
	// Android TV no srgb finalization
	#ifndef GLOW_BLUR_CLAMP
	#if defined(FINAL_TARGET_NO_SRGB)
		gl_FragColor.xyz = sqrt(gl_FragColor.xyz);
	#endif
	#endif
    return gl_FragColor;
}
