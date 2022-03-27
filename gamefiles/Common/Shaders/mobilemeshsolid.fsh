#define LIGHTMAP_DECODING_MULTIPLIER 2.0f

uniform float4 SpecularLightingMask;
uniform float4 EnvMapMask;
uniform float4 MaskOffsetParams;
uniform float4 ComboDesaturationAlphaTest;
uniform float4 EnvMapColor;

uniform float4 GlobalFogColor;

uniform sampler2D Texture0; //albedo
uniform samplerCUBE Texture3; //envmap
uniform sampler2D Texture7; //lightmap

float4 main(
    float3 Varying_Color : TEXCOORD8,
    float2 Varying_UV : TEXCOORD0,
    float2 Varying_Fog : TEXCOORD1,
    float3 Varying_Diffuse : TEXCOORD9,

#ifdef KOSOVO_SOFTNESS_DEPTH_IN_ALPHA
    float2 Varying_SoftnessDepth : TEXCOORD2,
#endif

#ifdef ENV_MAP
    float4 Varying_EnvMapVector : TEXCOORD3,
#endif

//#ifdef LIGHTMAP
    float2 Varying_LightmapUV : TEXCOORD4
//#endif
) {
    float4 albedo = float4(Varying_Color, 1.0f);

#ifdef DIFFUSE_TEXTURE
    albedo *= float4(tex2D(Texture0, Varying_UV));
#endif

#ifdef ALPHA_TEST
    if (albedo.w * ComboDesaturationAlphaTest.y + ComboDesaturationAlphaTest.z < 0.0f)
        discard;
#endif

    // masks
    float4 maskVector = albedo;
    float envMapMask = clamp(dot(maskVector, EnvMapMask) + MaskOffsetParams.z,0.0f,1.0f);
    float specularMask = clamp(dot(maskVector, SpecularLightingMask) + MaskOffsetParams.z,0.0f,1.0f);

    float3 specular = float3(0.0f,0.0f,0.0f);
    //specular = (half3)in.specular * specularMask;

#ifdef ENV_MAP
    float4 envMap = float4(texCUBE(Texture3, Varying_EnvMapVector.xyz));
    envMap.xyz = EnvMapColor.xyz;

    float3 emissive = float3(0.0f,0.0f,0.0f);
    float envMapLightingMaskUsage = 0.0f;

#if defined(ENV_MAP_ADDITIVE)
#if defined(ENV_MAP_LIGHTING_MASK)
    envMapLightingMaskUsage = 1.0f;
#endif
    emissive = envMap.xyz * envMap.w * envMapMask;
#endif

    specular += emissive;
#endif

    //lighting

#if defined(LIGHTMAP) || defined(TERRAIN_LIGHTMAP)
    float3 diffuse = float4(tex2D(Texture7, Varying_LightmapUV)).xyz;
    diffuse *= LIGHTMAP_DECODING_MULTIPLIER;

    albedo.xyz = albedo.xyz * diffuse.xyz + specular * diffuse.xyz;
#elif defined(LIGHT_PROBES)
    float3 diffuse = Varying_Diffuse;

    albedo.xyz = albedo.xyz * diffuse.xyz + specular * diffuse.xyz;

#endif

    float fogFactor = clamp(max(Varying_Fog.x, GlobalFogColor.w), 0.0, 1.0);
    albedo.xyz = lerp(GlobalFogColor.xyz, albedo.xyz, fogFactor);

#ifdef KOSOVO_SOFTNESS_DEPTH_IN_ALPHA
    albedo.w = Varying_SoftnessDepth.x;
#endif

    return albedo;
}
