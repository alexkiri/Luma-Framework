#include "../Includes/Common.hlsl"
#include "../Includes/ColorGradingLUT.hlsl"

Texture2DMS<float4> t0 : register(t0);

cbuffer cb0 : register(b0)
{
  float4 cb0[138];
}

float3 Uncharted2Curve(float3 x, float a, float b, float c, float d, float e, float f)
{
  return ((x * (a * x + c * b) + d * e) / (x * (a * x + b) + d * f)) - e / f;
}

// One channel only, given they are all the same
float Uncharted2Curve_Inverse(float y, float a, float b, float c, float d, float e, float f)
{
  float ef = e / f;
  float yp = y + ef;

  float A = a * (yp - 1.0);
  float B = b * (yp - c);
  float C = d * (f * yp - e);

  float discriminant = B * B - 4.0 * A * C;

  float sqrtD = sqrt(abs(discriminant)) * sign(discriminant);

  float x1 = (-B + sqrtD) / (2.0 * A);
  float x2 = (-B - sqrtD) / (2.0 * A);

  // Choose the root that makes sense in your context (e.g., positive, in [0,1])
  return (x1 >= 0.0) ? x1 : x2;
}

// Basically identical to the full Uncharted 2 tonemapper,
// but with changed parameters and an extra division by the white scale on the input.
// 0 is mapped to 0. ~INF to ~1 or slightly more.
float3 UnityTonemapper(float3 x)
{
#if 1
  float a = 0.2;
  float b = 0.29;
  float c = 0.24;
  float d = 0.272;
  float e = 0.02;
  float f = 0.3;
  float whiteLevel = 5.3;
  float whiteScale = Uncharted2Curve(whiteLevel, a, b, c, d, e, f).x;

  return sign(x) * Uncharted2Curve(abs(x) / whiteScale, a, b, c, d, e, f) / whiteScale; // Luma: add sign*abs to preserve negative values
#else
  float a = 0.2 * 2 * LumaSettings.DevSetting05;
  float b = 0.29 * 2 * LumaSettings.DevSetting06;
  float c = 0.24 * 2 * LumaSettings.DevSetting07;
  float d = 0.272 * 2 * LumaSettings.DevSetting08;
  float e = 0.02 * 2 * LumaSettings.DevSetting09;
  float f = 0.3 * 2 * LumaSettings.DevSetting10;
  float whiteLevel = 5.3 * 2 * LumaSettings.DevSetting03;
  float whiteScale = Uncharted2Curve(whiteLevel, a, b, c, d, e, f).x;

  return sign(x) * Uncharted2Curve(abs(x) / whiteScale, a, b, c, d, e, f) / (whiteScale * 2 * LumaSettings.DevSetting04);
#endif
}

// One channel only, given they are all the same
float UnityTonemapper_Inverse(float x)
{
  float a = 0.2;
  float b = 0.29;
  float c = 0.24;
  float d = 0.272;
  float e = 0.02;
  float f = 0.3;
  float whiteLevel = 5.3;
  float whiteScale = Uncharted2Curve(whiteLevel, a, b, c, d, e, f).x;

  return sign(x) * Uncharted2Curve_Inverse(abs(x) * whiteScale, a, b, c, d, e, f) * whiteScale;
}

// Resolve MSAA and tonemap in the meantime
// In and out in linear space (it was float textures in the vanilla game too)
void main(
  float4 v0 : SV_POSITION0,
  out float3 o0 : SV_Target0)
{
  float3 outColor = 0; // Start from 0 as then we add below
  float3 SDRColor = 0;

  const uint MSCount = asuint(cb0[134].x);
  const float exposure = cb0[137].x;

  for (uint i = 0; i < MSCount; i++)
  {
    float3 sceneColor = t0.Load((int2)v0.xy, i).xyz;
    sceneColor *= exposure;
    float3 tonemappedSDRColor = UnityTonemapper(sceneColor); // Tonemapping before averaging the MS color is slightly better!
    float3 tonemappedColor = tonemappedSDRColor;
#if 1 // Luma: restore untonemapped color from around 0.18
    static const float SDRTMMidGrayOut = MidGray; 
    static const float SDRTMMidGrayIn = UnityTonemapper_Inverse(SDRTMMidGrayOut);
    static const float SDRTMMidGrayRatio = SDRTMMidGrayOut / SDRTMMidGrayIn;
    float3 tonemappedHDRColor = sceneColor * SDRTMMidGrayRatio; // Match mid gray with the original TM output
    tonemappedColor = lerp(tonemappedSDRColor, tonemappedHDRColor, saturate(tonemappedSDRColor / MidGray));
#elif 1 // Bad attept at stretching the SDR tonemapper, it's extremely saturated
    const float peakWhite = LumaSettings.PeakWhiteNits / sRGB_WhiteLevelNits;
    tonemappedColor = UnityTonemapper(sceneColor / peakWhite) * peakWhite;
#endif
    outColor += tonemappedColor;
    SDRColor += tonemappedSDRColor;
  }
  // Normalize
  outColor /= int(MSCount);
  SDRColor /= int(MSCount);

#if 1 // Luma: restore SDR colors
  outColor = RestoreHue(outColor, SDRColor, 0.8);
  outColor = RestoreChrominanceAdvanced(outColor, SDRColor, 0.4);
#endif
  o0.xyz = outColor;
}