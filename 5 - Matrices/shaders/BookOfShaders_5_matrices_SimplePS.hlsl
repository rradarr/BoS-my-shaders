cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

#define PI 3.14159265359

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
	// I found this on SO, don't ask.
	return sqrt((1+pow(flatness,2))/(1+pow(flatness,2)*pow(cos(uTime), 2)))*cos(uTime);
}

float movingCrossShape(float2 uv, float size)
{
	// There is a '-' instead of a '+' here because we are not moving
	// points in a space, we are moving the entire space. (akin to
	// subtracting from x to 'move' a graph of f(x) to the right)
	uv -= float2(0.5);
	
	float timing = flattenedCos(uTime, 2);
	timing = (timing+1)/2 * 2*PI + 1.5*PI; // Get this in range
	float2 translate = float2(cos(timing), sin(timing));
   	uv += translate * 0.4;
	return crossShape(uv, size); 
}

float2x2 getRotationMat(float angle)
{
	return float2x2(cos(angle),-sin(angle),
                sin(angle),cos(angle));
}

float2x2 getScaleMat(float2 scale)
{
	return float2x2(scale.x, 0.0,
    				0.0, scale.y);
}

float rotatingCrossShape(float2 uv, float size)
{
	// This caused some head scrathching for me: the typical
	// order of center-rotate-reposition when rotating vertices
	// is kind of reversed, again because we are manipulating the
	// space rather than points within it. So:
	uv -= float2(0.5); 						// We move the (0,0) point to the center of the screen;
	uv = getRotationMat(uTime*0.4) * uv;	// We rotate around the (0,0) point, as always;
	//uv -= float2(0.2); 					// Now we could modify the coordiantes further,
											// essentialy offsetting by a rotated vector.

	return crossShape(uv, size);
}

float movingAndRotatingCrossShape(float2 uv)
{
	float retVal = 0;
	
	// Scale and position our composition.
	uv *= 1.3;
	uv -= float2(0.15, 0.25);
	retVal += movingCrossShape(uv, 0.2);
	
	// Position the second cross and use the flattenedCos function to control the rotation.
	uv -= float2(0.5, -0.1);
	float timeControl = -flattenedCos(uTime, 4) * 1.4 * PI;
	uv = getRotationMat(timeControl) * uv;
	retVal += crossShape(uv, 0.2);
	
	return retVal;
}

// ---------------------- Fake HUD section ----------------------

float getFakeWaveformReadout(float2 uv)
{
	const int xBarCount = 150;	// I like how it looks with a lot of bars, but it kindof makes the width setting obsolete...
	const float amplitudeScale = 0.8;
	const float amplitudeOffset = 0.1;	
	const float barWidth = 0.3;
	float time = uTime * 1;
	
	// Generate the values that will be the heights of the bars.
	float xValue = uv.x;
	xValue = floor(uv.x * xBarCount);	// Discretize the x coordinates.
	// Generate some noisy values (just some sin and cos with different frequencies multiplied together).
	float amplitude = sin(sin(3 * xValue + time)*sin(xValue * 8 + time)*cos(xValue * 50 + time) + time) * cos(2 * xValue + time) / 2 + 0.5;
	//return amplitude;		// Uncomment to see the partial result (comment xValue discretization to see the continuous values).
	amplitude = amplitude * amplitudeScale + amplitudeOffset;	// Scale and offset the amplitude values.
	
	// Prepare a binary mask for where we want the bars to show up (simply this will limit their width).
	float xBarMask = frac(uv.x*xBarCount - (1-barWidth)/2);
	//return xBarMask;
	float barMask = step(xBarMask, barWidth);
	//return barMask;
	
	// Create the bars with appropriate height, but max width.
	float wideBar = step(uv.y, amplitude);
	//return wideBar;
	
	// Multiply the wide bars with the mask and modify their brightness to add visual complexity.
	return wideBar * barMask * (1-amplitude) * saturate(sin(uv.x * PI)*2);
}

float getPlotWeight(float val, float2 pos) {
	const float plotWidth = 0.005;
	return smoothstep(val - plotWidth, val, pos.y) - smoothstep(val, val + plotWidth, pos.y);
}

float waveformFunction(float x, float time)
{
	return sin(sin(4 * x + time)*sin(x * 8 + time)*cos(x * 50 + time) + time) * cos(2 * x + time) / 2 + 0.5;
}

