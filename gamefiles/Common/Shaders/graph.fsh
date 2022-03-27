uniform sampler2D   Texture0;

float4 main(
    float2 uvVarying : TEXCOORD0,
    float4 colorVarying : TEXCOORD8
) {
    float4 color = colorVarying;

#ifdef TEXTURE
    float4 txt = tex2D( Texture0, uvVarying );
    color *= txt;
#endif

    return color;
}
