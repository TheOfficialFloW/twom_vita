uniform float4 LightColor;

float4 main() {
    float4 gl_FragColor = float4(0, 0, 0, 0);

#ifdef POINT
    gl_FragColor = LightColor;
#else
    gl_FragColor = float4(0.0, 0.0, 0.0, 0.0);
#endif
    return gl_FragColor;
}
