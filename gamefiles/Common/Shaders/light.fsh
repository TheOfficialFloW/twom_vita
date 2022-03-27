uniform float4 LightColor;

float4 main() {
#ifdef POINT
    return LightColor;
#else
    return float4(0.0f, 0.0f, 0.0f, 0.0f);
#endif
}
