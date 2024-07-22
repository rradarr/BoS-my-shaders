cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

#define PI 3.14

float box(float2 uv, float2 size)
{
	size = size / 2;	// Size should grow from the center.
    float smoothness = 0.001;
    uv = abs(uv);	// We can make the boxes symmetric around the (0,0) point.
    float2 box = smoothstep(size, size - smoothness, uv);
	return box.x * box.y;
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
	// There is a - instead of a + here because we are not moving
	// points in a space, we are moving the entire space. (akin to
	// subtracting from x to 'move' a graph of f(x) to the right)
	uv -= float2(0.5);
	
	float timing = flattenedCos(uTime, 2);
	timing = (timing+1)/2 * 2*PI + 1.5*PI; // Get this in range
	float2 translate = float2(cos(timing), sin(timing));
   	uv += translate * 0.4;
	return crossShape(uv, size); 
}

float2x2 rotate(float angle)
{
	return float2x2(cos(angle),-sin(angle),
                sin(angle),cos(angle));
}

float rotatingCrossShape(float2 uv, float size)
{
	// This caused some head scrathching for me: the typical
	// order of center-rotate-reposition when rotating vertices
	// is kind of reversed, again because we are manipulating the
	// space rather than points within it. So:
	uv -= float2(0.5); 				// We move the (0,0) point to the center of the screen
	uv = rotate(uTime*0.4) * uv;	// We rotate around the (0,0) point, as always
	//uv -= float2(0.2); 			// Now we could modify the coordiantes further,
									// essentialy offsetting by a rotated vector

	return crossShape(uv, size);
}

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
    float2 uv = fragCoord.xy/uResolution;
    
    float3 val = float3(0);
    //val = float3(frac(uv.x*10));

   	//val += box(uv, float2(0.6));
   	//val = movingCrossShape(uv, 0.2);
   	val = rotatingCrossShape(uv, 0.2);

    
    return float4(val, 1.0f);
}
