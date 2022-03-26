uniform sampler2D Texture0;

float4 main(
    float2 uv0Varying : TEXCOORD0
) {
    return tex2D(Texture0,uv0Varying);
}
