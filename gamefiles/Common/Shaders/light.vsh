uniform float4x4 ModelViewProjMatrix;

void main(
    float3 Position,

    float4 out gl_Position : POSITION
) {
    gl_Position = mul(float4( Position, 1.0f ), ModelViewProjMatrix);
}
