uniform float4 OutlineUVOffset;

void main(
    float2 Position,

    float4 out uv0Varying : TEXCOORD0,
    float4 out gl_Position : POSITION
) {
    gl_Position = float4(Position,0,1);

    float2 uv0=Position*float2(0.5,0.5)+float2(0.5,0.5);
    uv0Varying=uv0.xyxy+OutlineUVOffset*float4(1,1,-1,-1);
}
