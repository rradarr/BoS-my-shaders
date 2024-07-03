cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

#define PI 3.14

float box(float2 uv, float2 size)
{
	// Size should grow from the center
	size = float2(0.5) + size / 2;
    float smoothness = 0.001;
    float2 box = smoothstep(size, size - smoothness, uv);
    box *= smoothstep(size, size - smoothness, 1 - uv);
	return box.y * box.x;
}

float crossShape(float2 uv, float size)
{
	return box(uv, float2(size, size/4)) + box(uv, float2(size/4, size));
}

float flattenedCos(float x, float flatness)
{
	return sqrt((1+pow(flatness,2))/(1+pow(flatness,2)*pow(cos(uTime), 2)))*cos(uTime);
}

float movingCrossShape(float2 uv, float size)
{
	float timing = flattenedCos(uTime, 2);
	timing = (timing+1)/2 * 2*PI + 1.5*PI; // Get this in range
	float2 translate = float2(cos(timing), sin(timing));
   	uv += translate * 0.4;
	return crossShape(uv, size); 
}

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
    float2 uv = fragCoord.xy/uResolution;
    
    float3 val = float3(0);
    //val = float3(frac(uv.x*10));

   	//val += box(uv, float2(0.6));
   	val = movingCrossShape(uv, 0.2);

    
    return float4(val, 1.0f);
}
