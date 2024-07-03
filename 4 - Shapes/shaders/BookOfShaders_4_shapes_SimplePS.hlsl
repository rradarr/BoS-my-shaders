cbuffer vars : register(b0)
{
	float2 uResolution;
	float2 uMouse;
	float uTime;
};

#define PI 3.14

// Get 1 within the box of 'leftBottom' origin and spanning 'size'
float box(float2 uv, float2 leftBottom, float2 size)
{
	float2 leftBottomBorder = step(leftBottom, uv);			// 0 when less than box in given dimension
	float2 rightTopBorder = step(uv, leftBottom + size);	// 0 when more than box in given dimension
	return leftBottomBorder.x * leftBottomBorder.y * rightTopBorder.x * rightTopBorder.y;	// box mask
}

// Get smoothed 1s within the box of 'leftBottom' origin and spanning 'size', with edges smoothed over 'smoothWidth'
float boxSmooth(float2 uv, float2 leftBottom, float2 size, float2 smoothWidth)
{
	float2 leftBottomBorder = smoothstep(leftBottom, leftBottom + smoothWidth, uv);			// 0 when less than box in given dimension
	float2 rightTopBorder = smoothstep(leftBottom + size, leftBottom + size - smoothWidth, uv);	// 0 when more than box in given dimension
	return leftBottomBorder.x * leftBottomBorder.y * rightTopBorder.x * rightTopBorder.y;	// smooth box mask
}

// Implementation of box using floor() and linear transformations
float boxFloor(float2 uv, float2 leftBottom, float2 size)
{
	float2 leftBottomBorder = saturate(floor(1 / leftBottom * uv));
	float2 rightTopBorder = saturate(floor(-1 / (1 - (leftBottom + size)) * (uv - 1)));
	return leftBottomBorder.x * leftBottomBorder.y * rightTopBorder.x * rightTopBorder.y;
}

// Get only the edge of a box of thickness edgeWidth (egde goes inside)
float boxEdge(float2 uv, float2 leftBottom, float2 size, float2 edgeWidth)
{
	return box(uv, leftBottom, size) - box(uv, leftBottom + edgeWidth, size - 2*edgeWidth);
}

float3 getAbstractArt(float2 uv)
{
	const float edgeWidth = 0.015;
	float3 baseCol = 0;
	
	// Background
	baseCol = float3(0.9, 0.75, 0.6);
	
	// Solid colors
	baseCol = box(uv, float2(0, 0.77), float2(0.15, 1)) ? float3(1, 0.1, 0.1) : baseCol; // Red
	baseCol = box(uv, float2(0.68, 0.93), float2(0.6, 1)) ? float3(0.3, 0.1, 0.8) : baseCol; // Blue
	baseCol = box(uv, float2(0.68, 0.09), float2(0.6, 0.15)) ? float3(0.1, 0.6, 0.3) : baseCol; // Green
	baseCol = box(uv, float2(0.45, 0.2), float2(0.28, 0.3)) ? float3(0.7) : baseCol; // Middle
	
	// Horizontal lines
	float linesMask = 0;
	linesMask += boxEdge(uv, float2(-1, 0.23), float2(3, 0.54), edgeWidth);
	linesMask += boxEdge(uv, float2(-1, 0.08), float2(2, 0.86), edgeWidth);
	// Vertical lines
	linesMask += boxEdge(uv, float2(0.15, -1), float2(0.54, 3), edgeWidth);
	linesMask += boxEdge(uv, float2(0.82, 0.23), float2(0.54, 3), edgeWidth);
	// Fill lines
	baseCol = linesMask ? float3(0) : baseCol;
	
	return baseCol;
}

float circle(float2 uv, float2 center, float2 radius)
{
	return step(radius.x, distance(center, uv));
}

float circleSmooth(float2 uv, float2 center, float2 radius, float2 smoothFactor)
{
	return 1 - smoothstep(radius - (radius * smoothFactor), radius, distance(center, uv));
}

float circleBeat(float2 uv, float time)
{
	const float2 center = float2(0.5);
	float2 radius = float2(0.3);
	float2 smoothness = float2(0.1);
	
	time *= 3;
	float beatTime = (sin(time) * sin(time * 3) + 1) / 2 + 0.2;
	
	return circleSmooth(uv, center, radius * beatTime, smoothness);
}

float distanceFields(float2 uv)
{
	uv = uv*2 - 1;
	float2 offset = float2(0.4);
	
	// Repeat the 4 quadrants, offset their centers and get distance to center
	return length(abs(uv) - offset);
	
	// Cutoff the coordinates outside
	//return length(min(abs(uv) - offset, float2(0.5)));
	
	// Cutoff the coordinates inside
	//return length(max(abs(uv) - offset, float2(0)));
	
	// Modify the pattern (- for streching out, + for sucking in)
	//return length(abs(uv) - offset) - length(uv)*1.2;
}

