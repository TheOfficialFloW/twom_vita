uniform float4 HostileColor;
uniform float4 FriendlyColor;
uniform float4 NeutralColor;

uniform sampler2D Texture2;

float4 main(
    float4 uv0Varying : TEXCOORD0
) {
    float3 one=float3(1.0f,1.0f,1.0f);

    float3 outline0=tex2D(Texture2,uv0Varying.xy).xyz;
    float3 outline1=tex2D(Texture2,uv0Varying.zw).xyz;
    float3 outlineSum=outline0+outline1;
    float3 finalOutline=min(one,outlineSum)*min(one,float3(2.0f,2.0f,2.0f)-outlineSum);

    float4 color = HostileColor*finalOutline.x
                 + FriendlyColor*finalOutline.y
                 + NeutralColor*finalOutline.z;

    return color;
}
