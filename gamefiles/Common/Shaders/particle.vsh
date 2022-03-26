uniform float4x4 ModelViewProjMatrix;
uniform float4 FogParams;
uniform float4 NodeColors[4];

void main(
    float3 Position,
    float4 Color,
    float4 UV0,

    float4 out colorVarying : COLOR0,
    float4 out uv0Varying : TEXCOORD0,
    float2 out frameFactorFog : TEXCOORD1,
    float4 out gl_Position : POSITION
) {
    float4 pos = float4(Position.xyz, 1.0);
    gl_Position = mul(pos, ModelViewProjMatrix);
    
    int node = int(Color.x * 255.0);
    float factor = Color.y;
    
    colorVarying=lerp(NodeColors[node],NodeColors[node+1],factor);
    uv0Varying = UV0;
    
    frameFactorFog = float2(Color.z,0);
#ifdef FOG
    frameFactorFog.y = dot(FogParams,pos);
#endif
}
