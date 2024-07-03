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

float3 getChannelPlots(float3 val, float2 pos, float3 pixCol) {
	pixCol = lerp(pixCol, float3(1, 0, 0), getPlotWeight(val.r, pos).xxx);
    pixCol = lerp(pixCol, float3(0, 1, 0), getPlotWeight(val.g, pos).xxx);
    pixCol = lerp(pixCol, float3(0, 0, 1), getPlotWeight(val.b, pos).xxx);
    return pixCol;
}

float3 func1(float x) {
	float3 val;
    val.r = 1 - abs(x * 5 - 3.4);
    val.g = smoothstep(0, 0.4, x);
    val.b = pow(x, 0.2);
	return val;
}

float3 func2(float x) {
	float3 val;
	x = smoothstep(0.1, 1, x);
	val.x = sin(x * PI * 3) * (1 - pow(abs(x * 2 - 1.1), 1.5));
	val.y = 1 - pow(abs(((x + 0.15) * 2) - 1), 1.4) - 0.5;
	val.z = sin(x * PI - 2 * PI) * pow(x, 0.2) + 0.02;
	return val;
}

float3 func3Rainbow(float x) {
	float3 val;
	float multiplier = 1;
	float offset = 1 - cos(PI / 3);
	val.x = cos(x * PI * 2 - PI * 0) * multiplier + offset;
	val.y = cos(x * PI * 2 - PI * 0.6666) * multiplier + offset;
	val.z = cos(x * PI * 2 - PI * 1.3333) * multiplier + offset;
	return val;
}

float3 func4_flag(float x) {
	float3 val;
	val.x = 1;
	val.y = step(x, 0.5);
	val.z = step(x, 0.5);
	return val;
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

// Based on uv position returns pixel color, creating a spinning HSV circle.
float3 func5(float2 pos) {
	float2 center = float2(0.5, 0.5);
	float2 toCenter = center - pos; 	// Calculate vector to the center of coord stystem.
	float dist = length(toCenter) * 2; 	// Calculate distance from center, will be used as saturation/value.
	float angle = atan2(toCenter.y, toCenter.x) / PI / 2 + 1; // Calucate the angle(?), used as hue. Normalize -PI to PI -> 0 - 1.
	float3 col = hsb2rgb(float3(angle + uTime / 2, dist / 0.8, (sin(uTime) + 1) / 2)); // Convert Hue, Saturation and Value into RGB color.
	col *= smoothstep(0.9, 0.8, dist); // Blur the edges.
	return col;
}

// Use a shaping function to redistribute the hue coordinate.
float3 func6(float2 pos) {
	float2 center = float2(0.5, 0.5);
	float2 toCenter = center - pos;
	float dist = length(toCenter) * 2;
	float angle = atan2(toCenter.y, toCenter.x) / PI / 2 + 1;
	angle = pow(1 - abs(angle * 2 - 1), 2) + uTime;
	float3 col = hsb2rgb(float3(angle, dist / 0.8, 1));
	col *= smoothstep((sin(uTime) + 1) / 2 * 0.1 + 0.8, 0.8, dist);
	//col *= angle % 0.1 > 0.008;
	return col;
}

float4 main1(float4 fragCoord : SV_POSITION) : SV_TARGET
{
    float2 uv = fragCoord.xy/uResolution;
    
    float3 val = func2(uv.x);
    
    float3 col1 = float3(1.0, 0.3, 0.6);
    float3 col2 = float3(0.2, 0.7, 0.8);
    
    float3 pixCol = lerp(col1, col2, val);
    pixCol = getChannelPlots(val, uv, pixCol);
    
    return float4(pixCol, 1.0f);
}

float4 main2_days(float4 fragCoord : SV_POSITION) : SV_TARGET
{
    float2 uv = fragCoord.xy/uResolution;
    
    float3 col1 = float3(0.0, 0.0, 0);
    float3 col2 = float3(1, 1, 1);
    
    //float3 val = func2(uv.x);
    float3 val = func2(frac(uTime / 10));	// switch comment here
    float3 gradCol1 = lerp(col1, col2, val);
    
    val = func2(frac((uTime - 0.8) / 10)); // switch comment here
    float3 gradCol2 = lerp(col1, col2, val);
    
    float3 pixCol = lerp(gradCol2, gradCol1, uv.yyy); // switch comment here
    //float3 pixCol = gradCol1;
    pixCol = getChannelPlots(val, uv, pixCol);
    
    return float4(pixCol, 1.0f);
}

float4 main2_rainbow(float4 fragCoord : SV_POSITION) : SV_TARGET
{
    float2 uv = fragCoord.xy/uResolution;
    
    float3 val = func3Rainbow(uv.x);
    
    float3 col1 = float3(0.0, 0.0, 0.0);
    float3 col2 = float3(1.0, 1.0, 1.0);
    
    float3 pixCol = lerp(col1, col2, val);
    pixCol = getChannelPlots(val, uv, pixCol);
    
    return float4(pixCol, 1.0f);
}

float4 main3_flag(float4 fragCoord : SV_POSITION) : SV_TARGET
{
    float2 uv = fragCoord.xy/uResolution;
    
    float3 val = func4_flag(1 - uv.y);
    
    float3 col1 = float3(0.0, 0.0, 0.0);
    float3 col2 = float3(1.0, 1.0, 1.0);
    
    float3 pixCol = lerp(col1, col2, val);
    pixCol = getChannelPlots(val, uv, pixCol);
    
    return float4(pixCol, 1.0f);
}

float4 main(float4 fragCoord : SV_POSITION) : SV_TARGET
{
    float2 uv = fragCoord.xy/uResolution;
    
    float3 pixCol = func6(uv);
    
    //pixCol = getChannelPlots(val, uv, pixCol);
    
    return float4(pixCol, 1.0f);
}