uniform float4 OutlineUVOffset;

void main(
    float2 Position,

    float4 out uv0Varying : TEXCOORD0,
    float4 out gl_Position : POSITION
) {
    gl_Position = float4(Position,0.0f,1.0f);

    float2 uv0=Position*0.5f+0.5f;
    uv0Varying=uv0.xyxy+OutlineUVOffset*float4(1.0f,1.0f,-1.0f,-1.0f);
}
