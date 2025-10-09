#include "../Includes/Common.hlsl"
#include "../Includes/ColorGradingLUT.hlsl"

Texture2D<float4> t0 : register(t0);

SamplerState s0_s : register(s0);

cbuffer cb0 : register(b0)
{
  float4 cb0[4];
}

void main(
  float4 v0 : SV_POSITION0,
  float2 v1 : TEXCOORD0,
  out float4 o0 : SV_Target0)
{
  float4 sceneColor = t0.Sample(s0_s, v1.xy).xyzw;

  float3 decodedColor = sceneColor.rgb;
  // Decode the SDR range with sRGB and the HDR range (at least beyond 1) with gamma 2.2
  if (asint(cb0[3].z) != 0) // Unused by Skate Story (because input was linear)
  {
    bool3 useSRGB = sceneColor.rgb < float3(1,1,1);
    decodedColor = useSRGB ? gamma_sRGB_to_linear(sceneColor.rgb, GCT_MIRROR) : gamma_to_linear(sceneColor.rgb);
  }

  float3 encodedColor = 0;
  if (asint(cb0[3].y) == 0) // Unused by Skate Story as this shader is only used if HDR is enabled
  {
    encodedColor = linear_to_sRGB_gamma(decodedColor, GCT_MIRROR);
  }
  else // HDR branches (?)
  {
    float paperWhiteBrightnessNits = cb0[3].x; // Seemengly fixed to 160 nits (double of 80)
    float peakBrightness = cb0[3].w; // This is taken from the DXGI HDR display calibration
		const float PQNormalizationFactor = paperWhiteBrightnessNits / HDR10_MaxWhiteNits;
    bool forceSCRGB = true; // Luma uses scRGB HDR
#if 0
    paperWhiteBrightnessNits = sRGB_WhiteLevelNits; // Luma: force 80 nits as game paper white, so we use our controls instead (needs "UI_DRAW_TYPE == 2")
#elif 0
    paperWhiteBrightnessNits = paperWhiteBrightnessNits * (sRGB_WhiteLevelNits / 300.0);
#endif
    if (asint(cb0[3].y) == 4 && !forceSCRGB) // PQ encode
    {
      encodedColor = Linear_to_PQ(BT709_To_BT2020(decodedColor) * PQNormalizationFactor, GCT_MIRROR);
    }
    // Seemengly unused by Skate Story, this is some weird custom encoding or post process effect thing?
    else if (asint(cb0[3].y) == 6 && !forceSCRGB)
    {
      // BT.2020 to DP3?
      float3 colorConversion;
      colorConversion.r = dot(float2(0.822462022, 0.177537993), decodedColor.rg);
      colorConversion.g = dot(float2(0.0331940018, 0.966805995), decodedColor.rg);
      colorConversion.b = dot(float3(0.0170830004, 0.0723970011, 0.910520017), decodedColor.rgb);
      encodedColor = linear_to_gamma(colorConversion.rgb * PQNormalizationFactor, GCT_MIRROR);
    }
    // scRGB HDR
    else
    {
      encodedColor = decodedColor / sRGB_WhiteLevelNits * paperWhiteBrightnessNits;
    }
  }
  o0.xyzw = float4(encodedColor, sceneColor.a);
  
#if UI_DRAW_TYPE == 2 // Scale by the inverse of the relative UI brightness so we can draw the UI at brightness 1x and then multiply it back to its intended range
	ColorGradingLUTTransferFunctionInOutCorrected(o0.rgb, VANILLA_ENCODING_TYPE, GAMMA_CORRECTION_TYPE, true);
  o0.rgb *= LumaSettings.GamePaperWhiteNits / LumaSettings.UIPaperWhiteNits;
	ColorGradingLUTTransferFunctionInOutCorrected(o0.rgb, GAMMA_CORRECTION_TYPE, VANILLA_ENCODING_TYPE, true);
#endif
}