cbuffer vars : register(b0)
{
	float2 uResolution;
	float uTime;
};

#define PI 3.14

float getPlotWeight(float val, float2 pos) {
	const float plotWidth = 0.005;
	return smoothstep(val - plotWidth, val, pos.y) - smoothstep(val, val + plotWidth, pos.y);
}

float func1(float x) {
	return pow(x, 2);
}

float func2(float x) {
	return x * (1 + sin((x + uTime / 2) * PI * 10)) / 2;
}

float func3(float x) {
	return frac(x * 3) * (1 + sin(x * 2 + uTime / 2)) / 2;
}

float func4(float x) {
	x = x * 2 - 1; // Rescale x so we get -1 to 1 range.
	
	float timeModifier = (sin(uTime) + 1) * 0.2;
	timeModifier = 0; // Comment to see movement.
	
	return 1 - pow(abs(x), 0.3) - timeModifier;
}

float func5(float x) {
	x = (x - 0.5) * PI; // Rescale x so we get 0 to PI range.
	
	float timeModifier = (sin(uTime) + 1) * 2;
	timeModifier = 1; // Comment to see movement.
	
	return pow(cos(x), timeModifier);
}

float func6(float x) {
	x = (x - 0.5) * PI;
	return 1 - pow(abs(sin(x)), 1.5);
}

float func7(float x) {
	x = x * 2 - 1;
	//return pow(1 - abs(x), 3);
	return pow(min(cos(x * PI / 2.0), 1 - abs(x)), 3); // what? xd it's same as line above...
}

float func8(float x) {
	x = x * 2 - 1;
	//return x;
	return pow(1 - max(0, abs(x) * 2 - 1), 4);
}

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
    float2 uv = fragCoord.xy/uResolution;
    
    float functionVal = func2(uv.x);
    float plotWeight = getPlotWeight(functionVal, uv);
    float3 bcgCol = float3(functionVal.xxx);
    float3 plotCol = float3(0.0, 1.0, 0.0);
    
    float3 pixCol = (1 - plotWeight) * bcgCol + plotWeight * plotCol;
    
    return float4(pixCol, 1.0f);
}