float3 visualizingDistanceFields(float2 uv)
{
	float distanceValue = distanceFields(uv);
	
	// Display repeating saw pattern
	//return frac(distanceValue*10);
	
	// Smooth waves, added movement
	//return sin(distanceValue*100 + uTime*15)/2 + 0.5;
	
	// Pure disatnce
	//return distanceValue;
	
	// Cutoff the distance filed with step
	//return step(0.5, distanceValue);
	
	// Two steps to control inner and outer cutoff
	//return step(distanceValue, 0.3) * step(0.2, distanceValue);
	
	// Two smooth steps controling inner and outer size and smoothness
	return smoothstep(0.04, 0.1, distanceValue) * smoothstep(0.6, 0.2, distanceValue);
}

float3 polarShapes(float2 uv, float2 offset)
{
	uv = 2*uv - 1;
	float distanceVal = length(uv - offset);
	float angle = atan(uv.y / uv.x);
	
	//return distanceVal < abs(cos(angle*6 + uTime));
	float flower = distanceVal < abs(cos(angle*6 + uTime));
	return flower * step(0.2, distanceVal);
}

float flower(float2 uv, float2 offset, float size, float petals)
{
	uv = 2*uv - 1;
	uv -= offset;
	float distanceVal = length(uv);
	float angle = atan(uv.y / uv.x);
	
	float flower = distanceVal/size < abs(cos(angle*petals + uTime));
	return flower * step(0.2*size, distanceVal);
}

float3 flowers(float2 uv)
{
	float flowers = flower(uv, float2(0), 0.2, 6);
	flowers += flower(uv, 0.3, 0.2, 6);
	flowers += flower(uv, float2(-0.3, 0.4), 0.3, 6);
	
	flowers = saturate(flowers);
	return flowers * float3(0.84, 0.85, 0.7);
}

float gear(float2 uv, float2 offset, float size, float teeth)
{
	uv = uv*2 -1;
	uv -= offset;
	float distanceVal = length(uv);
	float angle = atan(uv.y / uv.x);
	
	float gear = distanceVal/size < smoothstep(-0.8, 1, cos(angle*teeth + uTime*10)) * 0.25 + 0.6;
	gear -= step(distanceVal/size, 0.3);
	
	return gear;
}

float gearSmoothOutline(float2 uv, float2 offset, float size, float teeth)
{
	uv = uv*2 -1;
	uv -= offset;
	float distanceVal = length(uv);
	float angle = atan(uv.y / uv.x);
	float gear = smoothstep(-0.8, 1, cos(angle*teeth + uTime*10)) * 0.25 + 0.6;
	gear = (1 - smoothstep(gear, gear+0.05, distanceVal/size)) * smoothstep(gear, gear+0.05, distanceVal/size) * 10;
	gear += (1 - smoothstep(0.3, 0.35, distanceVal/size)) * smoothstep(0.3, 0.4, distanceVal/size) * 20;
	
	return saturate(gear);
}

float square(float2 uv)
{
	uv = uv*2 - 1;
	uv = abs(uv); // Make the coordiantes symmetric
	float square = max(uv.x, uv.y); // Get the distance field of a square
	return step(square, 0.5) * step(0.4, square);
}

float regularPolygon(float2 uv, int sides)
{
	uv = uv*2 - 1;
	float angle = atan2(uv.x, uv.y) + PI;
	float radius = PI * 2 / float(sides);
	float f = cos(floor(0.5 + angle / radius) * radius - angle) * length(uv);
	return step(f, 0.3);
}

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
	float aspectRatio = uResolution.x / uResolution.y;
    float2 uv = fragCoord.xy/uResolution;
    uv.x *= aspectRatio;
    
    float2 nMouse = float2(uMouse.x * aspectRatio, uMouse.y);
    
    float2 proportions = float2(1, 0.5);
    float3 val;
    //val = box(uv, float2(0.1), float2(0.8));
    //val = boxSmooth(uv, float2(0.1), (0.5 * sin(uTime) + 0.5) * 0.8 * proportions, float2(0.04));
	//val = boxFloor(uv, float2(0.1), float2(0.8));
	//val = boxEdge(uv, float2(0.1), float2(0.8), float2(0.02));
	//val = getAbstractArt(uv);
	
	//val = circle(uv, nMouse, float2(0.2, 0.04));
	//val = circleSmooth(uv, nMouse, float2(0.1), float2((sin(uTime) / 2) + 0.5));
	//val = circleBeat(uv, uTime) * float3(0.9, 0.1, 0.1);

	//val = distanceFields(uv);
	//val = visualizingDistanceFields(uv);
	
	//val = polarShapes(uv, 0);
	//val = flowers(uv);
	//val = gear(uv, 0, 0.6, 8);
	//val = gearSmoothOutline(uv, 0, 0.6, 8);
	
	//val = square(uv);
	val = regularPolygon(uv, 6);

    return float4(val, 1.0f);
}
