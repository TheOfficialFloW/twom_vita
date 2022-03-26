uniform float4 GraphParams;
uniform float4 ConstantColor;
uniform float4x4 ModelViewProjMatrix;
uniform float4 UserVSHParams[ 32 ];

void main(
    float3 Position,

    float2 out uvVarying : TEXCOORD0,
    float4 out colorVarying : TEXCOORD8,
    float4 out gl_Position : POSITION
) {
	float width=GraphParams.x;
	float3 v = Position;
	float positionOnPath;

#ifdef CATMULL_ROM
	float3 pos, way;
	
	// ewaluacja catmull roma zostala zinlinowana z powodu bledow na androidzie

	float4 a=UserVSHParams[int(4.0*v.z)];
	float4 b=UserVSHParams[int(4.0*v.z+1.0)];
	float4 c=UserVSHParams[int(4.0*v.z+2.0)];
	float4 d=UserVSHParams[int(4.0*v.z+3.0)];
	float st=v.x;
	float st2 = st*st;
	{
		float st3 = st2*st;

		float3 t	 = float3(st,st,st);
		float3 t2  = float3(st2,st2,st2);
		float3 t3  = float3(st3,st3,st3);
		float3 c05 = float3(0.5,0.5,0.5);
		float3 c2  = float3(2.,2.,2.);
		float3 c3  = float3(3.,3.,3.);
		float3 c4  = float3(4.,4.,4.);
		float3 c5  = float3(5.,5.,5.);
		pos=((b.xyz*2.0) + (c.xyz-a.xyz)*t + (a.xyz*c2-b.xyz*c5+c.xyz*c4-d.xyz)*t2 + (-a.xyz+b.xyz*c3-c.xyz*c3+d.xyz)*t3) * c05;
	}
	{
		float3 t	 = float3(st,st,st);
		float3 t2  = float3(st2,st2,st2);	
		float3 c05 = float3(0.5,0.5,0.5);
		float3 c1  = float3(1.,1.,1.);
		float3 c2  = float3(2.,2.,2.);
		float3 c3  = float3(3.,3.,3.);
		float3 c4  = float3(4.,4.,4.);
		float3 c5  = float3(5.,5.,5.);
		way=((c.xyz-a.xyz) + c2*(a.xyz*c2-b.xyz*c5+c.xyz*c4-d.xyz) * t + c3*(a.xyz*-c1+b.xyz*c3-c.xyz*c3+d.xyz)*t2)*c05;
	}
	
	width*=v.y;
	positionOnPath=lerp(a.w,d.w,v.x);
#elif defined(ARROW)
	float4 a=UserVSHParams[int(2.0*v.z)];
	float4 b=UserVSHParams[int(2.0*v.z+1.0)];
	float3 pos=a.xyz+b.xyz*v.xxx;
	float3 way=b.xyz;
	width*=4.0*v.y;
	positionOnPath=1.0;
#else	
	float4 a=UserVSHParams[int(2.0*v.z)];
	float4 b=UserVSHParams[int(2.0*v.z+1.0)];
	float4 pos4=lerp(a,b,v.x);
	float3 pos=pos4.xyz;
	float3 way=b.xyz-a.xyz;
	width*=v.y;
	positionOnPath=pos4.w;
#endif

	float3 side=cross(way,float3(0.0,1.0,0.0));
	side=normalize(side);
	pos+=side*width;

	uvVarying 		= float2( v.y + 0.5, -positionOnPath * GraphParams.y );
	gl_Position 	= mul(float4( pos, 1. ), ModelViewProjMatrix);
	colorVarying 	= ConstantColor;
}