uniform float4 HostileColor;
uniform float4 FriendlyColor;
uniform float4 NeutralColor;

uniform sampler2D Texture2;

float4 main(
    float4 uv0Varying : TEXCOORD0
) {
    float4 gl_FragColor = float4(0, 0, 0, 0);

    float3 one=float3(1.0,1.0,1.0);

    float3 outline0=tex2D(Texture2,uv0Varying.xy).xyz;
	float3 outline1=tex2D(Texture2,uv0Varying.zw).xyz;
    float3 outlineSum=outline0+outline1;
	float3 finalOutline=min(one,outlineSum)*min(one,float3(2.0,2.0,2.0)-outlineSum);

	float4 color = HostileColor*finalOutline.x
                       + FriendlyColor*finalOutline.y
                       + NeutralColor*finalOutline.z;

	gl_FragColor=color;
    return gl_FragColor;
}
