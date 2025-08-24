#include "Includes/Common.hlsl"
#include "../Includes/DICE.hlsl"
#include "../Includes/RCAS.hlsl"

Texture2D<float4> t0 : register(t0);

SamplerState s0_s : register(s0);

Texture2D<float2> dummyFloat2Texture : register(t2); // LUMA

// Used when AA is set to low quality, runs after tonemapping
void main(
  float4 v0 : SV_Position0,
  float4 v1 : TEXCOORD0,
  out float4 o0 : SV_Target0)
{
  float4 r0;
  r0.xyz = t0.Sample(s0_s, v1.xy).xyz;
  r0.w = dot(r0.xyz, float3(1,1,1)); // Sum of RGB, probably unused
  o0.xyz = r0.xyz;
  r0.x = (9.99999975e-006 < r0.w);
  o0.w = r0.x ? 1.0 : 0.0;

  // Clouds use this shader too, just as "post processing" for them.
  // This can occasionally be run before tonemapping (in cutscenes), in that case we want to keep the output linear and unprocessed
  bool isWritingOnSwapchain = LumaData.CustomData1 != 0;
  if (isWritingOnSwapchain)
  {
    // Do TM at the very very last

#if ENABLE_SHARPENING
    float sharpenAmount = LumaSettings.GameSettings.Sharpening;
	  o0.rgb = RCAS(v0.xy, 0, 0x7FFFFFFF, sharpenAmount, t0, dummyFloat2Texture, 1.0, true, float4(o0.rgb, 1.0)).rgb;
#endif // !ENABLE_SHARPENING

#if ENABLE_LUMA
    if (LumaSettings.DisplayMode == 1)
    {
      const float paperWhite = LumaSettings.GamePaperWhiteNits / sRGB_WhiteLevelNits;
      const float peakWhite = LumaSettings.PeakWhiteNits / sRGB_WhiteLevelNits;

      DICESettings settings = DefaultDICESettings();
#if !STRETCH_ORIGINAL_TONEMAPPER && !ENABLE_LUT_EXTRAPOLATION
      settings.Type = DICE_TYPE_BY_LUMINANCE_PQ_CORRECT_CHANNELS_BEYOND_PEAK_WHITE; // We already tonemapped by channel and restored hue/chrominance so let's not shift it anymore by tonemapping by channel
#endif // !STRETCH_ORIGINAL_TONEMAPPER
      // TODO: try SDR case (in HDR modes), and also make shoulder start from mid grey? theoretically that's the section that wasn't tonemapped, anything beyond mid grey (roughly) (nah!)
      settings.ShoulderStart = paperWhite / peakWhite; // Only tonemap beyond paper white, so we leave the SDR range untouched (roughly), so we leave the SDR range untouched (roughly), even if we only blend in the SDR tonemapper up to mid grey, if we start earlier HDR would lose range
      o0.rgb = DICETonemap(o0.rgb * paperWhite, peakWhite, settings) / paperWhite;
    }
#endif // ENABLE_LUMA

    o0.xyz = linear_to_sRGB_gamma(o0.xyz, GCT_MIRROR); // Needed because the original view was a R8G8B8A8_UNORM_SRGB, with the input being float/linear, so there was an implicity sRGB encoding. Following passes are UI and work with non sRGB views.
#if UI_DRAW_TYPE == 2 // Scale by the inverse of the relative UI brightness so we can draw the UI at brightness 1x and then multiply it back to its intended range
  	o0.rgb *= pow(LumaSettings.GamePaperWhiteNits / LumaSettings.UIPaperWhiteNits, 1.0 / DefaultGamma);
#endif
  }
}