float getFakeTopology(float2 uv)
{
	uv = saturate(uv);	// Clamp the UVs in 0-1 range. Prevents the pattern from duplicating when later scaled.
	const float2 originalUV = uv;
	float waveOffset = 0.04;
	int waveCount = 80;
	float time = uTime / 4;
	
	uv = uv * float2(0.2, 2) + float2(0, 0.7);	// Fill the screen with waves.
	float retVal = 0;
	float value = 0;
	for(int i = 0; i < waveCount; i++)
	{
		// Get the down- and up-slanted waves and draw their values with the plot method.
		value = waveformFunction(uv.x, time + waveOffset * i * 3) / 4;
		retVal += getPlotWeight(value, uv - float2(0, waveOffset * i + uv.x * 3)) * value * 3;
		
		value = waveformFunction(uv.x, time + waveOffset * i * 4) / 4;
		retVal += getPlotWeight(value, uv - float2(0, waveOffset * i - uv.x * 3)) * value * 3;
	}
	
	uv = originalUV;
	
	// We could vignette the edges of the effect.
	float vignette = saturate(sin(uv.x * PI) * sin(uv.y * PI) * 3);
	return retVal * vignette;
	// Or give it a hard cutoff (the almost-1 and -0 are because we saturated the uvs at the start).
	//return retVal * step(uv.x, 0.9999) * step(0.0001, uv.x) * step(uv.y, 0.9999) * step(0.0001, uv.y);
}

float getZoomingThing(float2 uv)
{
	uv = abs(uv - float2(0.5));
	
	float dist = length(uv);
	float mask = step(frac(dist*10 + uTime * 2), 0.1);
	mask *= step(0.05, frac(dist*10 + uTime * 2));
	
	return mask * (1-dist*1.9);
}

float3 getFakeHUD(float2 uv)
{
	const float2 originalUV = uv;
	float3 color = float3(0);
	
	uv = getRotationMat(0.5 * PI) * (uv - float2(0.5)) + float2(0.5);
	uv = getScaleMat(float2(1, 4)) * uv;
	color += float3(0.7, 0.65, 0.3) * 1.3 * getFakeWaveformReadout(uv);
	
	// Add lines and crosses
	uv =originalUV;
	float linesThickness = 0.002;
	float linesLength = 0.65;
	color += box(uv - float2(0.75, 0.6), float2(linesThickness, linesLength)) * float3(0.7, 0.65, 0.3);
	color += box(uv - float2(0.05, 0.6), float2(linesThickness, linesLength)) * float3(0.7, 0.65, 0.3);
	color += box(uv - float2(0.4, 0.95), float2(linesLength, linesThickness)) * float3(0.7, 0.65, 0.3);
	color += box(uv - float2(0.4, 0.25), float2(linesLength, linesThickness)) * float3(0.7, 0.65, 0.3);
	color += saturate(crossShape(uv - float2(0.05, 0.25), 0.03)) * float3(0.8);
	color += saturate(crossShape(uv - float2(0.05, 0.95), 0.03)) * float3(0.8);
	color += saturate(crossShape(uv - float2(0.75, 0.25), 0.03)) * float3(0.8);
	color += saturate(crossShape(uv - float2(0.75, 0.95), 0.03)) * float3(0.8);

	uv = originalUV;
	uv -= float2(0.07, 0.27);
	uv = getScaleMat(float2(1.5, 1.5)) * uv;
	color += saturate(getFakeTopology(uv) * 2);// * float3(0.7, 0.65, 0.3);
	
	uv = originalUV;
	uv = uv * float(4.5) - float2(0.2, 0);
	color += saturate(getZoomingThing(uv)) * float3(0.8, 0.1, 0.1) * (sin(uTime*4) / 2 + 0.5);

	return color;
}

// ---------------------- /Fake HUD section ----------------------

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
    float2 uv = fragCoord.xy/uResolution;
    
    float3 val = float3(0);
    //val = float3(frac(uv.x*10));

   	//val += box(uv, float2(0.6));
   	//val = movingCrossShape(uv, 0.2);
   	//val = rotatingCrossShape(uv, 0.2);
   	//val = movingAndRotatingCrossShape(uv);
   	val = getFakeHUD(uv);

    
    return float4(val, 1.0f);
}
