cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

#define PI 3.14159265359

float circleShape(float2 uv, float radius)
{
	uv -= float2(0.5);
	float dist = length(uv);
	return 1 - step(radius, dist);
}

float ringShape(float2 uv, float radius, float thickness)
{
	return circleShape(uv, radius) - circleShape(uv, radius * (1 - thickness));
}

float2x2 getRotationMat(float angle)
{
	return float2x2(cos(angle),-sin(angle),
                sin(angle),cos(angle));
}

float crossShape(float2 uv, float size, float thickness)
{
	uv -= float2(0.5);
	uv = getRotationMat(PI * 0.25) * uv;
	uv = abs(uv);
	
	float mask = step(uv, size) * step(uv.y, 0.2 * thickness);
	mask += step(uv.x, 0.2 * thickness) * step(uv.y, size);
	return saturate(mask);
}

//  Function from Iñigo Quiles
//  https://www.shadertoy.com/view/MsS3Wc
float3 hsb2rgb(float3 c ){
    float3 rgb = clamp(
    		abs(((c.x*6.0+float3(0.0,4.0,2.0)) % 6.0) - 3.0) - 1.0,
    	0.0, 1.0 );
    rgb = rgb*rgb*(3.0-2.0*rgb);
    return c.z * lerp( float3(1.0), rgb, c.y);
}

// Return the ID of the cell in a grid with equal sides. IDs start with 0 and grow to the right and up.
int getGridCellId(float2 uv, int gridSize)
{
	uv = floor(uv*gridSize);
	return uv.x + uv.y * gridSize; 
}

float3 getColoredGrid(float2 uv, int gridSize, float dotSize)
{
	const float2 originalUV = uv;
	float3 color = 0;
	float multiplier = sin(uTime/2000)*3;
	//multiplier = 1;
	float offset = uTime*2;
	//offset = 0;
	
	int id = getGridCellId(uv, gridSize);
	
	uv = originalUV;
	uv = frac(uv*gridSize);
	color = circleShape(uv, dotSize);
	
	//color *= float(id)/(gridSize*gridSize);
	color *= float3(sin(id*2*multiplier+offset)*cos(id*5*multiplier+offset), sin(id*multiplier+offset)*cos(id*3*multiplier+offset), sin(id*3*multiplier+offset)*cos(id*multiplier+offset));
	//color *= hsb2rgb(float3(sin(id*multiplier+offset)*cos(id*3*multiplier+offset)*cos(id*9*multiplier+offset), 1, 0.8));
	
	return color;
}

float getTicTacToe(float2 uv)
{
	const float2 originalUV = uv;
	const int gridSize = 3;
	float3 color = 0;
	
	int id = getGridCellId(uv, gridSize);
	
	uv = originalUV;
	uv = frac(uv*gridSize);
	color = sin(pow(id,9)+uTime) > 0 ? ringShape(uv, 0.2, 0.2) : crossShape(uv, 0.2, 0.15);
	
	return color; 
}

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
    float2 uv = fragCoord.xy/uResolution;
    const float2 originalUV = uv;
    
    float3 color = float3(0);
    
    uv = frac(uv*3);
    color = circleShape(uv, 0.2);
    
    uv = originalUV;
    color = getColoredGrid(uv, 5, 0.55);
    color = getTicTacToe(uv) * float3(0.9, 0.1, 0.1);
    
    return float4(color, 1.0f);
}

